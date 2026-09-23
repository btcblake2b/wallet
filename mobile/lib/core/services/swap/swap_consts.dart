/// Costanti del protocollo swap (app ↔ provider) — feature P9.
///
/// // PERCHÉ: i kind Nostr, lo schema URI e i prefissi DEVONO essere identici
/// // sui due lati: qui la copia APP, in `bridge/lib/src/swap/swap_consts.dart`
/// // la copia provider. Ogni modifica va replicata su ENTRAMBE.
///
/// Wire format (il "contratto" che `swapd` lato provider implementa):
///
/// ```text
/// Richiesta (kind 23290, NIP-04, tag p = provider):
///   {"v":1,"id":"<request_id hex32>","method":"swap_quote","params":{…}}
/// Risposta  (kind 23291, NIP-04 verso il client, tag e = id evento richiesta):
///   {"v":1,"id":"<request_id>","result":{…}}
///   {"v":1,"id":"<request_id>","error":{"code":"…","message":"…"}}
/// Notifica  (kind 23292, NIP-04 verso il client, id = swap_id):
///   {"v":1,"id":"<swap_id>","result":{…campo "result" di swap_status…}}
/// ```
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

  /// Schema dell'URI provider: `nostr+swap://<pubkey>?v=1&network=blake2b&relay=…`.
  static const String uriScheme = 'nostr+swap';

  /// Prefisso del blob di recupero: `swaprecover1.<base64url(json)>`.
  static const String recoveryPrefix = 'swaprecover1.';

  /// Identificativo della rete nel protocollo (single-chain: blake2b).
  static const String network = 'blake2b';

  /// Account dedicato per le chiavi di refund nello swap.
  ///
  /// // PERCHÉ (piano v2): `m/84'/coin'/2'/0/x` separa le chiavi dello swap
  /// // dall'account principale (0') — un indice x per sessione evita ogni
  /// // riuso di chiave fra swap diversi.
  static const int refundAccount = 2;

  /// Chain esterna dell'account refund (ricezione).
  static const int refundChain = 0;
}
