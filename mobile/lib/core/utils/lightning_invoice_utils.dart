/// Prefissi BOLT11 accettati: mainnet `lnbc`, testnet `lntb`, regtest
/// `lnbcrt` (già coperto da `lnbc`), signet/simnet `lnsb`.
const List<String> _bolt11Prefixes = ['lnbc', 'lntb', 'lnsb'];

/// Rimuove spazi e l'eventuale prefisso URI `lightning:` (BIP21-like).
String normalizeLightningInvoice(String raw) {
  var value = raw.trim();
  if (value.toLowerCase().startsWith('lightning:')) {
    value = value.substring('lightning:'.length).trim();
  }
  return value;
}

/// True se [raw] ha la forma di un invoice BOLT11 (`lnbc…`).
///
/// // PERCHÉ: è un controllo di forma (prefisso + lunghezza minima), non di
/// checksum: distingue un QR invoice da uno estraneo (indirizzo on-chain,
/// lnurl, testo) durante la scansione. La validità crittografica la verifica
/// il nodo al pagamento.
bool isValidLightningInvoice(String raw) {
  final value = normalizeLightningInvoice(raw).toLowerCase();
  // Le invoice reali sono lunghe centinaia di caratteri: sotto questa
  // soglia è quasi certamente altro testo.
  if (value.length < 20) return false;
  return _bolt11Prefixes.any((prefix) => value.startsWith(prefix));
}
