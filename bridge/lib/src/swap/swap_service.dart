import 'dart:math';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

import '../cln/cln_api.dart';
import '../logger.dart';
import '../protocol.dart';
import 'chain_api.dart';
import 'swap_config.dart';
import 'swap_models.dart';
import 'swap_script.dart';
import 'swap_signer.dart';
import 'swap_store.dart';

/// Servizio di swap (lato provider): quote → funding → pagamento LN → claim.
///
/// // FLOW: Pagamento LN via swap (P9) — provider
/// Macchina a stati del Blueprint §2.7; ogni transizione è persistita
/// ([SwapStore]) e riconciliata da [tick] — il servizio sopravvive ai riavvii.
class SwapService {
  SwapService({
    required ClnApi cln,
    required ChainApi chain,
    required SwapStore store,
    required SwapConfig config,
    required SwapSigner signer,
    Logger? logger,
    DateTime Function()? clock,
    Random? random,
  })  : _cln = cln,
        _chain = chain,
        _store = store,
        _config = config,
        _signer = signer,
        _logger = logger ?? Logger(),
        _clock = clock ?? DateTime.now,
        _random = random ?? Random.secure();

  final ClnApi _cln;
  final ChainApi _chain;
  final SwapStore _store;
  final SwapConfig _config;
  final SwapSigner _signer;
  final Logger _logger;
  final DateTime Function() _clock;
  final Random _random;

  /// Quote in volo (in memoria: un riavvio le perde, il client ne rifà una).
  final Map<String, _Quote> _quotes = {};

  static final RegExp _hex64 = RegExp(r'^[0-9a-fA-F]{64}$');
  static final RegExp _nodeIdHex = RegExp(r'^[0-9a-fA-F]{66}$');

  /// Layers per il calcolo della rotta: le stesse del plugin `pay`
  /// (`auto.localchans` = canali locali, anche non pubblici; `auto.sourcefree`
  /// = primo hop senza fee/delay).
  ///
  /// // PERCHÉ stringa e non List: `lightning-cli` serializza i valori così
  /// // come sono — una List Dart diventerebbe `[auto.localchans, …]` (JSON non
  /// // valido). Forma verificata sul fork v26.06.7-blake2b.4 il 18/09/2026.
  static const String _routeLayers =
      '["auto.localchans","auto.sourcefree"]';

  /// CLTV finale usato SOLO dalla guardia di rotta (valore tipico delle
  /// invoice): serve a verificare che una rotta ESISTA, non a pagare.
  static const int _routeFinalCltv = 40;

  // ---------- API di protocollo ----------

  /// Limiti e capacità corrente del provider (metodo `swap_info`).
  ///
  /// // PERCHÉ (27/10/2026): l'app deve dire PRIMA quanto si può inviare — la
  /// // liquidità del nodo cambia di minuto in minuto e i limiti di config non
  /// // la raccontano — e se il DESTINATARIO di una invoice è raggiungibile.
  /// Senza questo metodo l'unica verifica possibile era la quote, che però
  /// impegna una sessione: qui nessun effetto collaterale, nessun fondo mosso.
  ///
  /// Con [bolt11] valorizzata il payload contiene anche `check`
  /// (`valid`/`reachable`/`reason`): è il pre-flight mostrato in UI.
  Future<Map<String, dynamic>> info({String? bolt11}) async {
    final spendableSats = await _spendableSats();
    final ppm = _config.limits.liquidityReservePpm;
    final capSats = spendableSats - (spendableSats * ppm ~/ 1000000);
    final outstandingSats =
        _store.active().fold<int>(0, (sum, s) => sum + s.fundingAmountSats);
    final freeSats = capSats - outstandingSats;
    final availableSats = freeSats < 0 ? 0 : freeSats;
    final feesSats = _config.fees.serviceFeeSats + _config.fees.claimFeeSats;
    // Il lock comprende le fee: il massimo PAGABILE è il tetto meno le fee.
    final maxFundableSats = min(_config.limits.maxSats, availableSats);
    final out = <String, dynamic>{
      'network': 'blake2b',
      'min_sats': _config.limits.minSats,
      'max_sats': _config.limits.maxSats,
      'min_sendable_sats':
          _config.limits.minSats > feesSats ? _config.limits.minSats - feesSats : 0,
      'max_sendable_sats':
          maxFundableSats > feesSats ? maxFundableSats - feesSats : 0,
      'available_sats': availableSats,
      'spendable_sats': spendableSats,
      'outstanding_sats': outstandingSats,
      'service_fee_sats': _config.fees.serviceFeeSats,
      'claim_fee_sats': _config.fees.claimFeeSats,
      'active_sessions': _store.active().length,
    };
    if (bolt11 != null && bolt11.isNotEmpty) {
      out['check'] = await _checkInvoice(bolt11);
    }
    return out;
  }

