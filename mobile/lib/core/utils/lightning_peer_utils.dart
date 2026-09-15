/// Parsing della stringa di connessione di un peer Lightning.
///
/// // PERCHÉ: dagli explorer e dalle chat si copia spesso la forma compatta
/// `pubkey@host:port` in un blocco unico: qui la separiamo nei due campi che
/// il protocollo NCC usa (`pubkey` e `host`).
({String nodeId, String? host}) parseNodeConnectionString(String raw) {
  final value = raw.trim();
  if (value.isEmpty) {
    return (nodeId: '', host: null);
  }
  final at = value.indexOf('@');
  if (at < 0) {
    return (nodeId: value.toLowerCase(), host: null);
  }
  final nodeId = value.substring(0, at).trim().toLowerCase();
  final host = value.substring(at + 1).trim();
  return (nodeId: nodeId, host: host.isEmpty ? null : host);
}

/// True se [nodeId] è una pubkey Lightning valida (33 byte compressi in hex).
bool isValidLightningNodeId(String nodeId) =>
    RegExp(r'^[0-9a-f]{66}$').hasMatch(nodeId.trim().toLowerCase());

/// True se [host] è nella forma `host:porta` (accetta anche indirizzi `.onion`,
/// raggiungibili solo da un nodo con proxy Tor configurato).
bool isValidPeerHost(String host) {
  final value = host.trim();
  if (value.isEmpty) return false;
  final colon = value.lastIndexOf(':');
  if (colon <= 0 || colon == value.length - 1) return false;
  final port = int.tryParse(value.substring(colon + 1));
  return port != null && port > 0 && port <= 65535;
}
