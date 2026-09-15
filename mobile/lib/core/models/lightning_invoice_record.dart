/// Stato di una fattura Lightning, come mostrato all'utente.
///
/// // PERCHÉ: il nodo usa `unpaid` anche DOPO la scadenza — la distinzione
/// "ancora pagabile" / "scaduta" la deriva l'app da `expires_at`, così l'utente
/// non aspetta un pagamento su una fattura che non è più valida.
enum LightningInvoiceState { paid, pending, expired, unknown }

/// Fattura del nodo (spec dln `list_invoices` / `lookup_invoice`).
class LightningInvoiceRecord {
  const LightningInvoiceRecord({
    required this.paymentHash,
    required this.label,
    required this.amountMsat,
    required this.status,
    this.description,
    this.expiresAt,
    this.createdIndex,
    this.paidAt,
    this.amountReceivedMsat,
  });

  final String paymentHash;
  final String label;
  final int amountMsat;

  /// Stato grezzo dal nodo (`unpaid`, `paid`, …).
  final String status;

  final String? description;

  /// Scadenza in secondi epoch (UTC).
  final int? expiresAt;

  /// Indice di creazione sul nodo (ordinamento: cresce nel tempo).
  final int? createdIndex;

  /// Secondi epoch del pagamento (presente solo sulle fatture pagate).
  final int? paidAt;

  /// Importo effettivamente ricevuto (msat, può differire dal richiesto).
  final int? amountReceivedMsat;

  int get amountSats => amountMsat ~/ 1000;

  bool get isPaid => status.toLowerCase() == 'paid';

  /// Stato mostrato in UI (scadenza derivata quando il nodo dice `unpaid`).
  LightningInvoiceState get state {
    if (isPaid) return LightningInvoiceState.paid;
    // PERCHÉ: uno stato non riconosciuto non va interpretato: si mostra grezzo.
    if (status.toLowerCase() != 'unpaid') {
      return LightningInvoiceState.unknown;
    }
    final expires = expiresAt;
    if (expires == null) {
      return LightningInvoiceState.pending;
    }
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return nowSeconds > expires
        ? LightningInvoiceState.expired
        : LightningInvoiceState.pending;
  }

  DateTime? get expiryDate => expiresAt == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(expiresAt! * 1000, isUtc: true)
          .toLocal();

  DateTime? get paidDate => paidAt == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(paidAt! * 1000, isUtc: true)
          .toLocal();

  factory LightningInvoiceRecord.fromJson(Map<String, dynamic> json) =>
      LightningInvoiceRecord(
        paymentHash: '${json['payment_hash'] ?? ''}',
        label: '${json['label'] ?? ''}',
        amountMsat: (json['amount_msat'] as num?)?.toInt() ?? 0,
        status: '${json['status'] ?? 'unknown'}',
        description: (json['description']?.toString().isEmpty ?? true)
            ? null
            : json['description']?.toString(),
        expiresAt: (json['expires_at'] as num?)?.toInt(),
        createdIndex: (json['created_index'] as num?)?.toInt(),
        paidAt: (json['paid_at'] as num?)?.toInt(),
        amountReceivedMsat: (json['amount_received_msat'] as num?)?.toInt(),
      );
}