  Future<Map<String, dynamic>> quote({
    required String bolt11,
    required String clientPubkey,
    required String refundPubkeyHex,
  }) async {
    // STEP: 1 — decode della invoice sul nodo (nessun effetto collaterale:
    // `pay` avviene SOLO dopo il funding confermato).
    final inv = await _decodeInvoice(bolt11);
    final paymentHash = inv.paymentHashHex;
    final amountMsat = inv.amountMsat;
    final payeeId = inv.payeeId;

    // STEP: 2 — guardie: duplicati, limiti, soglia fee.
    final blocking = _store.blockingByPaymentHash(paymentHash);
    if (blocking != null) {
      throw RpcError(
        'DUPLICATE_SWAP',
        'payment_hash già usato dalla sessione ${blocking.id} (${blocking.state.wireName}).',
      );
    }
    if (_store.active().length >= _config.limits.maxConcurrent) {
      throw const RpcError(
        'RATE_LIMITED',
        'troppe sessioni attive sul provider.',
      );
    }
    if (clientPubkey.isNotEmpty) {
      final mine =
          _store.active().where((s) => s.clientPubkey == clientPubkey).length;
      if (mine >= _config.limits.maxPerPubkey) {
        throw const RpcError(
          'RATE_LIMITED',
          'troppe sessioni attive per questo client.',
        );
      }
    }
    // Arrotonda per eccesso: l'HTLC non deve mai valere meno della invoice.
    final invoiceSats = inv.amountSats;
    final fundingSats =
        invoiceSats + _config.fees.serviceFeeSats + _config.fees.claimFeeSats;
    if (fundingSats < _config.limits.minSats) {
      throw RpcError(
        'AMOUNT_TOO_SMALL',
        'importo sotto il minimo (${_config.limits.minSats} sat, totale da lockare incluso).',
      );
    }
    if (fundingSats > _config.limits.maxSats) {
      throw RpcError(
        'AMOUNT_TOO_LARGE',
        'importo oltre il massimo (${_config.limits.maxSats} sat).',
      );
    }
    final routingWorst = _config.fees.maxRoutingFeeBaseSats +
        (invoiceSats * _config.fees.maxRoutingFeePpm ~/ 1000000);
    final costSats = _config.fees.claimFeeSats + routingWorst;
    if (costSats > fundingSats * _config.limits.maxFeeRatio) {
      throw RpcError(
        'AMOUNT_TOO_SMALL',
        'costo tecnico stimato ($costSats sat) oltre il '
            '${(_config.limits.maxFeeRatio * 100).round()}% dell\'importo.',
      );
    }

    // STEP: 3 — guardia di liquidità aggregata (B2, 05/10/2026): il tetto di
    // config (`maxSats` × `maxConcurrent`) prometteva più della capacità reale
    // del nodo; qui il limite è ancorato alla liquidità MISURATA.
    await _ensureLiquidity(fundingSats);

    // STEP: 4 — guardia di pagabilità (pre-flight): mai far lockare fondi se il
    // provider non può pagare. // PERCHÉ (incidente 18/09/2026): il nodo era
    // senza canali, la quote fu accettata, l'utente finanziò l'HTLC e il `pay`
    // fallì subito dopo ("Unknown source node") → fondi recuperabili solo dopo
    // il CLTV. Il rifiuto ora arriva PRIMA del finanziamento.
    await _ensurePayable(payeeId: payeeId, amountMsat: amountMsat);

    // STEP: 5 — parametri HTLC + quote (TTL in memoria).
    if (BytesUtils.fromHexString(refundPubkeyHex).length != 33) {
      throw const RpcError(
        'BAD_REQUEST',
        'refund_pubkey non valida (attesi 33 byte compressi).',
      );
    }
    final tip = await _chain.tipHeight();
    final cltvHeight = tip + _config.htlc.cltvDelta;
    final params = SwapScriptParams(
      paymentHashHex: paymentHash,
      claimPubkeyHex: _signer.pubkeyHex,
      refundPubkeyHex: refundPubkeyHex,
      cltvHeight: cltvHeight,
    );
    final htlcAddress = SwapScripts.address(params, BitcoinNetwork.mainnet);
    final witnessScriptHex = SwapScripts.witnessScript(params).toHex();
    final quoteId = _randomHex(16);
    final expiresAt = _nowSec() + _config.timeouts.quoteTtlSec;
    _pruneQuotes();
    _quotes[quoteId] = _Quote(
      clientPubkey: clientPubkey,
      invoice: bolt11,
      payeeId: payeeId,
      paymentHashHex: paymentHash,
      amountMsat: amountMsat,
      fundingAmountSats: fundingSats,
      cltvHeight: cltvHeight,
      refundPubkeyHex: refundPubkeyHex,
      htlcAddress: htlcAddress,
      witnessScriptHex: witnessScriptHex,
      expiresAt: expiresAt,
    );
    _logger.info(
      'quote ${quoteId.substring(0, 8)}…: invoice $invoiceSats sat, '
      'lock $fundingSats sat, cltv $cltvHeight',
    );
    return {
      'quote_id': quoteId,
      'expires_at': expiresAt,
      'payment_hash': paymentHash,
      'amount_msat': amountMsat,
      'amount_sats': invoiceSats,
      'service_fee_sats': _config.fees.serviceFeeSats,
      'claim_fee_sats': _config.fees.claimFeeSats,
      'funding_amount_sats': fundingSats,
      'cltv_height': cltvHeight,
      'claim_pubkey': _signer.pubkeyHex,
      'refund_pubkey': refundPubkeyHex,
      'htlc_address': htlcAddress,
      'witness_script_hex': witnessScriptHex,
      'network': 'blake2b',
    };
  }

