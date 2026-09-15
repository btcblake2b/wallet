/// Connessione a un nodo Lightning remoto via NIP-47 (Nostr Wallet Connect).
///
/// La URI ha formato:
/// `nostr+walletconnect://<wallet_pubkey>?relay=<wss://…>&secret=<hex64>[&lud16=…]`
///
/// ⚠️ [secretHex] è un SEGRETO (chiave privata di sessione del client):
/// va salvato solo in secure storage e MAI loggato.
class LightningConnection {
  const LightningConnection({
    required this.walletPubkey,
    required this.relays,
    required this.secretHex,
    this.lud16,
  });

  /// Pubkey x-only del nodo (hex 64) — destinatario delle richieste.
  final String walletPubkey;

  /// Relay Nostr su cui parlare col nodo (almeno 1).
  final List<String> relays;

  /// Chiave privata client (hex 64) — firma e cifra le richieste.
  final String secretHex;

  /// Lightning Address opzionale del nodo.
  final String? lud16;

  static final RegExp _hex64 = RegExp(r'^[0-9a-fA-F]{64}$');

  /// Parsa e valida una stringa di connessione. Lancia [FormatException]
  /// con un messaggio chiaro se malformata.
  static LightningConnection fromUri(String uri) {
    final parsed = Uri.tryParse(uri.trim());
    if (parsed == null || parsed.scheme != 'nostr+walletconnect') {
      throw const FormatException(
        'URI non valida: atteso schema nostr+walletconnect://',
      );
    }
    // PERCHÉ: nella URI NIP-47 la pubkey del nodo è l'"authority" (host).
    final walletPubkey = parsed.host.toLowerCase();
    if (!_hex64.hasMatch(walletPubkey)) {
      throw const FormatException(
        'wallet pubkey mancante o non valida (attesi 64 char hex)',
      );
    }
    final relays = (parsed.queryParametersAll['relay'] ?? const <String>[])
        .where((r) => r.startsWith('wss://') || r.startsWith('ws://'))
        .toList();
    if (relays.isEmpty) {
      throw const FormatException('nessun relay wss:// nella URI');
    }
    final secret = (parsed.queryParameters['secret'] ?? '').toLowerCase();
    if (!_hex64.hasMatch(secret)) {
      throw const FormatException(
        'secret mancante o non valido (attesi 64 char hex)',
      );
    }
    final lud16 = parsed.queryParameters['lud16'];
    return LightningConnection(
      walletPubkey: walletPubkey,
      relays: relays,
      secretHex: secret,
      lud16: (lud16 == null || lud16.isEmpty) ? null : lud16,
    );
  }

  /// Ricostruisce la URI (usata per la persistenza in secure storage).
  String toUri() {
    return Uri(
      scheme: 'nostr+walletconnect',
      host: walletPubkey,
      queryParameters: <String, dynamic>{
        'relay': relays,
        'secret': secretHex,
        if (lud16 != null) 'lud16': lud16,
      },
    ).toString();
  }

  /// // PERCHÉ: mai includere [secretHex] nei log/toString.
  @override
  String toString() =>
      'LightningConnection(wallet: $walletPubkey, relays: $relays)';
}
