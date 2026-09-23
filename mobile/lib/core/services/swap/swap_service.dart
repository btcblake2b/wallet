import 'package:flutter/foundation.dart';

import '../../config/bitcoin_network_config.dart';
import '../bitcoin_service.dart';
import 'swap_consts.dart';
import 'swap_models.dart';
import 'swap_provider_client.dart';
import 'swap_provider_store.dart';
import 'swap_script.dart';
import 'swap_session_store.dart';

/// Orchestratore dello swap lato APP (P9).
///
/// // FLOW: Pagamento LN via swap (P9) — app
/// // STEP: 1 collegamento provider (URI + chiave client)
/// // STEP: 2 quote → create (sessione persistita nel registro)
/// // STEP: 3 funding: tx on-chain verso l'HTLC firmata dall'app
/// // STEP: 4 follow-up: annuncio funding + polling/notifiche di stato
/// // STEP: 5 (recupero) refund dopo il CLTV, o import di un blob
///
/// // PERCHÉ: la UI parla SOLO con questo servizio — protocollo, persistenza
/// // e firma restano dietro un'unica superficie testabile.
class SwapService {
  SwapService({
    required SwapProviderClient client,
    required SwapProviderStore providerStore,
    required SwapSessionStore sessionStore,
    required BitcoinService bitcoinService,
    Future<int?> Function()? tipHeightProvider,
  })  : _client = client,
        _providerStore = providerStore,
        _sessionStore = sessionStore,
        _bitcoinService = bitcoinService,
        _tipHeightProvider = tipHeightProvider;

  final SwapProviderClient _client;
  final SwapProviderStore _providerStore;
  final SwapSessionStore _sessionStore;
  final BitcoinService _bitcoinService;

  /// Altezza corrente della chain (best-effort) per le guardie legate al CLTV.
  /// Null = check saltato (il nodo resta l'ultima guardia).
  final Future<int?> Function()? _tipHeightProvider;

  SwapProviderClient get client => _client;
  SwapSessionStore get sessions => _sessionStore;

  /// Validazione dell'invoice: soft-check sul prefisso BOLT11 (il decode
  /// autoritativo lo fa il provider con `decode`).
  static bool isLikelyInvoice(String value) {
    final v = value.trim().toLowerCase();
    final normalized = v.startsWith('lightning:') ? v.substring(10) : v;
    return normalized.startsWith('lnbc') ||
        normalized.startsWith('lntb') ||
        normalized.startsWith('lnsb');
  }

  // ── Collegamento provider ──────────────────────────────────────────────────

  /// Collega un provider dalla sua URI (`nostr+swap://…`).
  Future<SwapProvider> connect(String uri) async {
    final provider = SwapProvider.fromUri(uri);
    final secret = await _providerStore.ensureClientSecret();
    await _client.connect(provider, clientSecretHex: secret);
    await _providerStore.save(provider, clientSecretHex: secret);
    // PERCHÉ: la URI recente popola il menu a tendina della schermata swap.
    await _providerStore.rememberUri(provider.toUri());
    return provider;
  }

  /// URI dei provider usati di recente (menu a tendina).
  Future<List<String>> knownProviderUris() => _providerStore.knownUris();

  /// Annulla (dimentica) una sessione NON ancora finanziata.
  ///
  /// // PERCHÉ: se lo swap è stato creato col wallet sbagliato l'utente deve
  /// // poter ripartire: la sessione locale viene rimossa; lato provider resta
  /// // in `awaitingFunding` e scade da sola (nessun fondo in gioco). Per la
  /// // STESSA invoice il provider risponde DUPLICATE_SWAP finché la vecchia
  /// // sessione è viva → per riprovare serve una invoice nuova.
  Future<void> cancelSession(String swapId) => _sessionStore.remove(swapId);

  /// Ripristina il collegamento salvato (no-op se non c'è provider).
  Future<SwapProvider?> restoreConnection() async {
    final provider = await _providerStore.loadProvider();
    if (provider == null) return null;
    final secret = await _providerStore.ensureClientSecret();
    await _client.connect(provider, clientSecretHex: secret);
    return provider;
  }

  Future<void> disconnect() async {
    await _client.disconnect();
    await _providerStore.clear();
  }

  bool get isConnected => _client.isConnected;

