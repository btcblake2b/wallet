import 'dart:convert';

import 'swap_consts.dart';

/// Stato della sessione di swap visto dall'APP (specchio del wire `state`).
enum SwapClientState {
  awaitingFunding,
  confirming,
  paying,
  paid,
  claiming,
  completed,
  paymentFailed,
  expired,
  refunded;

  /// Nome stabile sul protocollo (JSON).
  String get wireName => name;

  /// Parse tollerante: uno stato sconosciuto (provider più nuovo) diventa
  /// [SwapClientState.awaitingFunding] invece di far crashare la UI.
  ///
  /// // PERCHÉ: app e provider possono essere aggiornati in momenti diversi;
  /// // la UI mostra comunque "in corso" e la verità resta lo `swap_status`.
  static SwapClientState fromWireName(String name) => SwapClientState.values
      .firstWhere((s) => s.name == name, orElse: () => awaitingFunding);

  /// Stati in cui il provider sta lavorando (fondi bloccati nell'HTLC).
  bool get isActive =>
      this == awaitingFunding ||
      this == confirming ||
      this == paying ||
      this == paid ||
      this == claiming;

  /// Stati finali: la sessione non evolve più.
  bool get isTerminal => this == completed || this == refunded;

  /// Stati in cui l'utente può recuperare i fondi col refund.
  bool get isRefundable => this == paymentFailed || this == expired;
}

/// Errore del protocollo swap (codici dal provider: DUPLICATE_SWAP, TIMEOUT…).
class SwapException implements Exception {
  const SwapException(this.code, this.message);

  final String code;
  final String message;

  /// True se l'errore è probabilmente transitorio (rete/relay/timeout):
  /// la UI può offrire "Riprova".
  bool get isTransient =>
      code == 'TIMEOUT' ||
      code == 'CONNECT_FAILED' ||
      code == 'NOT_CONNECTED' ||
      code == 'PUBLISH_FAILED';

  /// True se l'input utente va corretto (invoice/importo) prima di riprovare.
  bool get isInputError =>
      code == 'INVOICE_INVALID' ||
      code == 'INVOICE_EXPIRED' ||
      code == 'AMOUNT_TOO_SMALL' ||
      code == 'AMOUNT_TOO_LARGE' ||
      code == 'BAD_REQUEST';

  @override
  String toString() => 'SwapException($code): $message';
}

/// Provider swap a cui l'app si collega (una URI = un provider).
///
/// URI: `nostr+swap://<provider_pubkey>?v=1&network=blake2b&relay=wss://…`
/// (relay ripetibile più volte). L'app genera la PROPRIA chiave client e la
/// tiene solo in secure storage — la URI non contiene segreti.
class SwapProvider {
  const SwapProvider({
    required this.providerPubkey,
    required this.relays,
    this.network = SwapConsts.network,
  });

  /// Pubkey x-only (hex 64) del provider — destinatario delle richieste.
  final String providerPubkey;

  /// Relay Nostr su cui parlare col provider (almeno 1).
  final List<String> relays;

  /// Rete dichiarata dal provider (deve essere `blake2b`).
  final String network;

  static final RegExp _hex64 = RegExp(r'^[0-9a-fA-F]{64}$');

  /// Parsa e valida l'URI del provider. Lancia [FormatException] se malformata.
  static SwapProvider fromUri(String uri) {
    final parsed = Uri.tryParse(uri.trim());
    if (parsed == null || parsed.scheme != SwapConsts.uriScheme) {
      throw const FormatException(
        'URI non valida: atteso schema nostr+swap://',
      );
    }
    if ((parsed.queryParameters['v'] ?? '1') != '${SwapConsts.protocolVersion}') {
      throw const FormatException(
        'versione protocollo non supportata da questa app',
      );
    }
    final network = parsed.queryParameters['network'] ?? SwapConsts.network;
    if (network != SwapConsts.network) {
      throw FormatException('rete non supportata: $network');
    }
    // PERCHÉ: nella URI la pubkey del provider è l'"authority" (host).
    final pubkey = parsed.host.toLowerCase();
    if (!_hex64.hasMatch(pubkey)) {
      throw const FormatException(
        'provider pubkey mancante o non valida (attesi 64 char hex)',
      );
    }
    final relays = (parsed.queryParametersAll['relay'] ?? const <String>[])
        .where((r) => r.startsWith('wss://') || r.startsWith('ws://'))
        .toList();
    if (relays.isEmpty) {
      throw const FormatException('nessun relay wss:// nella URI');
    }
    return SwapProvider(
      providerPubkey: pubkey,
      relays: relays,
      network: network,
    );
  }