  Future<Map<String, dynamic>> create({
    required String quoteId,
    required String clientPubkey,
  }) async {
    final q = _quotes[quoteId];
    if (q == null ||
        q.expiresAt < _nowSec() ||
        q.clientPubkey != clientPubkey) {
      throw const RpcError(
        'QUOTE_EXPIRED',
        'quote scaduta o sconosciuta: richiederne una nuova.',
      );
    }
    final blocking = _store.blockingByPaymentHash(q.paymentHashHex);
    if (blocking != null) {
      throw RpcError(
        'DUPLICATE_SWAP',
        'payment_hash già in uso (${blocking.state.wireName}).',
      );
    }
    // PERCHÉ (ri-check pre-lock): tra quote e funding il nodo può perdere
    // canali/liquidità — la sessione NON deve nascere se non si può pagare.
    // PERCHÉ (B2): anche l'esposizione si ri-verifica qui — tra quote e create
    // altre sessioni possono aver consumato la capacità del provider.
    await _ensureLiquidity(q.fundingAmountSats);
    await _ensurePayable(payeeId: q.payeeId, amountMsat: q.amountMsat);
    final now = _nowSec();
    final session = SwapSession(
      id: _randomHex(16),
      clientPubkey: clientPubkey,
      invoice: q.invoice,
      paymentHashHex: q.paymentHashHex,
      amountMsat: q.amountMsat,
      fundingAmountSats: q.fundingAmountSats,
      serviceFeeSats: _config.fees.serviceFeeSats,
      claimFeeSats: _config.fees.claimFeeSats,
      cltvHeight: q.cltvHeight,
      claimPubkeyHex: _signer.pubkeyHex,
      refundPubkeyHex: q.refundPubkeyHex,
      htlcAddress: q.htlcAddress,
      witnessScriptHex: q.witnessScriptHex,
      fundingDeadlineHeight:
          q.cltvHeight - _config.htlc.claimMargin - _config.htlc.fundingBuffer,
      state: SwapState.awaitingFunding,
      createdAt: now,
      updatedAt: now,
    );
    await _store.upsert(session);
    _quotes.remove(quoteId);
    _logger.info(
      'sessione ${session.id.substring(0, 8)}… creata (awaitingFunding)',
    );
    return _statusOf(session);
  }

  Future<Map<String, dynamic>> registerFunding({
    required String swapId,
    required String clientPubkey,
    required String fundingTxid,
  }) async {
    final s = _requireSession(swapId, clientPubkey);
    if (s.state != SwapState.awaitingFunding &&
        s.state != SwapState.confirming) {
      throw RpcError('WRONG_STATE', 'sessione in stato ${s.state.wireName}.');
    }
    final txid = fundingTxid.toLowerCase();
    if (!_hex64.hasMatch(txid)) {
      throw const RpcError('BAD_REQUEST', 'funding_txid non valido.');
    }
    final status = await _chain.txStatus(txid);
    if (status == null) {
      throw const RpcError(
        'FUNDING_TX_UNKNOWN',
        'tx di funding sconosciuta alla chain.',
      );
    }
    final updated = s.copyWith(
      state: SwapState.confirming,
      fundingTxid: txid,
      updatedAt: _nowSec(),
    );
    await _store.upsert(updated);
    _logger.info(
      'sessione ${updated.id.substring(0, 8)}…: funding ${txid.substring(0, 12)}… annunciata',
    );
    return _statusOf(updated);
  }

  Future<Map<String, dynamic>> status({
    required String swapId,
    required String clientPubkey,
  }) async {
    final s = _requireSession(swapId, clientPubkey);
    final out = _statusOf(s);
    final height = s.fundingHeight;
    if (height != null) {
      try {
        final tip = await _chain.tipHeight();
        out['funding_confirmations'] = tip - height + 1;
      } on Exception {
        // best-effort: lo stato resta valido anche senza il conteggio.
      }
    }
    return out;
  }

  /// Payload di stato (formato wire) per [session].
  ///
  /// // PERCHÉ: usato dal daemon per le notifiche push (kind 23292) — un
  /// // unico punto definisce la forma dello stato, identica a `swap_status`.
  Map<String, dynamic> statusPayload(SwapSession session) =>
      _statusOf(session);

  // ---------- Riconciliazione ----------

  /// Un passo della macchina a stati per tutte le sessioni rilevanti.
  /// Resiliente: un errore su una sessione non blocca le altre.
  Future<void> tick() async {
    final sessions = _store
        .all()
        .where((s) => s.state.isActive || s.state.isRefundable)
        .toList();
    if (sessions.isEmpty) return;
    int tip;
    try {
      tip = await _chain.tipHeight();
    } on Exception catch (e) {
      _logger.warn('tick: tip non disponibile ($e) — ciclo saltato');
      return;
    }
    for (final s in sessions) {
      try {
        await _tickSession(s, tip);
      } on Exception catch (e, st) {
        _logger.warn('tick sessione ${s.id.substring(0, 8)}… fallito: $e');
        _logger.debug('tick stack: $st');
      }
    }
  }

