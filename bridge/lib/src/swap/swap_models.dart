import 'swap_script.dart';

/// Stato della sessione di swap sul lato PROVIDER (macchina a stati, §2.7).
enum SwapState {
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

  static SwapState fromWireName(String name) =>
      SwapState.values.firstWhere((s) => s.name == name);

  /// Stati in cui la sessione è "viva" (il provider sta lavorando).
  bool get isActive =>
      this == awaitingFunding ||
      this == confirming ||
      this == paying ||
      this == paid ||
      this == claiming;

  /// Stati che bloccano una NUOVA sessione con lo stesso payment_hash.
  ///
  /// PERCHÉ: impedire al client di rifinanziare lo stesso hash mentre una
  /// sessione è in corso o in attesa di refund — il secondo funding sarebbe
  /// inutile (l'invoice si paga una volta sola) e andrebbe refundato.
  bool get blocksPaymentHash => this != completed && this != refunded;

  /// Stati in cui l'utente può (o potrà) recuperare i fondi col refund.
  bool get isRefundable => this == paymentFailed || this == expired;
}

/// Sessione di swap persistita dal provider (store JSON atomico).
class SwapSession {
  SwapSession({
    required this.id,
    required this.clientPubkey,
    required this.invoice,
    required this.paymentHashHex,
    required this.amountMsat,
    required this.fundingAmountSats,
    required this.serviceFeeSats,
    required this.claimFeeSats,
    required this.cltvHeight,
    required this.claimPubkeyHex,
    required this.refundPubkeyHex,
    required this.htlcAddress,
    required this.witnessScriptHex,
    required this.fundingDeadlineHeight,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
    this.fundingTxid,
    this.fundingVout,
    this.fundingHeight,
    this.preimageHex,
    this.claimTxid,
    this.payAttempts = 0,
    this.claimAttempts = 0,
    this.errorCode,
    this.errorMessage,
  });

  final String id;
  final String clientPubkey;
  final String invoice;
  final String paymentHashHex;
  final int amountMsat;

  /// Totale da bloccare nell'HTLC = invoice + service fee + claim fee.
  final int fundingAmountSats;
  final int serviceFeeSats;
  final int claimFeeSats;
  final int cltvHeight;
  final String claimPubkeyHex;
  final String refundPubkeyHex;
  final String htlcAddress;
  final String witnessScriptHex;

  /// Altezza oltre la quale il provider NON paga più (margine claim+buffer).
  final int fundingDeadlineHeight;

  final SwapState state;
  final int createdAt;
  final int updatedAt;

  /// Funding osservato (txid annunciato + vout/height al momento del match).
  final String? fundingTxid;
  final int? fundingVout;
  final int? fundingHeight;

  /// Preimage dell'invoice, memorizzata appena il pagamento riesce.
  final String? preimageHex;
  final String? claimTxid;
  final int payAttempts;
  final int claimAttempts;
  final String? errorCode;
  final String? errorMessage;

  /// Parametri dello script HTLC ricostruibili dalla sessione.
  SwapScriptParams get scriptParams => SwapScriptParams(
        paymentHashHex: paymentHashHex,
        claimPubkeyHex: claimPubkeyHex,
        refundPubkeyHex: refundPubkeyHex,
        cltvHeight: cltvHeight,
      );

