/// Feature flag di compilazione (`--dart-define`).
///
/// // PERCHÉ (ADR 30/10-7 §2): il kill switch deve poter spegnere una feature
/// // senza toccare il codice persistito. Essendo compile-time, un rollback è
/// // una nuova build con il define a `false` — compatibile con la
/// // distribuzione diretta (APK firmata su GitHub Releases/Zapstore).
///
/// // PERCHÉ default `false` per la rotazione: attivarla senza il flusso di
/// // adozione in UI farebbe incontrare `needsAdoption` agli utenti esistenti.
/// // La release che include il flusso di ricezione la compila con
/// // `--dart-define=WALLET_INDEX_ROTATION=true`.
class FeatureFlags {
  const FeatureFlags({required this.walletIndexRotation});

  /// Valori usati dalla build corrente.
  static const FeatureFlags current = FeatureFlags(
    walletIndexRotation: bool.fromEnvironment('WALLET_INDEX_ROTATION'),
  );

  /// Rotazione degli indirizzi di ricezione (`nextReceiveIndex` + gap-scan).
  ///
  /// // Lo stato del record **vince** sempre su questo flag: `corrupt` e
  /// // `anomalous` restano fail-closed anche con la rotazione spenta
  /// // (ADR 30/10-7 §2).
  final bool walletIndexRotation;
}
