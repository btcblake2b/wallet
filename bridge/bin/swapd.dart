import 'dart:async';
import 'dart:io';

import 'package:nwc_cln_bridge/src/cln/cln_api.dart';
import 'package:nwc_cln_bridge/src/cln/cln_cli.dart';
import 'package:nwc_cln_bridge/src/logger.dart';
import 'package:nwc_cln_bridge/src/nostr/nostr_crypto.dart';
import 'package:nwc_cln_bridge/src/nostr/websocket_transport.dart';
import 'package:nwc_cln_bridge/src/swap/chain_api.dart';
import 'package:nwc_cln_bridge/src/swap/swap_config.dart';
import 'package:nwc_cln_bridge/src/swap/swap_consts.dart';
import 'package:nwc_cln_bridge/src/swap/swap_daemon.dart';
import 'package:nwc_cln_bridge/src/swap/swap_handlers.dart';
import 'package:nwc_cln_bridge/src/swap/swap_service.dart';
import 'package:nwc_cln_bridge/src/swap/swap_signer.dart';
import 'package:nwc_cln_bridge/src/swap/swap_store.dart';

/// Entrypoint del provider swap (P9): `swapd`.
///
/// Uso:
///   dart run bin/swapd.dart --genkey [--key-file=provider.key]
///       → genera la chiave di CLAIM del provider (hex 64, permessi 600):
///         è la chiave che firma i claim degli HTLC — mai nel repo.
///   dart run bin/swapd.dart --genuri [--config=swap-config.json]
///       → stampa la URI per l'app (`nostr+swap://…`) e la salva in
///         swap-uri.txt (permessi 600)
///   dart run bin/swapd.dart [--config=swap-config.json]
///       → avvia il daemon (ascolta il relay, tick di riconciliazione)
Future<void> main(List<String> args) async {
  final opts = _parseArgs(args);
  final configPath = opts['config'] ?? 'swap-config.json';

  if (opts.containsKey('genkey')) {
    final keyPath = opts['key-file'] ?? 'provider.key';
    final key = NostrCrypto.randomHex32();
    await _writePrivate(File(keyPath), key);
    stdout.writeln('chiave provider scritta: $keyPath (permessi 600)');
    stdout.writeln('pubkey provider: ${NostrCrypto.derivePublicKey(key)}');
    return;
  }

  SwapConfig config;
  try {
    config = SwapConfig.fromJsonFile(configPath);
  } on FormatException catch (e) {
    stderr.writeln('CONFIG NON VALIDA: ${e.message}');
    exit(78); // sysexits.h EX_CONFIG
  }

  final String providerKeyHex;
  try {
    providerKeyHex = config.loadProviderKeyHex();
  } on FormatException catch (e) {
    stderr.writeln('CHIAVE PROVIDER NON LEGGIBILE: ${e.message}');
    exit(78);
  }

  if (opts.containsKey('genuri')) {
    final uri = _buildUri(
      providerPubkey: NostrCrypto.derivePublicKey(providerKeyHex),
      relays: config.relays,
    );
    stdout.writeln('URI swap da incollare nell\'app:');
    stdout.writeln(uri);
    final uriPath = opts['uri-file'] ?? 'swap-uri.txt';
    await _writePrivate(File(uriPath), uri);
    stdout.writeln('salvata in $uriPath (permessi 600)');
    return;
  }

  final logger = Logger(
    minLevel: LogLevel.values.firstWhere(
      (l) => l.name == config.logLevel,
      orElse: () => LogLevel.info,
    ),
  );

  final ClnApi cln;
  final cliPath = config.clnCliPath;
  if (cliPath != null && cliPath.isNotEmpty) {
    // PERCHÉ: provider CO-LOCATO col nodo → socket locale, nessuna rune
    // (il fork .4 non permette di creare runi nuove: commando senza metodi).
    logger.info('swapd: CLN via lightning-cli locale ($cliPath)');
    cln = ClnCliApi(
      cliPath: cliPath,
      lightningDir: config.clnLightningDir,
      ldLibraryPath: config.clnLdLibraryPath,
      logger: logger,
    );
  } else {
    final String rune;
    try {
      rune = config.loadRune();
    } on FormatException catch (e) {
      stderr.writeln('RUNE NON LEGGIBILE: ${e.message}');
      exit(78);
    }
    // // PERCHÉ: la rune swapd è DEDICATA (decode,pay,listpays,newaddr): se
    // // finisse compromessa il danno resta confinato ai comandi dello swap.
    cln = ClnRestClient(
      baseUrl: config.clnUrl,
      rune: rune,
      logger: logger,
    );
  }
  final chain = EsploraChainApi(baseUrl: config.chain.esploraUrl);
  final store = SwapStore(config.storeFile);
  await store.load();
  final service = SwapService(
    cln: cln,
    chain: chain,
    store: store,
    config: config,
    signer: SwapSigner(providerKeyHex),
    logger: logger,
  );
  final handlers = SwapHandlers(service: service, store: store, logger: logger);
  final daemon = SwapDaemon(
    transport: WebSocketTransport(logger: logger),
    service: service,
    handlers: handlers,
    store: store,
    config: config,
    providerKeyHex: providerKeyHex,
    logger: logger,
  );

  try {
    await daemon.start();
  } catch (e) {
    stderr.writeln('AVVIO FALLITO: $e');
    exit(1);
  }
  logger.info(
    'swapd operativo: tick ${config.timeouts.tickSec}s, '
    'store ${config.storeFile}',
  );

  ProcessSignal.sigint.watch().listen((_) async {
    logger.info('arresto richiesto (SIGINT)');
    await daemon.stop();
    exit(0);
  });
  ProcessSignal.sigterm.watch().listen((_) async {
    logger.info('arresto richiesto (SIGTERM)');
    await daemon.stop();
    exit(0);
  });

  // Resta viva: il servizio lavora tramite stream e timer.
  await Completer<void>().future;
}

/// URI per l'app: `nostr+swap://<pubkey>?v=1&network=blake2b&relay=…` (relay
/// ripetibile: il client ha una lista per il failover).
String _buildUri({
  required String providerPubkey,
  required List<String> relays,
}) =>
    Uri(
      scheme: SwapConsts.uriScheme,
      host: providerPubkey,
      queryParameters: <String, dynamic>{
        'v': '${SwapConsts.protocolVersion}',
        'network': SwapConsts.network,
        'relay': relays,
      },
    ).toString();

/// Scrive un file di SEGRETO con permessi 600 (best-effort: chmod è POSIX).
Future<void> _writePrivate(File file, String content) async {
  await file.writeAsString('$content\n', flush: true);
  if (!Platform.isWindows) {
    try {
      await Process.run('chmod', ['600', file.path]);
    } catch (_) {
      // best-effort: il file esiste comunque, i permessi sono un extra.
    }
  }
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