  Future<void> _tickSession(SwapSession s, int tip) async {
    switch (s.state) {
      case SwapState.awaitingFunding:
        if (tip > s.fundingDeadlineHeight) {
          await _transition(
            s.copyWith(
              state: SwapState.expired,
              errorCode: 'FUNDING_TIMEOUT',
              errorMessage:
                  'fondi non visti entro l\'altezza ${s.fundingDeadlineHeight}.',
            ),
          );
        }
      case SwapState.confirming:
        await _reconcileFunding(s, tip);
      case SwapState.paying || SwapState.paid:
        await _payAndClaim(s, tip);
      case SwapState.claiming:
        await _reconcileClaim(s, tip);
      case SwapState.paymentFailed || SwapState.expired:
        await _watchRefund(s);
      case SwapState.completed || SwapState.refunded:
        break;
    }
  }

  Future<void> _reconcileFunding(SwapSession s, int tip) async {
    final txid = s.fundingTxid;
    if (txid == null) {
      // Annuncio senza txid (non dovrebbe accadere): torna in attesa.
      await _transition(s.copyWith(state: SwapState.awaitingFunding));
      return;
    }
    if (tip > s.fundingDeadlineHeight) {
      await _transition(
        s.copyWith(
          state: SwapState.expired,
          errorCode: 'FUNDING_TIMEOUT',
          errorMessage: 'funding non confermato entro la deadline.',
        ),
      );
      return;
    }
    final status = await _chain.txStatus(txid);
    if (status == null || !status.confirmed || status.blockHeight == null) {
      return; // ancora in mempool/da confermare
    }
    final height = status.blockHeight!;
    final confs = tip - height + 1;
    if (confs < _config.htlc.confirmations) return;

    // STEP: verifica dell'output che paga l'HTLC (script + importo).
    final rawHex = await _chain.txHex(txid);
    if (rawHex == null) return;
    final tx = BtcTransaction.deserialize(BytesUtils.fromHexString(rawHex));
    final expectedSpk = SwapScripts.scriptPubKeyHex(s.scriptParams);
    int? vout;
    for (var i = 0; i < tx.outputs.length; i++) {
      final out = tx.outputs[i];
      final spk = out.scriptPubKey.toHex().toLowerCase();
      if (spk == expectedSpk.toLowerCase() &&
          out.amount >= BigInt.from(s.fundingAmountSats)) {
        vout = i;
        break;
      }
    }
    if (vout == null) {
      await _transition(
        s.copyWith(
          state: SwapState.paymentFailed,
          errorCode: 'FUNDING_MISMATCH',
          errorMessage: 'la tx non paga l\'HTLC con l\'importo atteso.',
        ),
      );
      return;
    }

    // Troppo vicino al CLTV per pagare in sicurezza → si lascia scadere.
    if (tip > s.cltvHeight - _config.htlc.claimMargin - 2) {
      await _transition(
        s.copyWith(
          state: SwapState.expired,
          fundingVout: vout,
          fundingHeight: height,
          errorCode: 'TOO_LATE',
          errorMessage: 'funding troppo vicino al CLTV: pagamento annullato.',
        ),
      );
      return;
    }

    final cur = s.copyWith(
      state: SwapState.paying,
      fundingVout: vout,
      fundingHeight: height,
      updatedAt: _nowSec(),
    );
    await _store.upsert(cur);
    _logger.info(
      'sessione ${cur.id.substring(0, 8)}…: funding confermato '
      '(vout $vout, h $height) → pagamento invoice',
    );
    await _payAndClaim(cur, tip);
  }

  Future<void> _payAndClaim(SwapSession s, int tip) async {
    var cur = s;
    var preimage = cur.preimageHex;

    // STEP: 1 — recovery: pagamento già riuscito ma crash prima di persistere.
    if (preimage == null) {
      preimage = await _recoverPreimage(cur);
      if (preimage != null) {
        await _transition(cur.copyWith(preimageHex: preimage));
        cur = _store.byId(cur.id)!;
      }
    }

    // STEP: 2 — pagamento della invoice (con cap sulla routing fee).
    if (preimage == null) {
      final maxFeeMsat = (_config.fees.maxRoutingFeeBaseSats * 1000) +
          (cur.amountMsat * _config.fees.maxRoutingFeePpm ~/ 1000000);
      try {
        final res = await _cln.call('pay', {
          'bolt11': cur.invoice,
          'maxfee': maxFeeMsat,
        });
        preimage = res['payment_preimage']?.toString().toLowerCase();
      } on RpcError catch (e) {
        // Es. "already paid": prima di contare il tentativo, prova listpays.
        preimage = await _recoverPreimage(cur);
        if (preimage == null) {
          final attempts = cur.payAttempts + 1;
          final failed = attempts >= _config.timeouts.payRetryMax;
          await _transition(
            cur.copyWith(
              state: failed ? SwapState.paymentFailed : SwapState.paying,
              payAttempts: attempts,
              errorCode: failed ? 'PAYMENT_FAILED' : null,
              errorMessage: failed ? e.message : null,
            ),
          );
          if (failed) {
            _logger.warn(
              'sessione ${cur.id.substring(0, 8)}…: pagamento fallito '
              '(tentativi $attempts) — l\'utente potrà refundare dopo il CLTV',
            );
          }
          return;
        }
      }
    }
    if (preimage == null || preimage.length != 64) {
      await _transition(
        cur.copyWith(
          state: SwapState.paymentFailed,
          errorCode: 'PAYMENT_FAILED',
          errorMessage: 'preimage non disponibile.',
        ),
      );
      return;
    }

    // STEP: 3 — invariante di sicurezza: SHA256(preimage) == payment_hash.
    final expected = BytesUtils.toHexString(
      QuickCrypto.sha256Hash(BytesUtils.fromHexString(preimage)),
    ).toLowerCase();
    if (expected != cur.paymentHashHex.toLowerCase()) {
      // PERCHÉ: con una preimage incoerente il claim sarebbe invalido — non si
      // tocca la chain e si chiude la sessione come fallita.
      await _transition(
        cur.copyWith(
          state: SwapState.paymentFailed,
          errorCode: 'PREIMAGE_MISMATCH',
          errorMessage: 'preimage incoerente col payment_hash.',
        ),
      );
      return;
    }

    if (cur.preimageHex != preimage || cur.state != SwapState.paid) {
      await _transition(
        cur.copyWith(state: SwapState.paid, preimageHex: preimage),
      );
      cur = _store.byId(cur.id)!;
    }
    await _claim(cur, tip);
  }