  /// Ricostruisce la URI (usata per la persistenza in secure storage).
  String toUri() => Uri(
        scheme: SwapConsts.uriScheme,
        host: providerPubkey,
        queryParameters: <String, dynamic>{
          'v': '${SwapConsts.protocolVersion}',
          'network': network,
          'relay': relays,
        },
      ).toString();

  @override
  String toString() =>
      'SwapProvider(pubkey: $providerPubkey, relays: $relays, network: $network)';
}

/// Risposta della quote: tutto ciò che serve per finanziare l'HTLC.
class SwapQuote {
  const SwapQuote({
    required this.quoteId,
    required this.expiresAt,
    required this.paymentHashHex,
    required this.amountMsat,
    required this.amountSats,
    required this.serviceFeeSats,
    required this.claimFeeSats,
    required this.fundingAmountSats,
    required this.cltvHeight,
    required this.claimPubkeyHex,
    required this.refundPubkeyHex,
    required this.htlcAddress,
    required this.witnessScriptHex,
    required this.network,
  });

  final String quoteId;
  final int expiresAt;
  final String paymentHashHex;
  final int amountMsat;
  final int amountSats;
  final int serviceFeeSats;
  final int claimFeeSats;

  /// Totale da bloccare nell'HTLC = invoice + service fee + claim fee.
  final int fundingAmountSats;
  final int cltvHeight;
  final String claimPubkeyHex;
  final String refundPubkeyHex;
  final String htlcAddress;
  final String witnessScriptHex;
  final String network;

  bool isExpiredAt(int nowSec) => nowSec >= expiresAt;

  factory SwapQuote.fromJson(Map<String, dynamic> json) => SwapQuote(
        quoteId: _str(json, 'quote_id'),
        expiresAt: _int(json, 'expires_at'),
        paymentHashHex: _str(json, 'payment_hash'),
        amountMsat: _int(json, 'amount_msat'),
        amountSats: _int(json, 'amount_sats'),
        serviceFeeSats: _int(json, 'service_fee_sats'),
        claimFeeSats: _int(json, 'claim_fee_sats'),
        fundingAmountSats: _int(json, 'funding_amount_sats'),
        cltvHeight: _int(json, 'cltv_height'),
        claimPubkeyHex: _str(json, 'claim_pubkey'),
        refundPubkeyHex: _str(json, 'refund_pubkey'),
        htlcAddress: _str(json, 'htlc_address'),
        witnessScriptHex: _str(json, 'witness_script_hex'),
        network: _str(json, 'network'),
      );

  Map<String, dynamic> toJson() => {
        'quote_id': quoteId,
        'expires_at': expiresAt,
        'payment_hash': paymentHashHex,
        'amount_msat': amountMsat,
        'amount_sats': amountSats,
        'service_fee_sats': serviceFeeSats,
        'claim_fee_sats': claimFeeSats,
        'funding_amount_sats': fundingAmountSats,
        'cltv_height': cltvHeight,
        'claim_pubkey': claimPubkeyHex,
        'refund_pubkey': refundPubkeyHex,
        'htlc_address': htlcAddress,
        'witness_script_hex': witnessScriptHex,
        'network': network,
      };
}

/// Stato di una sessione di swap (risposta di create/funding/status).
class SwapStatus {
  const SwapStatus({
    required this.swapId,
    required this.state,
    required this.htlcAddress,
    required this.witnessScriptHex,
    required this.fundingAmountSats,
    required this.cltvHeight,
    required this.fundingDeadlineHeight,
    required this.createdAt,
    required this.updatedAt,
    this.fundingTxid,
    this.fundingVout,
    this.fundingHeight,
    this.fundingConfirmations,
    this.claimTxid,
    this.errorCode,
    this.errorMessage,
  });

  final String swapId;
  final SwapClientState state;
  final String htlcAddress;
  final String witnessScriptHex;
  final int fundingAmountSats;
  final int cltvHeight;
  final int fundingDeadlineHeight;
  final String? fundingTxid;
  final int? fundingVout;
  final int? fundingHeight;

  /// Presente solo nella risposta di `swap_status` (calcolato dal provider).
  final int? fundingConfirmations;
  final String? claimTxid;
  final String? errorCode;
  final String? errorMessage;
  final int createdAt;
  final int updatedAt;

