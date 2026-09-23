/// SendOutput — un destinatario di una transazione on-chain.
///
/// PERCHÉ (P3): il percorso di invio storicamente conosceva UN solo
/// destinatario (`toAddress` + `amountSats` sparsi in `BuildTxData`,
/// `_buildAndSignTx`, `RbfTxParams`). Con il batch send la lista diventa il
/// modello di verità e il caso singolo è una lista di un elemento: così la
/// firma UNIFIED (che accetta già `List<BitcoinOutput>`) resta l'unica via.
///
/// Modello manuale (nessun codegen), immutabile, senza serializzazione:
/// vive solo in memoria per la durata della costruzione/firma della tx —
/// non viene mai persistito (come [RbfTxParams]).
class SendOutput {
  const SendOutput({required this.address, required this.amountSats});

  /// Soglia dust: sotto questo valore l'output non è spendibile dai nodi
  /// (tx non standard → rifiutata). Deve combaciare con il `dustLimit` usato
  /// in `_buildAndSignTx` (546 sat).
  static const int dustLimitSats = 546;

  /// Indirizzo di destinazione (formato rete corrente: bech32/base58).
  final String address;

  /// Importo in satoshi per questo destinatario.
  final int amountSats;

  /// // PERCHÉ: un importo < 546 sat rende l'output non spendibile — la UI
  /// // deve bloccarlo PRIMA della firma, non il nodo dopo il broadcast.
  bool get isDust => amountSats < dustLimitSats;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SendOutput &&
          other.address == address &&
          other.amountSats == amountSats;

  @override
  int get hashCode => Object.hash(address, amountSats);

  @override
  String toString() => 'SendOutput($address, $amountSats sat)';
}