  Future<void> _claim(SwapSession s, int tip) async {
    if (s.fundingTxid == null ||
        s.fundingVout == null ||
        s.preimageHex == null) {
      return;
    }
    // Destinazione: SEMPRE un indirizzo nuovo del wallet del nodo.
    Map<String, dynamic> addr;
    try {
      addr = await _cln.call('newaddr', {'addresstype': 'bech32'});
    } on RpcError catch (e) {
      _logger.warn(
        'sessione ${s.id.substring(0, 8)}…: newaddr fallita (${e.message}) — ritento al prossimo tick',
      );
      return;
    }
    final destination = '${addr['bech32'] ?? addr['address'] ?? ''}';
    if (destination.isEmpty) {
      _logger.warn(
        'sessione ${s.id.substring(0, 8)}…: newaddr senza indirizzo — ritento',
      );
      return;
    }
    // Fee crescente a ogni ritentativo (RBF) — vedi _reconcileClaim.
    final feeRate = _config.fees.claimFeeRateSatVb + s.claimAttempts;
    final feeSats = SwapSigner.claimTxVbytes * feeRate;
    if (feeSats >= s.fundingAmountSats - 546) {
      await _transition(
        s.copyWith(
          state: SwapState.paymentFailed,
          errorCode: 'CLAIM_FEE_TOO_HIGH',
          errorMessage: 'fee di claim troppo alta per l\'importo.',
        ),
      );
      return;
    }
    String raw;
    try {
      raw = _signer.buildClaimTx(
        fundingTxid: s.fundingTxid!,
        fundingVout: s.fundingVout!,
        fundingAmountSats: s.fundingAmountSats,
        scriptParams: s.scriptParams,
        preimageHex: s.preimageHex!,
        destinationAddress: destination,
        feeSats: feeSats,
      );
    } on Exception catch (e) {
      _logger.error(
        'sessione ${s.id.substring(0, 8)}…: costruzione claim fallita: $e',
      );
      return;
    }
    final claimTxid = await _chain.broadcast(raw);
    final cur = s.copyWith(
      state: SwapState.claiming,
      claimTxid: claimTxid,
      claimAttempts: s.claimAttempts + 1,
      updatedAt: _nowSec(),
    );
    await _store.upsert(cur);
    _logger.info(
      'sessione ${cur.id.substring(0, 8)}…: claim trasmesso $claimTxid (fee $feeSats sat)',
    );
  }

  Future<void> _reconcileClaim(SwapSession s, int tip) async {
    final txid = s.claimTxid;
    if (txid == null) return;
    final status = await _chain.txStatus(txid);
    if (status == null) {
      // La tx non è (più) nota alla chain: possibile drop → si ritenta il claim.
      await _transition(s.copyWith(state: SwapState.paid));
      return;
    }
    if (status.confirmed) {
      await _transition(s.copyWith(state: SwapState.completed));
      _logger.info(
        'sessione ${s.id.substring(0, 8)}…: COMPLETATA (claim confermato)',
      );
      return;
    }
    // Non confermato: se il margine si sta esaurendo, ritenta con fee più alta.
    final remaining = s.cltvHeight - tip;
    if (remaining <= 6 && s.claimAttempts < 10) {
      _logger.warn(
        'sessione ${s.id.substring(0, 8)}…: claim non confermato, ritento (margine $remaining blocchi)',
      );
      await _transition(s.copyWith(state: SwapState.paid));
    }
  }

  Future<void> _watchRefund(SwapSession s) async {
    final txid = s.fundingTxid;
    final vout = s.fundingVout;
    if (txid == null || vout == null) return;
    final spends = await _chain.outspends(txid);
    if (vout >= spends.length) return;
    final spend = spends[vout];
    if (!spend.spent) return;
    if (s.claimTxid != null && spend.spendingTxid == s.claimTxid) return;
    // Speso da una tx diversa dal claim → refund dell'utente (o anomalia).
    await _transition(s.copyWith(state: SwapState.refunded));
    _logger.info(
      'sessione ${s.id.substring(0, 8)}…: REFUND osservato on-chain',
    );
  }