  /// Sonda [uri] e dice se il provider è DISPONIBILE (risponde sul relay).
  ///
  /// // PERCHÉ (18/09/2026): il provider predefinito va mostrato solo se
  /// // raggiungibile — un suggerimento morto è peggio di nessun suggerimento.
  /// La sonda NON lascia il collegamento aperto: connette, fa una richiesta di
  /// sola lettura su un id sconosciuto e disconnette (il collegamento vero
  /// resta un'azione dell'utente). Un errore di protocollo (es. SWAP_NOT_FOUND)
  /// significa provider VIVO; solo gli errori transitori di rete = non
  /// disponibile.
  Future<bool> probeProvider(String uri) async {
    final SwapProvider parsed;
    try {
      parsed = SwapProvider.fromUri(uri);
    } on FormatException {
      return false;
    }
    // PERCHÉ: non si sostituisce con una sonda un provider già collegato.
    if (_client.provider != null) return false;
    final secret = await _providerStore.ensureClientSecret();
    try {
      await _client.connect(parsed, clientSecretHex: secret);
      await _client.status(swapId: 'probe');
      debugPrint('[LoopEngineer] SwapService.probeProvider: risposta OK');
      return true;
    } on SwapException catch (e) {
      final available = !e.isTransient;
      debugPrint(
        '[LoopEngineer] SwapService.probeProvider: ${e.code} '
        '(${available ? 'disponibile' : 'non disponibile'})',
      );
      return available;
    } catch (e) {
      debugPrint('[LoopEngineer] SwapService.probeProvider: errore $e');
      return false;
    } finally {
      // PERCHÉ: la sonda non deve mai lasciare il socket aperto.
      await _client.disconnect();
    }
  }

  // ── Flusso pagamento ───────────────────────────────────────────────────────

  /// Path della chiave di refund per [keyIndex]: `m/84'/coin'/2'/0/x`.
  ///
  /// // PERCHÉ: riusa il COIN TYPE del wallet attivo (dalla config di rete) e
  /// // sposta solo l'account su 2' — mai le chiavi dell'account principale.
  static String refundPathFor(int keyIndex) {
    final base = BitcoinNetworkConfig.defaultDerivationPath.split('/');
    if (base.length == 4) {
      base[3] = "${SwapConsts.refundAccount}'";
      return '${base.join('/')}/${SwapConsts.refundChain}/$keyIndex';
    }
    // Fallback prudente se la config cambia forma: deriva comunque l'account 2'.
    return "m/84'/0'/${SwapConsts.refundAccount}'/"
        '${SwapConsts.refundChain}/$keyIndex';
  }

  /// Avvia lo swap: quote → create → sessione persistita.
  ///
  /// [refundPubkeyHex] è la chiave compressa (33B) derivata dall'app a
  /// [refundPathFor]`(refundKeyIndex)` — l'app la calcola PRIMA (serve nella
  /// richiesta di quote) e la riusa per il refund.
  Future<SwapSession> startSwap({
    required String invoice,
    required String refundPubkeyHex,
    required int refundKeyIndex,
    String? walletId,
    String? walletName,
  }) async {
    final provider = _client.provider;
    if (provider == null) {
      throw const SwapException('NOT_CONNECTED', 'provider non collegato.');
    }
    final quote = await _client.quote(
      invoice: invoice,
      refundPubkeyHex: refundPubkeyHex,
    );
    // STEP: 2a — guardia anti-manomissione: lo script della quote deve
    // coincidere byte per byte con i parametri dichiarati.
    final params = SwapScriptParams(
      paymentHashHex: quote.paymentHashHex,
      claimPubkeyHex: quote.claimPubkeyHex,
      refundPubkeyHex: quote.refundPubkeyHex,
      cltvHeight: quote.cltvHeight,
    );
    if (!SwapScripts.matchesWitnessScriptHex(params, quote.witnessScriptHex)) {
      throw const SwapException(
        'QUOTE_MISMATCH',
        'witness script della quote non coerente coi parametri.',
      );
    }
    final status = await _client.create(quoteId: quote.quoteId);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final session = SwapSession(
      swapId: status.swapId,
      invoice: invoice,
      paymentHashHex: quote.paymentHashHex,
      fundingAmountSats: quote.fundingAmountSats,
      cltvHeight: quote.cltvHeight,
      fundingDeadlineHeight: status.fundingDeadlineHeight,
      claimPubkeyHex: quote.claimPubkeyHex,
      refundPubkeyHex: quote.refundPubkeyHex,
      refundKeyIndex: refundKeyIndex,
      htlcAddress: status.htlcAddress,
      witnessScriptHex: quote.witnessScriptHex,
      providerPubkey: provider.providerPubkey,
      relays: provider.relays,
      walletId: walletId,
      walletName: walletName,
      state: status.state,
      createdAt: status.createdAt,
      updatedAt: status.updatedAt == 0 ? now : status.updatedAt,
    );
    await _sessionStore.upsert(session);
    debugPrint(
      '[LoopEngineer] SwapService: sessione ${session.swapId} avviata '
      '(lock ${session.fundingAmountSats} sat, cltv ${session.cltvHeight})',
    );
    return session;
  }

