import 'package:flutter/foundation.dart';

/// Relay Nostr consentiti sulla variante web/PWA (allowlist della CSP).
///
/// // PERCHÉ (2026-09-18): sulla PWA la CSP è STRETTA e `connect-src` enumera
/// // gli host consentiti (`mobile/web/_headers`). Un `wss:` generico aprirebbe
/// // un canale verso qualunque host — utile a un XSS attivo per esfiltrare —
/// // quindi si usa un'allowlist esplicita, coerente con l'hardening 2.4.
///
/// ⚠️ MANUTENZIONE: questa lista DEVE restare allineata alla direttiva
/// `connect-src` di `mobile/web/_headers`. Un provider su un relay nuovo
/// richiede ENTRAMBE le modifiche (CSP servita da Pages + questo file), oppure
/// l'utente su web non può collegarlo (errore `RELAY_NOT_ALLOWED_WEB`).
const Set<String> kWebAllowedSwapRelays = <String>{
  'wss://relay.primal.net',
};

/// Normalizza un URL relay per il confronto: minuscolo, senza spazi e senza
/// slash finali (`wss://relay.primal.net/` == `wss://relay.primal.net`).
///
/// // PERCHÉ: la URI del provider è scritta dall'utente/fornitore — differenze
/// // di maiuscole o di slash finale non devono cambiare l'esito della verifica.
String normalizeRelayUrl(String relayUrl) =>
    relayUrl.trim().toLowerCase().replaceAll(RegExp(r'/+$'), '');

/// True se [relayUrl] è nella allowlist della variante web.
bool isRelayInWebAllowlist(String relayUrl) =>
    kWebAllowedSwapRelays.contains(normalizeRelayUrl(relayUrl));

/// Relay effettivamente tentabili sulla piattaforma corrente.
///
/// // PERCHÉ: su web un relay fuori allowlist fallirebbe per CSP con un errore
/// // di rete poco comprensibile; filtrarlo PRIMA evita tentativi inutili e
/// // consente un messaggio chiaro quando nessun relay resta utilizzabile.
/// Fuori dal web la lista è restituita invariata (la CSP non esiste).
///
/// [useWebPolicy] è iniettabile perché `kIsWeb` è una costante di compilazione
/// e nei test vale sempre `false` (stesso motivo dei seam `*.test(...)` già
/// presenti nel progetto): il default resta il comportamento reale.
List<String> filterRelaysForPlatform(
  List<String> relays, {
  bool useWebPolicy = kIsWeb,
}) {
  if (!useWebPolicy) return List<String>.unmodifiable(relays);
  return List<String>.unmodifiable(relays.where(isRelayInWebAllowlist));
}