  // ---------- Helper ----------

  SwapSession _requireSession(String swapId, String clientPubkey) {
    final s = _store.byId(swapId);
    if (s == null) {
      throw const RpcError('SWAP_NOT_FOUND', 'sessione sconosciuta.');
    }
    if (s.clientPubkey != clientPubkey) {
      throw const RpcError(
        'UNAUTHORIZED',
        'la sessione appartiene a un altro client.',
      );
    }
    return s;
  }

  Future<void> _transition(SwapSession updated) async {
    await _store.upsert(updated.copyWith(updatedAt: _nowSec()));
  }

  /// Preimage di un pagamento già riuscito, letta da `listpays`.
  ///
  /// PERCHÉ: se il processo muore tra `pay` e la persistenza, la preimage è
  /// recuperabile dal nodo — senza, si perderebbe il pagamento fatto.
  Future<String?> _recoverPreimage(SwapSession s) async {
    try {
      final res = await _cln.call('listpays', {
        'payment_hash': s.paymentHashHex,
      });
      final pays = res['pays'];
      if (pays is List) {
        for (final p in pays) {
          if (p is! Map) continue;
          final preimage = p['preimage'] ?? p['payment_preimage'];
          final status = '${p['status'] ?? ''}';
          if (preimage is String &&
              preimage.isNotEmpty &&
              (status == 'complete' || status.isEmpty)) {
            return preimage.toLowerCase();
          }
        }
      }
    } on RpcError {
      return null;
    }
    return null;
  }

  Map<String, dynamic> _statusOf(SwapSession s) => {
        'swap_id': s.id,
        'state': s.state.wireName,
        'htlc_address': s.htlcAddress,
        'witness_script_hex': s.witnessScriptHex,
        'funding_amount_sats': s.fundingAmountSats,
        'cltv_height': s.cltvHeight,
        'funding_deadline_height': s.fundingDeadlineHeight,
        if (s.fundingTxid != null) 'funding_txid': s.fundingTxid,
        if (s.fundingVout != null) 'funding_vout': s.fundingVout,
        if (s.fundingHeight != null) 'funding_height': s.fundingHeight,
        if (s.claimTxid != null) 'claim_txid': s.claimTxid,
        if (s.errorCode != null)
          'error': {'code': s.errorCode, 'message': s.errorMessage ?? ''},
        'created_at': s.createdAt,
        'updated_at': s.updatedAt,
      };

  /// Guardia di liquidità aggregata (B2, 05/10/2026).
  ///
  /// // PERCHÉ: `maxSats` × `maxConcurrent` è un tetto "di config", non di
  /// // nodo — con 850 k sat di capacità reale si potevano accettare sessioni
  /// // per 5 M sat, che il provider NON avrebbe poi potuto pagare (fondi
  /// // dell'utente lockati in HTLC fino al refund). Qui il tetto è ancorato
  /// // alla liquidità MISURATA (`spendable_msat`), meno una riserva prudenziale.
  ///
  /// L'esposizione conta le sessioni vive ([SwapStore.active]): ogni sessione
  /// nata riserva capacità finché non si chiude.
  Future<void> _ensureLiquidity(int fundingSats) async {
    final spendableSats = await _spendableSats();
    final ppm = _config.limits.liquidityReservePpm;
    final capSats = spendableSats - (spendableSats * ppm ~/ 1000000);
    final outstandingSats =
        _store.active().fold<int>(0, (sum, s) => sum + s.fundingAmountSats);
    // // PERCHÉ (semantica): liquidità ZERO non è "troppa richiesta", è un
    // // provider che NON può pagare affatto — il client deve distinguere i due
    // // casi (riprovare più tardi vs aspettare che il nodo abbia canali).
    if (spendableSats <= 0) {
      throw const RpcError(
        'PROVIDER_UNAVAILABLE',
        'nessun canale con liquidità in uscita: il provider non può pagare.',
      );
    }
    if (outstandingSats + fundingSats > capSats) {
      _logger.warn(
        'liquidità insufficiente: ${fundingSats}sat richiesti + '
        '${outstandingSats}sat in corso su ${capSats}sat disponibili '
        '(${spendableSats}sat spendibili)',
      );
      throw const RpcError(
        'RATE_LIMITED',
        'liquidità del provider temporaneamente insufficiente: riprova più tardi.',
      );
    }
    _logger.debug(
      'liquidità: ${outstandingSats + fundingSats}sat impegnati su '
      '${capSats}sat disponibili',
    );
  }

