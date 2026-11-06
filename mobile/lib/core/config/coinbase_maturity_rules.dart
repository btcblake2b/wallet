/// Regole di maturity di un output coinbase per una rete.
///
/// PERCHÉ: dalla mainnet blake2b, dal blocco 979.919, non vale più una
/// profondità unica contata in conferme. Bitcoin Knots `v29.4.3` (PR
/// `bitcoinknots/bitcoin#419`, consenso `knots#468`) lascia in vigore due
/// regole diverse:
///
/// - **epoca 973.440 – 979.918** (45 giorni): le coinbase di quella finestra
///   si sbloccano TUTTE INSIEME a 979.919 — non ognuna dopo 6.480 conferme;
/// - **dal 979.919** (180 giorni): ogni coinbase matura dopo 25.920 blocchi,
///   fino all'expiry RDTS (2027-09), dopodiché la regola cambierà ancora.
///
/// Una coinbase minata a fine epoca deve comunque le 100 conferme ordinarie
/// dopo la chiusura della finestra: lo sblocco è il PIÙ TARDO fra i due
/// vincoli. Contare le conferme contro una sola costante risponde male in
/// entrambi i casi (troppo permissivo per i blocchi nuovi, troppo restrittivo
/// per quelli dell'epoca).
class CoinbaseMaturityRules {
  const CoinbaseMaturityRules({
    required this.longMaturityBlocks,
    this.longStartHeight,
    this.epochStartHeight,
    this.epochReleaseHeight,
    this.consensusMaturityBlocks = 100,
  });

  /// Profondità della regola più recente (25.920 blocchi mainnet, ~180 giorni).
  /// Su una rete senza epoche è l'unica regola: profondità fissa.
  final int longMaturityBlocks;

  /// Altezza da cui vale [longMaturityBlocks]. `null` → rete senza epoche.
  final int? longStartHeight;

  /// Prima altezza dell'epoca a sblocco comune (973.440). `null` → nessuna epoca.
  final int? epochStartHeight;

  /// Altezza a cui si sbloccano le coinbase dell'epoca (979.919).
  final int? epochReleaseHeight;

  /// Maturity di consenso ordinaria (100 blocchi), sempre dovuta.
  final int consensusMaturityBlocks;

  /// Blocchi di attesa dovuti da una coinbase generata a [coinbaseHeight].
  int requiredDepth(int coinbaseHeight) {
    final epochStart = epochStartHeight;
    final epochRelease = epochReleaseHeight;
    final longStart = longStartHeight;
    if (epochStart == null || epochRelease == null || longStart == null) {
      return longMaturityBlocks;
    }
    if (coinbaseHeight >= longStart) return longMaturityBlocks;
    // Conferme che mancano allo sblocco comune (+1: la conferma del blocco
    // stesso), mai meno della maturity ordinaria dovuta dopo la finestra.
    final toCommonRelease = epochRelease - coinbaseHeight + 1;
    if (coinbaseHeight < epochStart) {
      return consensusMaturityBlocks;
    }
    return toCommonRelease > consensusMaturityBlocks
        ? toCommonRelease
        : consensusMaturityBlocks;
  }

  /// Altezza minima del blocco di SPESA accettato dalla rete per una coinbase
  /// generata a [coinbaseHeight].
  int unlockHeight(int coinbaseHeight) =>
      coinbaseHeight + requiredDepth(coinbaseHeight);
}
