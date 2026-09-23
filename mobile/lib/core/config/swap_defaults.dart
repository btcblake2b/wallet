/// Provider swap predefinito (P9): nodo terzo noto, così una installazione
/// nuova può fare uno swap senza che l'utente debba procurarsi una URI.
///
/// // PERCHÉ: la URI non contiene segreti (pubkey del provider + relay) e senza
/// // un default l'utente non tecnico non ha modo di sapere dove trovarla.
///
/// ⚠️ Il default viene mostrato SOLO se il provider risponde alla sonda di
/// disponibilità (`SwapService.probeProvider`): un suggerimento morto è peggio
/// di nessun suggerimento. Se non risponde, resta nascosto.
/// ⚠️ Cambiare [providerUri] = cambiare il provider suggerito a TUTTE le
/// installazioni: è una scelta di prodotto, non un dettaglio tecnico.
abstract final class SwapDefaults {
  /// URI del provider swap suggerito (`nostr+swap://<pubkey>?v=…&relay=…`).
  static const String providerUri =
      'nostr+swap://91d1fca1a250bfd426b3276fa1a40018d4a0bf3fb46b8e748c5892066d18b296'
      '?v=1&network=blake2b&relay=wss%3A%2F%2Frelay.primal.net';

  /// [saved] (URI già note all'utente) + [providerUri] in coda, senza duplicati.
  ///
  /// // PERCHÉ: il default è un suggerimento, non una preferenza — le URI
  /// // dell'utente restano in testa all'elenco.
  static List<String> withDefault(List<String> saved) => saved.contains(
        providerUri,
      )
          ? List<String>.of(saved)
          : [...saved, providerUri];
}
