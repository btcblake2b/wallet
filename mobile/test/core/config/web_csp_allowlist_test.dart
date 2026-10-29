import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/core/config/bitcoin_network_config.dart';
import 'package:btc_blake2b_wallet/core/services/fiat_price.dart';
import 'package:btc_blake2b_wallet/core/services/fx_rates.dart';
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

    test('gli host https della CSP coincidono con gli Esplora + NeoXEX', () {
      final connectSrc = _cspDirectives()['connect-src'] ?? const <String>[];
      final cspHosts =
          connectSrc.where((value) => value.startsWith('https://')).toSet();

      final appHosts = <String>{
        for (final url in BitcoinNetworkConfig.explorerApiBaseUrls)
          _origin(url),
        // PERCHÉ (29/10): il prezzo automatico NeoXEX è on-demand e parte
        // SOLO se l'utente attiva il toggle nelle Impostazioni. L'host deve
        // stare in `connect-src` altrimenti il browser blocca il fetch.
        _origin(FiatPrice.neoxexTradesEndpoint),
        // PERCHÉ (29/10): il cambio USDT→valuta per il controvalore in EUR
        // (& co.) è letto da Coinbase solo quando serve.
        _origin(FxRates.endpoint),
      };

      expect(
        cspHosts,
        appHosts,
        reason: 'ALLINEARE: ogni host di '
            'BitcoinNetworkConfig.explorerApiBaseUrls e di '
            'FiatPrice.neoxexTradesEndpoint deve stare in `connect-src` '
            '(altrimenti failover/prezzo automatico sono bloccati dal '
            'browser) e nessun host estraneo deve restare nella CSP.',
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

    test('script-src non concede unsafe-inline né unsafe-eval', () {
      final scriptSrc = _cspDirectives()['script-src'] ?? const <String>[];

      expect(scriptSrc, contains("'self'"));
      // CanvasKit compila a runtime: la deroga vale SOLO per il WebAssembly.
      expect(scriptSrc, contains("'wasm-unsafe-eval'"));
      // Confronto per TOKEN: `'wasm-unsafe-eval'` contiene la sottostringa
      // "unsafe-eval", un `contains` testuale darebbe un falso positivo.
      expect(scriptSrc, isNot(contains("'unsafe-inline'")));
      expect(scriptSrc, isNot(contains("'unsafe-eval'")));
    });

    test('le direttive che chiudono la superficie sono presenti', () {
      final directives = _cspDirectives();

      expect(directives['default-src'], contains("'self'"));
      expect(directives['connect-src'], contains("'self'"));
      expect(directives['object-src'], contains("'none'"));
      // PERCHÉ (27/10) `'self'` e non `'none'`: Flutter Web usa
      // `<base href="/">` e con `'none'` il browser lo blocca (violazione vista
      // sull'app online). `'self'` vieta comunque un base verso altri domini.
      expect(directives['base-uri'], contains("'self'"));
      expect(directives['base-uri'], isNot(contains('*')));
      expect(directives['frame-ancestors'], contains("'none'"));
      expect(directives['form-action'], contains("'none'"));
    });

    test('nessun host esterno fuori da connect-src', () {
      for (final entry in _cspDirectives().entries) {
        if (entry.key == 'connect-src') continue;
        for (final value in entry.value) {
          expect(
            value.contains('//'),
            isFalse,
            reason: '${entry.key} cita un host esterno ($value): la superficie '
                'di rete deve passare solo da connect-src, in allowlist',
          );
        }
      }
    });
  });
}
