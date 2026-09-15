/// Indirizzo on-chain del nodo remoto (dln `make_new_address` / `list_addresses`).
class LightningNodeAddress {
  const LightningNodeAddress({
    required this.address,
    this.type,
    this.keyIndex,
    this.hasFunds,
    this.amountMsat,
  });

  final String address;

  /// `bech32` | `p2tr` (come riportato dal nodo).
  final String? type;

  /// Indice della chiave nel wallet del nodo (diagnostica/ordine).
  final int? keyIndex;

  /// True se questo indirizzo detiene oggi fondi on-chain.
  ///
  /// // PERCHÉ: CLN non espone un flag "usato" — il bridge lo deduce dagli
  /// output non spesi in `listfunds`: il significato è "con saldo", non
  /// "già usato" (un indirizzo speso torna a risultare vuoto).
  final bool? hasFunds;

  /// Fondi attribuiti a questo indirizzo (msat) — presente solo nel fallback
  /// su `listfunds`.
  final int? amountMsat;

  /// Indirizzo abbreviato per la UI: inizio e fine, copia sempre possibile.
  String get shortAddress => address.length <= 18
      ? address
      : '${address.substring(0, 10)}…${address.substring(address.length - 6)}';

  factory LightningNodeAddress.fromJson(Map<String, dynamic> json) =>
      LightningNodeAddress(
        address: '${json['address'] ?? ''}',
        type: json['type']?.toString(),
        keyIndex: (json['keyidx'] as num?)?.toInt(),
        // PERCHÉ: il bridge reale invia `has_funds`; `used` resta accettato per
        // retrocompatibilità con payload precedenti.
        hasFunds: (json['has_funds'] as bool?) ?? (json['used'] as bool?),
        amountMsat: (json['amount_msat'] as num?)?.toInt(),
      );
}
