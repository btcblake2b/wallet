import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:nwc_cln_bridge/src/nostr/nostr_crypto.dart';
import 'package:nwc_cln_bridge/src/nostr/nostr_event.dart';
import 'package:nwc_cln_bridge/src/nostr/websocket_transport.dart';
import 'package:nwc_cln_bridge/src/swap/swap_consts.dart';

/// Sonda del provider swap (P9): parla il protocollo VERO dell'app
/// (kind 23290-23292, NIP-04) contro un provider `swapd`.
///
/// Uso:
///   dart run bin/swapprobe.dart --uri-file=swap-uri.txt --invoice=lnbc…
///   dart run bin/swapprobe.dart --uri=nostr+swap://… --invoice=lnbc… \
///       [--refund-pubkey=02…] [--keep-open]
///
/// Senza `--invoice` esegue solo un giro di validazione (metodo inesistente):
/// utile per verificare che il daemon risponda sul relay.
Future<void> main(List<String> args) async {
  final opts = _parseArgs(args);
  var uri = opts['uri'] ?? '';
  final uriFile = opts['uri-file'];
  if (uri.isEmpty && uriFile != null) {
    uri = File(uriFile).readAsStringSync().trim();
  }
  if (uri.isEmpty) {
    stderr.writeln('Uso: --uri-file=swap-uri.txt (oppure --uri=nostr+swap://…)');
    exit(1);
  }
  final parsed = Uri.parse(uri);
  final providerPub = parsed.host.toLowerCase();
  final relays = parsed.queryParametersAll['relay'] ?? const <String>[];
  if (providerPub.length != 64 || relays.isEmpty) {
    stderr.writeln('URI provider non valida');
    exit(1);
  }
  final invoice = opts['invoice'] ?? '';
  final refundPubkey = opts['refund-pubkey'] ?? '02${'22' * 32}';

  // Chiave client EFFIMERA (come l'app, ma usa-e-getta per la sonda).
  final clientPriv = NostrCrypto.randomHex32();
  final clientPub = NostrCrypto.derivePublicKey(clientPriv);

  final transport = WebSocketTransport();
  Object? lastError;
  var connected = false;
  for (final relay in relays) {
    try {
      await transport.connect(relay);
      connected = true;
      stdout.writeln('[probe] relay: $relay');
      break;
    } catch (e) {
      lastError = e;
    }
  }
  if (!connected) {
    stderr.writeln('[probe] nessun relay raggiungibile: $lastError');
    exit(1);
  }

  final pending = <String, Completer<Map<String, dynamic>>>{};
  transport.subscribe([
    {
      'kinds': [SwapConsts.responseKind, SwapConsts.notificationKind],
      '#p': [clientPub],
    },
  ]).listen((event) {
    if (event.pubkey != providerPub || !event.verify()) return;
    String plain;
    try {
      plain = NostrCrypto.nip04Decrypt(
        privkeyHex: clientPriv,
        pubkeyHex: providerPub,
        payload: event.content,
      );
    } catch (_) {
      return;
    }
    final body = (jsonDecode(plain) as Map).cast<String, dynamic>();
    if (event.kind == SwapConsts.notificationKind) {
      stdout.writeln('[probe] NOTIFICA: ${jsonEncode(body['result'] ?? body)}');
      return;
    }
    final requestEventId = event.firstTagValue('e');
    final completer =
        requestEventId == null ? null : pending.remove(requestEventId);
    if (completer == null || completer.isCompleted) return;
    completer.complete(body);
  });

  Future<Map<String, dynamic>> request(
    String method,
    Map<String, dynamic> params,
  ) async {
    final requestId = NostrCrypto.randomHex32();
    final payload = jsonEncode({
      'v': SwapConsts.protocolVersion,
      'id': requestId,
      'method': method,
      'params': params,
    });
    final encrypted = NostrCrypto.nip04Encrypt(
      privkeyHex: clientPriv,
      pubkeyHex: providerPub,
      plaintext: payload,
    );
    final event = NostrEvent.unsigned(
      pubkey: clientPub,
      kind: SwapConsts.requestKind,
      tags: [
        ['p', providerPub],
      ],
      content: encrypted,
    ).sign(clientPriv);
    final completer = Completer<Map<String, dynamic>>();
    pending[event.id] = completer;
    await transport.publish(event);
    return completer.future.timeout(const Duration(seconds: 30));
  }

  if (invoice.isEmpty) {
    stdout.writeln('[probe] nessuna invoice: verifico solo la raggiungibilità…');
    final res = await request('swap_status', {'swap_id': 'probe'});
    stdout.writeln('[probe] swap_status → ${jsonEncode(res)}');
    await transport.close();
    return;
  }

  stdout.writeln('[probe] swap_quote…');
  final quote = await request('swap_quote', {
    'invoice': invoice,
    'refund_pubkey': refundPubkey,
  });
  stdout.writeln('[probe] swap_quote → ${jsonEncode(quote)}');
  final quoteResult = quote['result'];
  if (quoteResult is Map) {
    stdout.writeln('[probe] swap_create…');
    final created = await request('swap_create', {
      'quote_id': '${quoteResult['quote_id']}',
    });
    stdout.writeln('[probe] swap_create → ${jsonEncode(created)}');
    final createdResult = created['result'];
    if (createdResult is Map) {
      final swapId = '${createdResult['swap_id']}';
      stdout.writeln('[probe] swap_status…');
      final status = await request('swap_status', {'swap_id': swapId});
      stdout.writeln('[probe] swap_status → ${jsonEncode(status)}');
      stdout.writeln(
        '[probe] ATTENZIONE: sessione $swapId creata in awaitingFunding — '
        'senza funding scade da sola (nessun fondo in gioco).',
      );
    }
  }

  if (opts.containsKey('keep-open')) {
    stdout.writeln('[probe] --keep-open: in ascolto delle notifiche…');
    await Completer<void>().future;
  }
  await transport.close();
  stdout.writeln('[probe] PROBE_DONE');
}

Map<String, String> _parseArgs(List<String> args) {
  final out = <String, String>{};
  for (final a in args) {
    if (!a.startsWith('--')) {
      continue;
    }
    final eq = a.indexOf('=');
    if (eq < 0) {
      out[a.substring(2)] = '';
    } else {
      out[a.substring(2, eq)] = a.substring(eq + 1);
    }
  }
  return out;
}
