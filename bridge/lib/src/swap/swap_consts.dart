/// Costanti del protocollo swap (provider ↔ app).
///
/// PERCHÉ (P9): i kind Nostr e i prefissi DEVONO essere identici sui due lati
/// (provider bridge e app): qui la copia server, in
/// `mobile/lib/core/services/swap/swap_consts.dart` la copia app.
///
/// ⚠️ Prima del deploy verificare che 23290-23292 non confliggano con kind
/// registrati (NIP-47 usa 23194/23195, NNC 23198-23200): in caso di conflitto
/// slittare l'intero blocco e aggiornare ENTRAMBE le copie.
abstract final class SwapConsts {
  /// Versione del protocollo (campo `v` nei payload JSON).
  static const int protocolVersion = 1;

  /// Kind Nostr della richiesta (app → provider), cifrata NIP-04.
  static const int requestKind = 23290;

  /// Kind Nostr della risposta (provider → app), cifrata NIP-04.
  static const int responseKind = 23291;

  /// Kind Nostr della notifica di stato (provider → app), cifrata NIP-04.
  static const int notificationKind = 23292;

  /// Schema dell'URI provider: `nostr+swap://<pubkey>?v=1&relay=…`.
  static const String uriScheme = 'nostr+swap';

  /// Prefisso del blob di recupero: `swaprecover1.<base64url(json)>`.
  static const String recoveryPrefix = 'swaprecover1.';

  /// Identificativo della rete nel protocollo (single-chain: blake2b).
  static const String network = 'blake2b';
}
