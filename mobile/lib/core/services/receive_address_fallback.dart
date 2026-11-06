/// Scelta dell'indirizzo di ricezione **senza** indici persistiti.
///
/// // PERCHÉ esiste come funzione pura (ADR 01/11-25 §2): è la regola che
/// // governa il comportamento con la rotazione **spenta** in Ric ei, e prima
/// // era implicita dentro la schermata. Con la rotazione spenta il flag deve
/// // riportare il comportamento *precedente* ad A2, che è «il primo `/0/N` non
/// // ancora usato» — non `publicAddress`: chi ha già ricevuto su `/0/0` deve
/// // continuare a ottenere il successivo indirizzo libero, altrimenti il
/// // rollback reintrodurrebbe il riuso.
///
/// Restituisce [fallback] solo se nessun indirizzo derivato è libero.
String firstUnusedReceiveAddress({
  required Set<String> used,
  required List<String> derived,
  required String fallback,
}) {
  if (used.isEmpty) return fallback;
  for (final address in derived) {
    if (!used.contains(address)) return address;
  }
  return fallback;
}
