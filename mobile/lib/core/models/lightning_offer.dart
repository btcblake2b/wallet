/// Offerta BOLT12 (NCC `make_offer`, estensione del bridge).
///
/// // PERCHÉ (BOLT12): una fattura BOLT11 è monouso e scade; un'offerta è un
/// // codice stabile (`lno1…`) che chi paga trasforma in fattura al momento.
/// // È il modo per ricevere senza rigenerare un QR ogni volta. Senza
/// // `amountMsat` l'offerta è a importo libero: lo sceglie chi paga.
class LightningOffer {
  const LightningOffer({
    required this.offerId,
    required this.bolt12,
    required this.description,
    this.amountMsat,
    this.singleUse = false,
  });

  /// Identificativo dell'offerta sul nodo (per disattivarla/riusarla).
  final String offerId;

  /// Codice da condividere (`lno1…`), tipicamente in un QR.
  final String bolt12;

  /// Descrizione mostrata a chi paga.
  final String description;

  /// Importo fisso in msat (null = importo libero).
  final int? amountMsat;

  /// True se il nodo accetterà un solo pagamento.
  final bool singleUse;

  int? get amountSats => amountMsat == null ? null : amountMsat! ~/ 1000;

  factory LightningOffer.fromJson(
    Map<String, dynamic> json, {
    String description = '',
  }) =>
      LightningOffer(
        offerId: '${json['offer_id'] ?? ''}',
        bolt12: '${json['bolt12'] ?? ''}',
        description: description,
        amountMsat: (json['amount_msat'] as num?)?.toInt(),
        singleUse: json['single_use'] as bool? ?? false,
      );
}