  factory SwapStatus.fromJson(Map<String, dynamic> json) {
    final error = json['error'];
    return SwapStatus(
      swapId: _str(json, 'swap_id'),
      state: SwapClientState.fromWireName('${json['state'] ?? ''}'),
      htlcAddress: _str(json, 'htlc_address'),
      witnessScriptHex: _str(json, 'witness_script_hex'),
      fundingAmountSats: _int(json, 'funding_amount_sats'),
      cltvHeight: _int(json, 'cltv_height'),
      fundingDeadlineHeight: _int(json, 'funding_deadline_height'),
      fundingTxid: _optStr(json, 'funding_txid'),
      fundingVout: _optInt(json, 'funding_vout'),
      fundingHeight: _optInt(json, 'funding_height'),
      fundingConfirmations: _optInt(json, 'funding_confirmations'),
      claimTxid: _optStr(json, 'claim_txid'),
      errorCode: error is Map ? _optStr(error, 'code') : null,
      errorMessage: error is Map ? _optStr(error, 'message') : null,
      createdAt: _int(json, 'created_at'),
      updatedAt: _int(json, 'updated_at'),
    );
  }
}

/// Sessione di swap persistita dall'APP (secure storage).
///
/// Contiene SOLO dati pubblici (on-chain e di protocollo) + l'indice della
/// chiave di refund: nessun segreto — il seed resta nell'unico posto in cui
/// vive (il vault del wallet).
class SwapSession {
  const SwapSession({
    required this.swapId,
    required this.invoice,
    required this.paymentHashHex,
    required this.fundingAmountSats,
    required this.cltvHeight,
    required this.fundingDeadlineHeight,
    required this.claimPubkeyHex,
    required this.refundPubkeyHex,
    required this.refundKeyIndex,
    required this.htlcAddress,
    required this.witnessScriptHex,
    required this.providerPubkey,
    required this.relays,
    this.walletId,
    this.walletName,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
    this.fundingTxid,
    this.fundingVout,
    this.claimTxid,
    this.preimageHex,
    this.errorCode,
    this.errorMessage,
  });

  final String swapId;
  final String invoice;
  final String paymentHashHex;
  final int fundingAmountSats;
  final int cltvHeight;
  final int fundingDeadlineHeight;
  final String claimPubkeyHex;
  final String refundPubkeyHex;

  /// Indice x in `m/84'/coin'/2'/0/x` della chiave di refund di QUESTA
  /// sessione (mai riusata fra swap).
  final int refundKeyIndex;
  final String htlcAddress;
  final String witnessScriptHex;

  /// Provider di riferimento (per riconnettersi in recovery).
  final String providerPubkey;
  final List<String> relays;

  /// Wallet dell'app legato alla sessione.
  ///
  /// // PERCHÉ: la chiave di refund deriva dal SEED di un wallet specifico —
  /// // il funding e il refund DEVONO usare quel wallet, altrimenti i fondi
  /// // dell'HTLC non sarebbero recuperabili (nessun altro seed ha la chiave).
  final String? walletId;
  final String? walletName;

  final SwapClientState state;
  final int createdAt;
  final int updatedAt;
  final String? fundingTxid;
  final int? fundingVout;
  final String? claimTxid;

  /// Preimage dell'invoice (nota solo se il pagamento è andato a buon fine).
  final String? preimageHex;
  final String? errorCode;
  final String? errorMessage;

  /// Sessioni "vive" o comunque da seguire (non ancora finali/refunded).
  bool get needsAttention => state.isActive || state.isRefundable;

