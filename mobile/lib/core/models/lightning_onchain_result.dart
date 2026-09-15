/// Esito di un invio on-chain dal nodo (spec dln `pay_onchain`).
class LightningOnchainResult {
  const LightningOnchainResult({required this.txid});

  final String txid;

  factory LightningOnchainResult.fromJson(Map<String, dynamic> json) =>
      LightningOnchainResult(txid: '${json['txid'] ?? ''}');
}