  /// Guardia di pagabilità (pre-flight, PRIMA di far lockare fondi).
  ///
  /// // PERCHÉ (incidente 18/09/2026): il provider accettava le quote anche con
  /// // il nodo privo di canali → l'utente finanziava l'HTLC e il pagamento
  /// // falliva subito dopo ("Unknown source node"), con i fondi recuperabili
  /// // solo dopo il CLTV. Fail-closed: qualsiasi errore del nodo → rifiuto.
  Future<void> _ensurePayable({
    required String payeeId,
    required int amountMsat,
  }) async {
    final issue = await _payabilityIssue(payeeId: payeeId, amountMsat: amountMsat);
    if (issue == null) return;
    // PERCHÉ codice unico per il pagamento: `PROVIDER_UNAVAILABLE` è già
    // mappato in UI dai client esistenti — il dettaglio (destinatario vs nodo)
    // resta nel messaggio e in `swap_info`, dove serve a distinguere i casi.
    throw RpcError('PROVIDER_UNAVAILABLE', issue.message);
  }

  /// Esito della guardia di pagabilità SENZA eccezioni (serve a `swap_info`).
  ///
  /// Ritorna `null` se il provider può pagare, altrimenti il codice del
  /// problema (`PEER_UNREACHABLE` = nessuna rotta verso il destinatario,
  /// `PROVIDER_UNAVAILABLE` = nodo/canali non utilizzabili).
  Future<_PayabilityIssue?> _payabilityIssue({
    required String payeeId,
    required int amountMsat,
  }) async {
    // (a) il nodo deve avere almeno un canale normale con liquidità in uscita.
    final Map<String, dynamic> nodeInfo;
    final Map<String, dynamic> channels;
    try {
      nodeInfo = await _cln.call('getinfo');
      channels = await _cln.call('listpeerchannels');
    } on RpcError catch (e) {
      throw RpcError(
        'PROVIDER_UNAVAILABLE',
        'nodo del provider non interrogabile: ${e.message}',
      );
    }
    final selfId = '${nodeInfo['id'] ?? ''}'.toLowerCase();
    if (!_nodeIdHex.hasMatch(selfId)) {
      return const _PayabilityIssue(
        'PROVIDER_UNAVAILABLE',
        'getinfo del nodo senza node id valido.',
      );
    }
    final spendableMsat = _spendableMsatOf(channels);
    if (spendableMsat <= 0) {
      return const _PayabilityIssue(
        'PROVIDER_UNAVAILABLE',
        'nessun canale con liquidità in uscita: il provider non può pagare.',
      );
    }
    _logger.debug('pre-flight: ${spendableMsat ~/ 1000} sat spendibili');

    // (b) deve esistere una rotta verso il destinatario (stesse layers di pay).
    final maxFeeMsat = (_config.fees.maxRoutingFeeBaseSats * 1000) +
        (amountMsat * _config.fees.maxRoutingFeePpm ~/ 1000000);
    final Map<String, dynamic> res;
    try {
      res = await _cln.call('getroutes', {
        'source': selfId,
        'destination': payeeId,
        'amount_msat': amountMsat,
        'layers': _routeLayers,
        'maxfee_msat': maxFeeMsat,
        'final_cltv': _routeFinalCltv,
      });
    } on RpcError catch (e) {
      return _PayabilityIssue(
        'PEER_UNREACHABLE',
        'nessuna rotta verso il destinatario: ${e.message}',
      );
    }
    final routes = res['routes'];
    if (routes is! List || routes.isEmpty) {
      return const _PayabilityIssue(
        'PEER_UNREACHABLE',
        'nessuna rotta trovata verso il destinatario.',
      );
    }
    _logger.debug(
      'pre-flight: rotta OK verso ${payeeId.substring(0, 12)}…',
    );
    return null;
  }

  /// Somma di `spendable_msat` sui soli canali `CHANNELD_NORMAL`.
  int _spendableMsatOf(Map<String, dynamic> channels) {
    var spendableMsat = 0;
    final list = channels['channels'];
    if (list is List) {
      for (final raw in list) {
        if (raw is! Map) continue;
        final c = raw.cast<String, dynamic>();
        if ('${c['state'] ?? ''}' != 'CHANNELD_NORMAL') continue;
        spendableMsat += _parseMsat(c['spendable_msat']) ?? 0;
      }
    }
    return spendableMsat;
  }

  /// Liquidità in uscita spendibile ORA (sat). Fail-closed se il nodo muto.
  Future<int> _spendableSats() async {
    final Map<String, dynamic> channels;
    try {
      channels = await _cln.call('listpeerchannels');
    } on RpcError catch (e) {
      throw RpcError(
        'PROVIDER_UNAVAILABLE',
        'nodo del provider non interrogabile: ${e.message}',
      );
    }
    return _spendableMsatOf(channels) ~/ 1000;
  }