  SwapSession copyWith({
    SwapClientState? state,
    String? fundingTxid,
    int? fundingVout,
    String? claimTxid,
    String? preimageHex,
    String? errorCode,
    String? errorMessage,
    int? updatedAt,
  }) =>
      SwapSession(
        swapId: swapId,
        invoice: invoice,
        paymentHashHex: paymentHashHex,
        fundingAmountSats: fundingAmountSats,
        cltvHeight: cltvHeight,
        fundingDeadlineHeight: fundingDeadlineHeight,
        claimPubkeyHex: claimPubkeyHex,
        refundPubkeyHex: refundPubkeyHex,
        refundKeyIndex: refundKeyIndex,
        htlcAddress: htlcAddress,
        witnessScriptHex: witnessScriptHex,
        providerPubkey: providerPubkey,
        relays: relays,
        walletId: walletId,
        walletName: walletName,
        state: state ?? this.state,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        fundingTxid: fundingTxid ?? this.fundingTxid,
        fundingVout: fundingVout ?? this.fundingVout,
        claimTxid: claimTxid ?? this.claimTxid,
        preimageHex: preimageHex ?? this.preimageHex,
        errorCode: errorCode ?? this.errorCode,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  Map<String, dynamic> toJson() => {
        'swap_id': swapId,
        'invoice': invoice,
        'payment_hash': paymentHashHex,
        'funding_amount_sats': fundingAmountSats,
        'cltv_height': cltvHeight,
        'funding_deadline_height': fundingDeadlineHeight,
        'claim_pubkey': claimPubkeyHex,
        'refund_pubkey': refundPubkeyHex,
        'refund_key_index': refundKeyIndex,
        'htlc_address': htlcAddress,
        'witness_script_hex': witnessScriptHex,
        'provider_pubkey': providerPubkey,
        'relays': relays,
        if (walletId != null) 'wallet_id': walletId,
        if (walletName != null) 'wallet_name': walletName,
        'state': state.wireName,
        'created_at': createdAt,
        'updated_at': updatedAt,
        if (fundingTxid != null) 'funding_txid': fundingTxid,
        if (fundingVout != null) 'funding_vout': fundingVout,
        if (claimTxid != null) 'claim_txid': claimTxid,
        if (preimageHex != null) 'preimage': preimageHex,
        if (errorCode != null) 'error_code': errorCode,
        if (errorMessage != null) 'error_message': errorMessage,
      };

  factory SwapSession.fromJson(Map<String, dynamic> json) => SwapSession(
        swapId: _str(json, 'swap_id'),
        invoice: _str(json, 'invoice'),
        paymentHashHex: _str(json, 'payment_hash'),
        fundingAmountSats: _int(json, 'funding_amount_sats'),
        cltvHeight: _int(json, 'cltv_height'),
        fundingDeadlineHeight: _int(json, 'funding_deadline_height'),
        claimPubkeyHex: _str(json, 'claim_pubkey'),
        refundPubkeyHex: _str(json, 'refund_pubkey'),
        refundKeyIndex: _int(json, 'refund_key_index'),
        htlcAddress: _str(json, 'htlc_address'),
        witnessScriptHex: _str(json, 'witness_script_hex'),
        providerPubkey: _str(json, 'provider_pubkey'),
        relays: ((json['relays'] as List?) ?? const [])
            .map((r) => '$r')
            .toList(),
        walletId: _optStr(json, 'wallet_id'),
        walletName: _optStr(json, 'wallet_name'),
        state: SwapClientState.fromWireName('${json['state'] ?? ''}'),
        createdAt: _int(json, 'created_at'),
        updatedAt: _int(json, 'updated_at'),
        fundingTxid: _optStr(json, 'funding_txid'),
        fundingVout: _optInt(json, 'funding_vout'),
        claimTxid: _optStr(json, 'claim_txid'),
        preimageHex: _optStr(json, 'preimage'),
        errorCode: _optStr(json, 'error_code'),
        errorMessage: _optStr(json, 'error_message'),
      );
}

/// Export/import della sessione per il recupero fondi (P9, "Recupera fondi").
///
/// Formato: `swaprecover1.<base64url(json della sessione)>`.
/// // PERCHÉ: l'utente deve poter fare refund anche se perde il telefono:
/// // col seed + questo blob ricostruisce l'HTLC e la transazione di refund,
/// // senza che il blob stesso contenga alcun segreto.
abstract final class SwapRecoveryBlob {
  static String encode(SwapSession session) =>
      SwapConsts.recoveryPrefix +
      base64Url.encode(utf8.encode(jsonEncode(session.toJson())));

  static SwapSession decode(String blob) {
    final trimmed = blob.trim();
    if (!trimmed.startsWith(SwapConsts.recoveryPrefix)) {
      throw const FormatException(
        'blob non valido: atteso prefisso swaprecover1.',
      );
    }
    try {
      final payload = trimmed.substring(SwapConsts.recoveryPrefix.length);
      final json = jsonDecode(utf8.decode(base64Url.decode(payload)));
      if (json is! Map<String, dynamic>) {
        throw const FormatException('blob non valido: JSON non oggetto');
      }
      return SwapSession.fromJson(json);
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('blob non decodificabile: $e');
    }
  }
}

// ── Helper di parsing (chiavi snake_case, errori espliciti) ──────────────────

String _str(Map<dynamic, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('campo "$key" mancante o non valido');
}

String? _optStr(Map<dynamic, dynamic> json, String key) {
  final value = json[key];
  return (value is String && value.isNotEmpty) ? value : null;
}

int _int(Map<dynamic, dynamic> json, String key) {
  final value = _optInt(json, key);
  if (value == null) {
    throw FormatException('campo "$key" mancante o non valido');
  }
  return value;
}

int? _optInt(Map<dynamic, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
