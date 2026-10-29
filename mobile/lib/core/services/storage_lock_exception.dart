/// Errore sollevato quando il vault chiavi è protetto da password e la chiave
/// non è in memoria (prima dello sblocco o dopo l'auto-lock).
///
/// PERCHÉ: vive in un file neutro (non `dart:html`) perché anche la UI deve
/// poterlo distinguere — "vault bloccato" è uno stato normale, non un errore di
/// lettura dei wallet. Su native non viene mai sollevato.
class StorageLockedException implements Exception {
  StorageLockedException(this.message);

  final String message;

  @override
  String toString() => 'StorageLockedException: $message';
}