  /// Firma e trasmette il FUNDING on-chain verso l'HTLC, poi lo annuncia.
  ///
  /// ⚠️ Se l'annuncio fallisce (es. FUNDING_TX_UNKNOWN: la chain non vede
  /// ancora la tx), il txid viene comunque salvato: [refresh] riprova
  /// l'annuncio ai cicli successivi.
  Future<SendResult> fund({
    required SwapSession session,
    required String mnemonic,
    required String accountDerivationPath,
    required List<UtxoInfo> utxos,
    required int feeRateSatVb,
  }) async {
    // STEP: 3 — pagamento on-chain verso l'indirizzo P2WSH dell'HTLC.
    final result = await _bitcoinService.buildSignAndSend(
      mnemonic: mnemonic,
      toAddress: session.htlcAddress,
      amountSats: session.fundingAmountSats,
      feeRateSatVb: feeRateSatVb,
      utxos: utxos,
      derivationPath: accountDerivationPath,
    );
    var updated = session.copyWith(fundingTxid: result.txid);
    try {
      final status = await _client.funding(
        swapId: session.swapId,
        fundingTxid: result.txid,
      );
      updated = updated.copyWith(
        state: status.state,
        updatedAt: status.updatedAt,
      );
    } on SwapException catch (e) {
      debugPrint(
        '[LoopEngineer] SwapService: annuncio funding rimandato (${e.code})',
      );
    }
    await _sessionStore.upsert(updated);
    return result;
  }

  /// Aggiorna lo stato dal provider: ri-annuncia il funding se serve, poi
  /// chiede `swap_status` e persiste la sessione aggiornata.
  Future<SwapSession> refresh(SwapSession session) async {
    if (session.state.isTerminal) return session;
    var current = session;
    final fundingTxid = session.fundingTxid;
    if (fundingTxid != null &&
        session.state == SwapClientState.awaitingFunding) {
      try {
        final announced = await _client.funding(
          swapId: session.swapId,
          fundingTxid: fundingTxid,
        );
        current = current.copyWith(
          state: announced.state,
          updatedAt: announced.updatedAt,
        );
      } on SwapException catch (e) {
        debugPrint(
          '[LoopEngineer] SwapService: ri-annuncio funding fallito (${e.code})',
        );
      }
    }
    final status = await _client.status(swapId: session.swapId);
    final updated = current.copyWith(
      state: status.state,
      fundingVout: status.fundingVout,
      claimTxid: status.claimTxid,
      errorCode: status.errorCode,
      errorMessage: status.errorMessage,
      updatedAt: status.updatedAt,
    );
    await _sessionStore.upsert(updated);
    return updated;
  }

  /// Costruisce, firma e trasmette il REFUND (ramo OP_ELSE, dopo il CLTV).
  ///
  /// ⚠️ La tx è valida solo con `tipHeight >= cltvHeight`: se trasmessa prima
  /// il nodo la rifiuta (CLTV) e l'errore arriva al chiamante.
  Future<String> refund({
    required SwapSession session,
    required String mnemonic,
    required String destinationAddress,
    required int feeRateSatVb,
  }) async {
    final fundingTxid = session.fundingTxid;
    final fundingVout = session.fundingVout;
    if (fundingTxid == null || fundingVout == null) {
      throw const SwapException(
        'REFUND_NOT_READY',
        'funding non ancora identificato (manca txid/vout).',
      );
    }
    // PERCHÉ: il ramo OP_ELSE è spendibile solo dal CLTV — trasmettere prima
    // farebbe rifiutare la tx dal nodo con un errore grezzo (incidente
    // 18/09/2026). Il check è best-effort: senza altezza si prova comunque.
    final tip = await _tipHeightProvider?.call();
    if (tip != null && tip < session.cltvHeight) {
      debugPrint(
        '[LoopEngineer] SwapService.refund: troppo presto '
        '(tip=$tip, cltv=${session.cltvHeight})',
      );
      throw SwapException(
        'REFUND_TOO_EARLY',
        'refund disponibile dal blocco ${session.cltvHeight} (altezza $tip).',
      );
    }
    // STEP: 5 — la chiave dedicata deriva dal path dell'indice salvato in
    // sessione: nessuna ambiguità su QUALI fondi si stanno recuperando.
    final raw = await _bitcoinService.buildSignedRefundTx(
      mnemonic: mnemonic,
      refundDerivationPath: refundPathFor(session.refundKeyIndex),
      paymentHashHex: session.paymentHashHex,
      claimPubkeyHex: session.claimPubkeyHex,
      refundPubkeyHex: session.refundPubkeyHex,
      cltvHeight: session.cltvHeight,
      witnessScriptHex: session.witnessScriptHex,
      fundingTxid: fundingTxid,
      fundingVout: fundingVout,
      fundingAmountSats: session.fundingAmountSats,
      destinationAddress: destinationAddress,
      feeRateSatVb: feeRateSatVb,
    );
    final txid = await _bitcoinService.broadcastTransaction(raw);
    await _sessionStore.upsert(
      session.copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000),
    );
    debugPrint(
      '[LoopEngineer] SwapService: refund trasmesso ${txid.substring(0, 12)}…',
    );
    return txid;
  }

  // ── Recupero (blob export/import) ──────────────────────────────────────────

  String exportRecoveryBlob(SwapSession session) =>
      SwapRecoveryBlob.encode(session);

  /// Importa un blob di recupero nel registro locale (idempotente).
  Future<SwapSession> importRecoveryBlob(String blob) async {
    final session = SwapRecoveryBlob.decode(blob);
    await _sessionStore.upsert(session);
    debugPrint(
      '[LoopEngineer] SwapService: sessione ${session.swapId} importata '
      'da blob (${session.state.wireName})',
    );
    return session;
  }
}
