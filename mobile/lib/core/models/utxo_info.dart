/// UtxoInfo — Unspent Transaction Output del wallet.
///
/// PERCHÉ: spostato da `bitcoin_service.dart` in `core/models` per evitare un
/// import circolare con `WalletSnapshot` (che lo contiene e che
/// `BitcoinService.fetchWalletSnapshot` deve costruire). `bitcoin_service.dart`
/// ri-esporta il simbolo → nessun consumer esistente si rompe.
class UtxoInfo {
  final String txid;
  final int vout;
  final int valueSat;
  // scriptpubkey hex as returned by blockstream/mempool APIs
  final String? scriptPubKeyHex;
  // scriptpubkey_type e.g. "v0_p2wpkh", "v0_p2wsh", "p2sh", "v1_p2tr"
  final String? scriptPubKeyType;
  final String? scriptPubKeyAddress;
  final String? ownerAddress;
  final String? ownerDerivationPath;
  // PERCHÉ (S7): 0 = pending, 1+ = confermata, null = sconosciuta (API fallita).
  // Campo OPZIONALE → zero breaking su costruttori/copyWith esistenti.
  final int? confirmations;
  // PERCHÉ (A3-bis): altezza del blocco che contiene l'UTXO. Serve perché la
  // maturity dipende dall'ALTEZZA della coinbase, non solo dalle conferme: le
  // coinbase dell'epoca 973.440-979.918 si sbloccano tutte a 979.919, quelle
  // da 979.919 maturano dopo 25.920 blocchi (vedi `CoinbaseMaturityRules`).
  // `null` = altezza ignota → il guard applica la regola più restrittiva.
  final int? blockHeight;
  // PERCHÉ (A3): i payout di mining arrivano da una coinbase e la rete non ne
  // propaga la spesa prima della maturity di rete (25.920 blocchi sulla mainnet
  // blake2b dal 979.919): il coin selection deve poterli riconoscere ed
  // escludere. Default `false` → zero breaking sui costruttori esistenti.
  final bool isCoinbase;

  UtxoInfo({
    required this.txid,
    required this.vout,
    required this.valueSat,
    this.scriptPubKeyHex,
    this.scriptPubKeyType,
    this.scriptPubKeyAddress,
    this.ownerAddress,
    this.ownerDerivationPath,
    this.confirmations,
    this.blockHeight,
    this.isCoinbase = false,
  });

  UtxoInfo copyWith({
    String? scriptPubKeyHex,
    String? scriptPubKeyType,
    String? scriptPubKeyAddress,
    String? ownerAddress,
    String? ownerDerivationPath,
    int? confirmations,
    int? blockHeight,
    bool? isCoinbase,
  }) {
    return UtxoInfo(
      txid: txid,
      vout: vout,
      valueSat: valueSat,
      scriptPubKeyHex: scriptPubKeyHex ?? this.scriptPubKeyHex,
      scriptPubKeyType: scriptPubKeyType ?? this.scriptPubKeyType,
      scriptPubKeyAddress: scriptPubKeyAddress ?? this.scriptPubKeyAddress,
      ownerAddress: ownerAddress ?? this.ownerAddress,
      ownerDerivationPath: ownerDerivationPath ?? this.ownerDerivationPath,
      confirmations: confirmations ?? this.confirmations,
      blockHeight: blockHeight ?? this.blockHeight,
      isCoinbase: isCoinbase ?? this.isCoinbase,
    );
  }
}