  SwapSession copyWith({
    SwapState? state,
    String? fundingTxid,
    int? fundingVout,
    int? fundingHeight,
    String? preimageHex,
    String? claimTxid,
    int? payAttempts,
    int? claimAttempts,
    String? errorCode,
    String? errorMessage,
    int? updatedAt,
  }) =>
      SwapSession(
        id: id,
        clientPubkey: clientPubkey,
        invoice: invoice,
        paymentHashHex: paymentHashHex,
        amountMsat: amountMsat,
        fundingAmountSats: fundingAmountSats,
        serviceFeeSats: serviceFeeSats,
        claimFeeSats: claimFeeSats,
        cltvHeight: cltvHeight,
        claimPubkeyHex: claimPubkeyHex,
        refundPubkeyHex: refundPubkeyHex,
        htlcAddress: htlcAddress,
        witnessScriptHex: witnessScriptHex,
        fundingDeadlineHeight: fundingDeadlineHeight,
        state: state ?? this.state,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        fundingTxid: fundingTxid ?? this.fundingTxid,
        fundingVout: fundingVout ?? this.fundingVout,
        fundingHeight: fundingHeight ?? this.fundingHeight,
        preimageHex: preimageHex ?? this.preimageHex,
        claimTxid: claimTxid ?? this.claimTxid,
        payAttempts: payAttempts ?? this.payAttempts,
        claimAttempts: claimAttempts ?? this.claimAttempts,
        errorCode: errorCode ?? this.errorCode,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'client_pubkey': clientPubkey,
        'invoice': invoice,
        'payment_hash': paymentHashHex,
        'amount_msat': amountMsat,
        'funding_amount_sats': fundingAmountSats,
        'service_fee_sats': serviceFeeSats,
        'claim_fee_sats': claimFeeSats,
        'cltv_height': cltvHeight,
        'claim_pubkey': claimPubkeyHex,
        'refund_pubkey': refundPubkeyHex,
        'htlc_address': htlcAddress,
        'witness_script': witnessScriptHex,
        'funding_deadline_height': fundingDeadlineHeight,
        'state': state.wireName,
        if (fundingTxid != null) 'funding_txid': fundingTxid,
        if (fundingVout != null) 'funding_vout': fundingVout,
        if (fundingHeight != null) 'funding_height': fundingHeight,
        if (preimageHex != null) 'preimage': preimageHex,
        if (claimTxid != null) 'claim_txid': claimTxid,
        'pay_attempts': payAttempts,
        'claim_attempts': claimAttempts,
        if (errorCode != null) 'error_code': errorCode,
        if (errorMessage != null) 'error_message': errorMessage,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  static SwapSession fromJson(Map<String, dynamic> json) {
    T req<T>(String key) {
      final v = json[key];
      if (v is T) return v;
      throw FormatException('sessione swap: campo "$key" mancante o invalido');
    }

    return SwapSession(
      id: req<String>('id'),
      clientPubkey: req<String>('client_pubkey'),
      invoice: req<String>('invoice'),
      paymentHashHex: req<String>('payment_hash'),
      amountMsat: req<int>('amount_msat'),
      fundingAmountSats: req<int>('funding_amount_sats'),
      serviceFeeSats: req<int>('service_fee_sats'),
      claimFeeSats: req<int>('claim_fee_sats'),
      cltvHeight: req<int>('cltv_height'),
      claimPubkeyHex: req<String>('claim_pubkey'),
      refundPubkeyHex: req<String>('refund_pubkey'),
      htlcAddress: req<String>('htlc_address'),
      witnessScriptHex: req<String>('witness_script'),
      fundingDeadlineHeight: req<int>('funding_deadline_height'),
      state: SwapState.fromWireName(req<String>('state')),
      createdAt: req<int>('created_at'),
      updatedAt: req<int>('updated_at'),
      fundingTxid: json['funding_txid'] as String?,
      fundingVout: json['funding_vout'] as int?,
      fundingHeight: json['funding_height'] as int?,
      preimageHex: json['preimage'] as String?,
      claimTxid: json['claim_txid'] as String?,
      payAttempts: (json['pay_attempts'] as int?) ?? 0,
      claimAttempts: (json['claim_attempts'] as int?) ?? 0,
      errorCode: json['error_code'] as String?,
      errorMessage: json['error_message'] as String?,
    );
  }

  @override
  String toString() =>
      'SwapSession(${id.length > 8 ? '${id.substring(0, 8)}…' : id}, $state)';
}
