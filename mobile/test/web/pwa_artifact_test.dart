import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ANTI-DRIFT: artefatto PWA (index.html + manifest + regole di _headers)
// ─────────────────────────────────────────────────────────────────────────────
// PERCHÉ: l'hardening 2.4 si regge su due promesse scritte solo nei commenti —
// «nessuno script inline» (così la CSP può usare `script-src 'self'` senza
// `unsafe-inline`) e «nessun asset di terze parti» (così `font-src`/`img-src`
// restano `'self'` e la privacy policy è vera). Una modifica futura (snippet
// inline, font da CDN) romperebbe la CSP solo in PRODUZIONE: in sviluppo non
// se ne accorge nessuno. Questi test rendono il drift un fallimento di build.

/// Legge un file del progetto con CWD = `mobile/` (convenzione dei test che
/// leggono file di repository, come `web_csp_allowlist_test.dart`).
String _read(String path) {
  final file = File(path);
  expect(
    file.existsSync(),
    isTrue,
    reason: '$path non trovato: eseguire i test da mobile/',
  );
  return file.readAsStringSync();
}

void main() {
  group('PWA index.html', () {
    late String html;
    setUpAll(() => html = _read('web/index.html'));

    test('nessuno script inline', () {
      // Un tag con corpo non vuoto: `<script src="x.js"></script>` NON matcha.
      final inlineScript = RegExp(
        r'<script\b[^>]*>(?!\s*</script>)[\s\S]*?</script>',
        caseSensitive: false,
      );
      expect(
        inlineScript.hasMatch(html),
        isFalse,
        reason: 'script inline = la CSP deve concedere unsafe-inline (o hash): '
            'spostare il codice in un file .js come boot.js',
      );
    });

    test('nessun handler inline (onclick, onload, ...)', () {
      expect(
        RegExp(r'\son[a-z]+\s*=', caseSensitive: false).hasMatch(html),
        isFalse,
        reason: 'gli handler inline sono bloccati dalla CSP senza '
            'unsafe-inline: registrarli in boot.js',
      );
    });

    test('nessuna risorsa da origini esterne', () {
      final urls = RegExp(r'(?:src|href)\s*=\s*"([^"]+)"')
          .allMatches(html)
          .map((m) => m.group(1)!)
          .where((value) => !value.startsWith(r'$'))
          .toList();
      expect(urls, isNotEmpty);
      for (final url in urls) {
        expect(
          url.startsWith('http://') || url.startsWith('https://'),
          isFalse,
          reason: 'risorsa esterna "$url": rompe `default-src self` e invia '
              "l'IP dell'utente a terzi (privacy policy)",
        );
      }
    });

    test('tag PWA essenziali presenti', () {
      expect(html, contains('rel="manifest"'));
      expect(html, contains('name="theme-color"'));
      expect(html, contains('apple-touch-icon'));
      // Il fallback senza JavaScript deve esistere: senza JS l'app non parte.
      expect(html.toLowerCase(), contains('<noscript>'));
    });
  });

  group('PWA manifest.json', () {
    late Map<String, dynamic> manifest;
    setUpAll(() {
      manifest = jsonDecode(_read('web/manifest.json')) as Map<String, dynamic>;
    });

    test('campi installabilità e identità', () {
      expect(manifest['name'], isNotEmpty);
      expect(manifest['short_name'], isNotEmpty);
      expect(manifest['display'], 'standalone');
      expect(manifest['theme_color'], isNotEmpty);
      expect(manifest['background_color'], isNotEmpty);
    });

    test('start_url resta sulla stessa origine', () {
      final startUrl = '${manifest['start_url'] ?? ''}';
      expect(
        startUrl.startsWith('http://') || startUrl.startsWith('https://'),
        isFalse,
        reason: 'start_url assoluto su un\'altra origine = PWA che apre un '
            'dominio diverso da quello da cui è stata installata (phishing)',
      );
    });

    test('icone 192 e 512, incluse le maskable', () {
      final icons =
          (manifest['icons'] as List<dynamic>).cast<Map<String, dynamic>>();
      final sizes = icons.map((icon) => '${icon['sizes']}').toSet();
      expect(sizes, containsAll(<String>['192x192', '512x512']));
      expect(
        icons.any((icon) => '${icon['purpose']}'.contains('maskable')),
        isTrue,
        reason: 'senza icona maskable Android mostra un riquadro bianco',
      );
      for (final icon in icons) {
        expect('${icon['src']}'.startsWith('http'), isFalse);
      }
    });
  });

  group('PWA _headers', () {
    late String headers;
    setUpAll(() => headers = _read('web/_headers'));

    test('service worker e manifest mai in cache stantia', () {
      expect(headers, contains('/flutter_service_worker.js'));
      expect(headers, contains('Cache-Control: no-cache'));
      expect(headers, contains('/manifest.json'));
      expect(headers, contains('application/manifest+json'));
    });

    test('header di sicurezza di base presenti', () {
      for (final header in <String>[
        'Strict-Transport-Security:',
        'X-Content-Type-Options: nosniff',
        'X-Frame-Options: DENY',
        'Referrer-Policy: no-referrer',
        'Cross-Origin-Opener-Policy:',
        'Permissions-Policy:',
      ]) {
        expect(headers, contains(header), reason: 'header mancante: $header');
      }
    });
  });
}
