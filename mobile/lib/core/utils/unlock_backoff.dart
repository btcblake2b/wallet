/// Ritardo di backoff per i tentativi di sblocco del vault web falliti.
///
/// PERCHÉ (hardening 2.4): PBKDF2-SHA256 600k rallenta già ogni tentativo, ma
/// nulla impediva a uno script di tentarne molti in serie (anche tra reload).
/// Un backoff crescente e PERSISTITO in localStorage alza il costo di un
/// attacco dizionario senza introdurre una UI di lockout dedicata.
///
/// ⚠️ Limite dichiarato: chi può cancellare localStorage azzera il contatore —
/// è un attrito, non un muro. La difesa vera resta la password ad alta entropia.
///
/// Mappa: 0-2 tentativi → nessun ritardo (errori di battitura); poi 1, 2, 4, 8
/// secondi (cap 8 s).
Duration unlockBackoffDelay(int failedAttempts) {
  if (failedAttempts <= 2) return Duration.zero;
  const seconds = [1, 2, 4, 8];
  final index = (failedAttempts - 3).clamp(0, seconds.length - 1);
  return Duration(seconds: seconds[index]);
}
