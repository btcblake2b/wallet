import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/core/config/bitcoin_network_config.dart';
import 'package:btc_blake2b_wallet/core/services/swap/swap_web_policy.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ANTI-DRIFT: CSP della PWA ↔ allowlist dell'app
// ─────────────────────────────────────────────────────────────────────────────
// PERCHÉ: fino a oggi l'allineamento tra `web/_headers` e le costanti Dart era
// garantito SOLO da un commento ("⚠️ MANUTENZIONE: la lista DEVE restare
// allineata..."). Un disallineamento non si vede in sviluppo — si vede in
// produzione, come "il failover non funziona" o "RELAY_NOT_ALLOWED_WEB" su un
// provider legittimo. Questi test rendono il drift un fallimento di build.

/// Direttive della CSP dichiarata in `mobile/web/_headers`.
///
/// // PERCHÉ: i test girano con CWD = `mobile/`, quindi il percorso relativo è
/// stabile (stessa convenzione degli altri test che leggono file di progetto).
Map<String, List<String>> _cspDirectives() {
  final file = File('web/_headers');
  expect(
    file.existsSync(),
    isTrue,
    reason: 'web/_headers non trovato: eseguire i test da mobile/',
  );

  final headerLine = file.readAsLinesSync().firstWhere(
        (line) => line.trimLeft().startsWith('Content-Security-Policy:'),
        orElse: () => '',
      );
  expect(
    headerLine,
    isNotEmpty,
    reason: 'direttiva Content-Security-Policy assente in web/_headers',
  );

  const marker = 'Content-Security-Policy:';
  final policy = headerLine.substring(
    headerLine.indexOf(marker) + marker.length,
  );

  final directives = <String, List<String>>{};
  for (final raw in policy.split(';')) {
    final parts = raw
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length < 2) continue;
    directives[parts.first] = parts.sublist(1);
  }
  return directives;
}

/// Origine (`scheme://host`) di un URL: la CSP elenca origini, le costanti
/// dell'app sono URL completi di path (es. `.../api`).
String _origin(String url) {
  final uri = Uri.parse(url);
  return '${uri.scheme}://${uri.host}';
}

void main() {
  group('CSP PWA ↔ allowlist app', () {
    test('i relay wss della CSP coincidono con kWebAllowedSwapRelays', () {
      final connectSrc = _cspDirectives()['connect-src'] ?? const <String>[];
      expect(connectSrc, isNotEmpty, reason: 'connect-src assente');

      final cspRelays =
          connectSrc.where((value) => value.startsWith('wss://')).toSet();

      expect(
        cspRelays,
        kWebAllowedSwapRelays,
        reason: 'ALLINEARE: `connect-src` di mobile/web/_headers e '
            '`kWebAllowedSwapRelays` di swap_web_policy.dart devono contenere '
            'gli stessi relay. Un provider su un relay nuovo richiede ENTRAMBE '
            'le modifiche, altrimenti su web esce RELAY_NOT_ALLOWED_WEB.',
      );
    });

    test('gli host https della CSP coincidono con gli Esplora configurati', () {
      final connectSrc = _cspDirectives()['connect-src'] ?? const <String>[];
      final cspHosts =
          connectSrc.where((value) => value.startsWith('https://')).toSet();

      final appHosts = <String>{
        for (final url in BitcoinNetworkConfig.explorerApiBaseUrls)
          _origin(url),
      };

      expect(
        cspHosts,
        appHosts,
        reason: 'ALLINEARE: ogni host di '
            'BitcoinNetworkConfig.explorerApiBaseUrls deve stare in '
            '`connect-src` (altrimenti il failover è bloccato dal browser) e '
            'nessun host estraneo deve restare nella CSP.',
      );
    });

    test('la CSP non apre il web a un wss generico', () {
      final connectSrc = _cspDirectives()['connect-src'] ?? const <String>[];

      expect(
        connectSrc.contains('wss:'),
        isFalse,
        reason: 'un `wss:` generico è un canale di esfiltrazione per un XSS '
            'attivo mentre il vault è sbloccato: usare l allowlist esplicita.',
      );
    });
  });
}
