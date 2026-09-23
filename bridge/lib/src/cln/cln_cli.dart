import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../logger.dart';
import '../protocol.dart';
import 'cln_api.dart';

/// Client CLN via `lightning-cli` (socket UNIX locale).
///
/// // PERCHÉ: un provider CO-LOCATO col nodo non ha bisogno di rune: il socket
/// // locale (`~/.lightning/bitcoin/lightning-rpc`) autorizza in base ai
/// // permessi del filesystem — nessun segreto su disco o in rete. Scelta resa
/// // necessaria il 18/09/2026: il fork blake2b `.4` ha il plugin commando
/// // `active` ma senza metodi (commando-rune → "Unknown command"), quindi non
/// // si possono creare runi nuove.
class ClnCliApi implements ClnApi {
  ClnCliApi({
    required this.cliPath,
    this.lightningDir,
    this.ldLibraryPath,
    this.timeout = const Duration(minutes: 2),
    Logger? logger,
  }) : _logger = logger ?? Logger();

  /// Percorso del binario (es. `~/cln-blake2b/usr/bin/lightning-cli`).
  final String cliPath;

  /// `--lightning-dir` del nodo (es. `~/.lightning`), se non è il default.
  final String? lightningDir;

  /// `LD_LIBRARY_PATH` richiesto dal binario del fork (es. `~/cln-blake2b/lib`).
  final String? ldLibraryPath;

  final Duration timeout;
  final Logger _logger;

  @override
  Future<Map<String, dynamic>> call(
    String method, [
    Map<String, dynamic> params = const {},
  ]) async {
    final args = buildLightningCliArgs(
      method: method,
      params: params,
      lightningDir: lightningDir,
    );
    final ProcessResult result;
    try {
      result = await Process.run(
        cliPath,
        args,
        environment: {
          ...Platform.environment,
          if (ldLibraryPath != null && ldLibraryPath!.isNotEmpty)
            'LD_LIBRARY_PATH': ldLibraryPath!,
        },
      ).timeout(timeout);
    } on ProcessException catch (e) {
      throw RpcError('OTHER', 'lightning-cli non eseguibile: ${e.message}');
    } on TimeoutException {
      throw RpcError('OTHER', 'lightning-cli in timeout su $method');
    }
    _logger.debug('cln-cli: $method → exit ${result.exitCode}');
    return parseLightningCliResult(
      method: method,
      exitCode: result.exitCode,
      stdout: '${result.stdout}',
      stderr: '${result.stderr}',
    );
  }
}

/// Argomenti per `lightning-cli` (SENZA il percorso del binario).
///
/// // PERCHÉ `-k` (keyword) e NON l'oggetto JSON: verificato sul campo
/// // (18/09/2026, fork .4) che questa build non parsa l'oggetto JSON come
/// // primo argomento — lo passa come VALORE del parametro posizionale
/// // (`decode '{"string":"lnbc…"}'` → "Unparsable string: invalid token").
/// // La forma keyword è stabile e non richiede escaping.
///
/// Formato: `lightning-cli [--lightning-dir=…] -k <method> k=v k=v …`
List<String> buildLightningCliArgs({
  required String method,
  Map<String, dynamic> params = const {},
  String? lightningDir,
}) =>
    [
      if (lightningDir != null && lightningDir.isNotEmpty)
        '--lightning-dir=$lightningDir',
      '-k',
      method,
      for (final entry in params.entries)
        '${entry.key}=${_cliValue(entry.value)}',
    ];

String _cliValue(Object? value) {
  if (value == null) return '';
  if (value is bool) return value ? 'true' : 'false';
  return '$value';
}

/// Converte l'esito di `lightning-cli` nel formato di [ClnApi].
///
/// Lancia [RpcError] su exit code ≠ 0 (col codice/messaggio del nodo) o su
/// output non JSON: fail-closed — mai silenziare un errore del nodo.
Map<String, dynamic> parseLightningCliResult({
  required String method,
  required int exitCode,
  required String stdout,
  required String stderr,
}) {
  final rawOut = stdout.trim().isNotEmpty ? stdout.trim() : stderr.trim();
  // PERCHÉ (18/09/2026): il fork `.4` scrive su STDOUT anche le righe di log
  // dei plugin (`# Flow 0/1: …`) PRIMA del risultato JSON → `jsonDecode`
  // sull'output intero falliva anche su comandi RIUSCITI (visto sul pre-flight
  // `getroutes` e sul messaggio di `pay`). Si ignorano le righe che iniziano
  // con `#` (nel JSON pretty-print di CLN nessuna riga di dato inizia così).
  final raw = rawOut
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('#'))
      .join('\n')
      .trim();
  Map<String, dynamic>? decoded;
  try {
    final json = jsonDecode(raw);
    if (json is Map) decoded = json.cast<String, dynamic>();
  } catch (_) {
    decoded = null;
  }
  if (exitCode != 0) {
    if (decoded != null && decoded['message'] != null) {
      // CLN risponde `{"code": <int|string>, "message": "…"}`.
      final code = decoded['code'];
      throw RpcError(
        code is String && code.isNotEmpty ? code : 'OTHER',
        '${decoded['message']}',
      );
    }
    throw RpcError(
      'OTHER',
      'lightning-cli $method fallito (exit $exitCode): '
      '${raw.isEmpty ? '' : raw.substring(0, raw.length > 160 ? 160 : raw.length)}',
    );
  }
  if (decoded == null) {
    throw RpcError(
      'OTHER',
      'output di lightning-cli $method non JSON: '
      '${raw.isEmpty ? '' : raw.substring(0, raw.length > 160 ? 160 : raw.length)}',
    );
  }
  return decoded;
}
