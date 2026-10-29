import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../logger.dart';
import '../protocol.dart';

/// Client dell'API pubblica di un bridge cross-chain (kilobridge / Lightning
/// Fork `bridgerpc`).
///
/// // PERCHÉ (P9): il nostro wallet deve poter pagare una fattura della chain
/// // SHA-256 partendo dai fondi della chain BLAKE2b. Il bridge non è
/// // custodial: risponde con una **hold invoice sulla nostra chain con lo
/// // stesso payment hash**; noi la paghiamo, il bridge incassa solo
/// // presentando la preimage (cioè dopo aver pagato la fattura SHA-256).
/// // Se non riesce, la hold invoice scade e i fondi tornano da soli.
///
/// Contratto HTTP verificato sul sorgente pubblico di kilobridge
/// (`web/server.js`, 19/10/2026):
/// - `GET  /api/pow` → `{challenge}`
/// - `POST /api/check {invoice}` → `{sat, estimate_sat, rate, spread, wait_s, hash}`
/// - `POST /api/quote {invoice, pow:{challenge, nonce}}` →
///   `{hold_invoice, hash, sat, pay_sat, rate, spread, expires_at, node, cltv, token}`
/// - `GET  /api/swap/<hash>?t=<token>` → `{state, preimage}`
class KilobridgeClient {
  KilobridgeClient({
    required this.baseUrl,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 20),
    Logger? logger,
  })  : _http = httpClient ?? http.Client(),
        _logger = logger ?? Logger();

  /// URL del servizio (es. `https://bridge.kilombino.com`).
  final String baseUrl;
  final Duration timeout;
  final http.Client _http;
  final Logger _logger;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  /// Cosa costa pagare [invoice] (nessuna prenotazione, sola lettura).
  Future<Map<String, dynamic>> check(String invoice) =>
      _post('/api/check', {'invoice': invoice});

  /// Chiede una hold invoice da pagare sulla nostra chain.
  ///
  /// // PERCHÉ (PoW): il servizio pretende un piccolo proof-of-work per ogni
  /// // quote (anti-abuso): si prende una challenge e si cerca un nonce tale
  /// // che `SHA-256("<challenge>:<payment hash>:<nonce>")` inizi con `bits`
  /// // bit a zero — la stessa cosa che fa la pagina web (~1 s).
  Future<Map<String, dynamic>> quote(String invoice) async {
    final challenge = await _getPowChallenge();
    final hash = paymentHashFromInvoice(invoice);
    final nonce =
        hash == null ? null : solvePow(challenge: challenge, hash: hash);
    return _post('/api/quote', {
      'invoice': invoice,
      if (nonce != null) 'pow': {'challenge': challenge, 'nonce': nonce},
    });
  }

  /// Stato dello swap (`settled`, `failed`, `aborted`, `expired`, `lost`, …).
  ///
  /// // PERCHÉ: la preimage torna solo a chi possiede il `token` del quote —
  /// // è la prova del pagamento, ed è ciò che restituiamo all'app.
  Future<Map<String, dynamic>> swap({
    required String paymentHash,
    required String token,
  }) =>
      _get('/api/swap/$paymentHash', {'t': token});

  // ── internals ─────────────────────────────────────────────────────────────

  Future<String> _getPowChallenge() async {
    final body = await _get('/api/pow');
    final challenge = '${body['challenge'] ?? ''}';
    if (challenge.isEmpty) {
      throw const RpcError('OTHER', 'bridge: challenge proof-of-work assente');
    }
    return challenge;
  }

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, String>? query,
  ]) async {
    final http.Response res;
    try {
      res = await _http.get(_uri(path, query)).timeout(timeout);
    } on TimeoutException {
      throw const RpcError('OTHER', 'bridge: timeout');
    } catch (e) {
      throw RpcError('OTHER', 'bridge non raggiungibile: $e');
    }
    return _decode(res, path);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final http.Response res;
    try {
      res = await _http
          .post(
            _uri(path),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const RpcError('OTHER', 'bridge: timeout');
    } catch (e) {
      throw RpcError('OTHER', 'bridge non raggiungibile: $e');
    }
    return _decode(res, path);
  }

  /// // PERCHÉ: il servizio usa 4xx con `{error}` per i rifiuti (troppo
  /// // piccolo, limite, PoW scaduto): il messaggio deve arrivare all'utente
  /// // così com'è, non travestito da errore interno.
  Map<String, dynamic> _decode(http.Response res, String path) {
    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map) body = decoded.cast<String, dynamic>();
    } catch (_) {
      body = null;
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (body == null) {
        throw RpcError('OTHER', 'bridge: risposta non JSON su $path');
      }
      return body;
    }
    final error = '${body?['error'] ?? 'http ${res.statusCode}'}';
    _logger.warn('bridge cross-chain: $path → $error');
    throw RpcError(_errorCode(error), error);
  }

  static String _errorCode(String error) {
    switch (error) {
      case 'invalid_request':
      case 'too_small':
      case 'too_large':
        return 'BAD_REQUEST';
      case 'limit':
        return 'RESTRICTED';
      case 'unavailable':
        return 'OTHER';
      default:
        return 'PAYMENT_FAILED';
    }
  }

  /// Payment hash (hex) da una fattura BOLT11, o null se non decodificabile.
  ///
  /// // PERCHÉ: il PoW lega challenge e **payment hash**; senza hash il
  /// // servizio rifiuta il quote. Il hash è il campo taggato `p`, che può
  /// // stare in qualsiasi posizione dopo il timestamp: va letto scorrendo i
  /// // campi, non a offset fisso.
  static String? paymentHashFromInvoice(String invoice) {
    var s = invoice.trim().toLowerCase();
    if (s.startsWith('lightning:')) s = s.substring('lightning:'.length);
    final sep = s.lastIndexOf('1');
    if (sep < 3) return null;
    final data = _toWords(s.substring(sep + 1));
    if (data == null || data.length < 7 + 3 + 52 + 104) return null;
    // Formato: timestamp (7 word) + campi taggati + firma (104 word).
    var i = 7;
    final end = data.length - 104;
    while (i + 3 <= end) {
      final tag = data[i];
      final len = (data[i + 1] << 5) | data[i + 2];
      final start = i + 3;
      if (start + len > end) return null;
      if (tag == 1) {
        // `p` = payment hash: 52 word da 5 bit = 260 bit → 32 byte.
        return _wordsToHex(data.sublist(start, start + len));
      }
      i = start + len;
    }
    return null;
  }

  static const String _charset = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';

  /// Caratteri bech32 → word da 5 bit (null se un carattere non è valido).
  static List<int>? _toWords(String payload) {
    final out = <int>[];
    for (final ch in payload.split('')) {
      final v = _charset.indexOf(ch);
      if (v < 0) return null;
      out.add(v);
    }
    return out;
  }

  /// Word da 5 bit → hex dei byte interi contenuti (32 byte = 256 bit).
  static String _wordsToHex(List<int> words) {
    final bits = <int>[];
    for (final w in words) {
      for (var i = 4; i >= 0; i--) {
        bits.add((w >> i) & 1);
      }
    }
    final out = StringBuffer();
    for (var i = 0; i + 8 <= 256 && i + 8 <= bits.length; i += 8) {
      var byte = 0;
      for (var j = 0; j < 8; j++) {
        byte = (byte << 1) | bits[i + j];
      }
      out.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return out.toString();
  }

  /// Cerca un nonce (`[0-9a-z]{1,32}`) che soddisfi il proof-of-work.
  ///
  /// // PERCHÉ: se non si trova entro [maxIterations] si restituisce null → il
  /// // quote parte senza PoW. Il servizio lo rifiuta solo da clearnet: meglio
  /// // un errore chiaro che bloccare la richiesta per minuti.
  static String? solvePow({
    required String challenge,
    required String hash,
    int maxIterations = 4000000,
  }) {
    final bits = requiredBits(challenge);
    for (var i = 0; i < maxIterations; i++) {
      final nonce = i.toRadixString(36);
      if (nonce.length > 32) break;
      final digest = sha256.convert(utf8.encode('$challenge:$hash:$nonce'));
      if (leadingZeroBits(digest.bytes) >= bits) return nonce;
    }
    return null;
  }

  /// Bit a zero richiesti, letti dalla challenge (`1.<ts>.<bits>.<mac>`).
  static int requiredBits(String challenge) {
    final parts = challenge.split('.');
    if (parts.length < 4) return 18;
    return int.tryParse(parts[2]) ?? 18;
  }

  /// Bit a zero iniziali del digest.
  static int leadingZeroBits(List<int> digest) {
    var bits = 0;
    for (final byte in digest) {
      if (byte == 0) {
        bits += 8;
        continue;
      }
      var b = byte;
      while ((b & 0x80) == 0) {
        bits++;
        b = (b << 1) & 0xff;
      }
      break;
    }
    return bits;
  }
}
