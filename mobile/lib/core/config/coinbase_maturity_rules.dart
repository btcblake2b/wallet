/// Regole di maturity di un output coinbase per una rete.
///
/// PERCHÉ: dal blocco 979.919 la mainnet blake2b non applica più una sola
/// regola. Il consenso (Knots `v29.4.3`, `src/consensus/tx_verify.cpp`) decide
/// la profondità richiesta **dall'altezza della coinbase**, non dall'altezza
/// della spesa:
///
/// ```cpp
/// const int actual_maturity{nSpendHeight - (int)coin.nHeight};
/// const int required_maturity{coin.nHeight >= long_maturity_end_height ? COINBASE_MATURITY :
///     (coin.nHeight >= long_maturity_start_height ? coinbase_maturity_long : coinbase_maturity_before_start)};
/// ```
///
/// Quindi ogni payout ha il **proprio** conto alla rovescia che parte dal
/// blocco in cui è stato minato — non uno sblocco comune:
///
/// - **< 973.440**: 100 blocchi (consenso ordinario);
/// - **973.440 – 979.918** (epoca 45 giorni): 6.480 blocchi dal proprio blocco
///   (`CoinbaseMaturityBeforeRolling() = release − start`);
/// - **≥ 979.919**: 25.920 blocchi (~180 giorni) dal proprio blocco, fino
///   all'expiry RDTS.
///
/// ⚠️ Verificato l'08/11/2026 sul nodo reale (tip 981.146): una coinbase di
/// h=979877 con 1.270 conferme viene rifiutata con
/// `bad-txns-premature-spend-of-coinbase`; il wallet del nodo tiene immature le
/// 60 coinbase dell'epoca (35,5638758 BTC), la più vecchia a 6.406 conferme
/// (h=974741 → sblocco a 981.221 = h + 6.480).
class CoinbaseMaturityRules {
  const CoinbaseMaturityRules({
    required this.epochs,
    required this.defaultMaturityBlocks,
    this.rdtsExpiryUnixTime,
    this.rdtsExpiryNote,
  });

  /// Epoche ordinate dalla più vecchia: la prima che copre l'altezza vince.
  final List<CoinbaseMaturityEpoch> epochs;

  /// Profondità fuori da ogni epoca (100 = consenso ordinario, oggi).
  final int defaultMaturityBlocks;

  /// Timestamp (UTC) dell'expiry RDTS. Dopo quell'istante il consenso torna a
  /// 100 blocchi per le coinbase minate **dopo** l'expiry: allora si aggiornano
  /// i parametri di rete, non la logica.
  final int? rdtsExpiryUnixTime;

  /// Nota leggibile sull'expiry (documentazione, non usata dal calcolo).
  final String? rdtsExpiryNote;

  /// Blocchi di attesa dovuti da una coinbase generata a [coinbaseHeight].
  int requiredDepth(int coinbaseHeight) {
    for (final epoch in epochs) {
      if (epoch.covers(coinbaseHeight)) return epoch.maturityBlocks;
    }
    return defaultMaturityBlocks;
  }

  /// Altezza del primo blocco che può SPENDERE quella coinbase.
  ///
  /// Il consenso richiede `spendHeight − coinHeight ≥ required`: con la
  /// convenzione del wallet (`conferme = tip − height + 1`) equivale a
  /// `conferme ≥ required`, perché la spesa entra nel blocco `tip + 1`.
  int unlockHeight(int coinbaseHeight) =>
      coinbaseHeight + requiredDepth(coinbaseHeight);

  /// La profondità più restrittiva in vigore: usata quando l'altezza della
  /// coinbase è ignota (non si può datare, quindi non si può scegliere l'epoca).
  int get strictestMaturityBlocks =>
      epochs.fold<int>(defaultMaturityBlocks, (max, e) {
        return e.maturityBlocks > max ? e.maturityBlocks : max;
      });
}

/// Intervallo di altezze con una propria profondità di maturity.
class CoinbaseMaturityEpoch {
  const CoinbaseMaturityEpoch({
    required this.fromHeight,
    this.toHeight,
    required this.maturityBlocks,
  });

  final int fromHeight;

  /// Ultima altezza coperta; `null` = epoca aperta (fino all'expiry RDTS).
  final int? toHeight;

  final int maturityBlocks;

  bool covers(int height) =>
      height >= fromHeight && (toHeight == null || height <= toHeight!);
}