  /// Decodifica e valida la invoice sul nodo (payee, importo, scadenza).
  ///
  /// Lancia [RpcError] con i codici storici (`INVOICE_INVALID`/`INVOICE_EXPIRED`):
  /// la usano sia `swap_quote` sia `swap_info`.
  Future<_DecodedInvoice> _decodeInvoice(String bolt11) async {
    Map<String, dynamic> decoded;
    try {
      decoded = await _cln.call('decode', {'string': bolt11});
    } on RpcError catch (e) {
      throw RpcError('INVOICE_INVALID', 'decode fallito: ${e.message}');
    }
    final paymentHash = '${decoded['payment_hash'] ?? ''}'.toLowerCase();
    final amountMsat = _parseMsat(decoded['amount_msat']);
    if (paymentHash.length != 64 || amountMsat == null || amountMsat <= 0) {
      throw const RpcError(
        'INVOICE_INVALID',
        'invoice senza importo o payment_hash non valido (amountless non supportate).',
      );
    }
    // PERCHÉ: la guardia di pagabilità (STEP 3) e il ri-check di `create`
    // devono conoscere il destinatario — senza payee valido niente quote.
    final payeeId = '${decoded['payee'] ?? ''}'.toLowerCase();
    if (!_nodeIdHex.hasMatch(payeeId)) {
      throw const RpcError(
        'INVOICE_INVALID',
        'invoice senza payee valido (atteso node id da 66 cifre esadecimali).',
      );
    }
    final expirySec = (decoded['expiry'] as num?)?.toInt() ?? 3600;
    final createdAt = (decoded['created_at'] as num?)?.toInt() ?? _nowSec();
    if (createdAt + expirySec < _nowSec()) {
      throw const RpcError('INVOICE_EXPIRED', 'invoice scaduta.');
    }
    return _DecodedInvoice(
      paymentHashHex: paymentHash,
      amountMsat: amountMsat,
      payeeId: payeeId,
    );
  }

  /// Verdetto su una invoice per `swap_info` (nessun effetto collaterale).
  ///
  /// Ritorna sempre un payload: `valid` (fattura leggibile), `reachable`
  /// (destinatario raggiungibile E importo nei limiti) e `reason` col codice
  /// che la UI sa tradurre. // PERCHÉ non lancia: la UI deve MOSTRARE il
  /// motivo ("peer non raggiungibile") invece di gestire un'eccezione.
  Future<Map<String, dynamic>> _checkInvoice(String bolt11) async {
    final _DecodedInvoice inv;
    try {
      inv = await _decodeInvoice(bolt11);
    } on RpcError catch (e) {
      return {
        'valid': false,
        'reachable': false,
        'reason': e.code,
        'message': e.message,
      };
    }
    final feesSats = _config.fees.serviceFeeSats + _config.fees.claimFeeSats;
    final fundingSats = inv.amountSats + feesSats;
    final base = <String, dynamic>{
      'valid': true,
      'payee': inv.payeeId,
      'amount_sats': inv.amountSats,
      'funding_amount_sats': fundingSats,
    };
    if (fundingSats < _config.limits.minSats) {
      return {
        ...base,
        'reachable': false,
        'reason': 'AMOUNT_TOO_SMALL',
        'message': 'importo sotto il minimo (${_config.limits.minSats} sat).',
      };
    }
    if (fundingSats > _config.limits.maxSats) {
      return {
        ...base,
        'reachable': false,
        'reason': 'AMOUNT_TOO_LARGE',
        'message': 'importo oltre il massimo (${_config.limits.maxSats} sat).',
      };
    }
    final issue = await _payabilityIssue(
      payeeId: inv.payeeId,
      amountMsat: inv.amountMsat,
    );
    if (issue != null) {
      return {
        ...base,
        'reachable': false,
        'reason': issue.code,
        'message': issue.message,
      };
    }
    return {...base, 'reachable': true};
  }

  /// Converte `amount_msat` di CLN (int o stringa `"5000000msat"`).
  int? _parseMsat(Object? raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    final s = raw.toString().trim().toLowerCase();
    final match = RegExp(r'^(\d+)msat$').firstMatch(s);
    if (match != null) return int.tryParse(match.group(1)!);
    return int.tryParse(s);
  }

  void _pruneQuotes() {
    final cutoff = _nowSec();
    _quotes.removeWhere((_, q) => q.expiresAt < cutoff);
  }

  String _randomHex(int bytes) => List.generate(
        bytes,
        (_) => _random.nextInt(256),
      ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  int _nowSec() => _clock().millisecondsSinceEpoch ~/ 1000;
}

/// Quote in volo (non persistita: vive quanto il TTL).
class _Quote {
  _Quote({
    required this.clientPubkey,
    required this.invoice,
    required this.payeeId,
    required this.paymentHashHex,
    required this.amountMsat,
    required this.fundingAmountSats,
    required this.cltvHeight,
    required this.refundPubkeyHex,
    required this.htlcAddress,
    required this.witnessScriptHex,
    required this.expiresAt,
  });

  final String clientPubkey;
  final String invoice;
  final String payeeId;
  final String paymentHashHex;
  final int amountMsat;
  final int fundingAmountSats;
  final int cltvHeight;
  final String refundPubkeyHex;
  final String htlcAddress;
  final String witnessScriptHex;
  final int expiresAt;
}

/// Invoice decodificata dal nodo e validata (condivisa da quote e info).
class _DecodedInvoice {
  const _DecodedInvoice({
    required this.paymentHashHex,
    required this.amountMsat,
    required this.payeeId,
  });

  final String paymentHashHex;
  final int amountMsat;

  /// Node id del destinatario (66 hex) — il "peer" del pagamento.
  final String payeeId;

  /// Arrotonda per eccesso: l'HTLC non deve mai valere meno della invoice.
  int get amountSats => (amountMsat + 999) ~/ 1000;
}

/// Problema che impedisce il pagamento (codice + messaggio per il client).
class _PayabilityIssue {
  const _PayabilityIssue(this.code, this.message);

  final String code;
  final String message;
}
