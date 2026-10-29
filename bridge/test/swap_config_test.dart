import 'dart:convert';
import 'dart:io';

import 'package:nwc_cln_bridge/src/swap/swap_config.dart';
import 'package:test/test.dart';

/// Config del provider swap: default di sicurezza e validazione fail-fast.
///
/// // PERCHÉ (B1/B2, 05/10/2026): la config è l'unico punto in cui si decide
/// // chi può usare il provider e quanto può esporre — se sbaglia, sbaglia in
/// // silenzio. Questi test bloccano le regressioni (fail-open, riserva fuori
/// // range) PRIMA che arrivino su un nodo con fondi veri.
void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('swap_cfg_'));
  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  /// Scrive una config con i campi obbligatori + [overrides],
  /// e ne ritorna il path.
  String writeConfig(Map<String, dynamic> overrides) {
    final json = <String, dynamic>{
      'relays': ['wss://relay.test'],
      'clnUrl': 'http://127.0.0.1:3001',
      'providerKeyFile': '${tmp.path}/provider.key',
      'storeFile': '${tmp.path}/swap-store.json',
      'chain': {'esploraUrl': 'https://example.test/api'},
      ...overrides,
    };
    final path = '${tmp.path}/swap-config.json';
    File(path).writeAsStringSync(jsonEncode(json));
    return path;
  }

  group('allowlist client (B1 — fail-closed)', () {
    test('senza allowlist e senza flag → config RIFIUTATA', () {
      expect(
        () => SwapConfig.fromJsonFile(writeConfig(const {})),
        throwsA(isA<FormatException>()),
      );
    });

    test('allowlist popolata → accettata, modo aperto disattivo', () {
      final cfg = SwapConfig.fromJsonFile(
        writeConfig({
          'allowedClientPubkeys': ['AB' * 32],
        }),
      );
      // Le pubkey sono normalizzate in minuscolo (confronto con l'evento).
      expect(cfg.allowedClientPubkeys, ['ab' * 32]);
      expect(cfg.allowAnyClient, isFalse);
    });

    test('allowAnyClient esplicito → accettata anche con allowlist vuota', () {
      final cfg = SwapConfig.fromJsonFile(
        writeConfig({'allowAnyClient': true}),
      );
      expect(cfg.allowAnyClient, isTrue);
      expect(cfg.allowedClientPubkeys, isEmpty);
    });

    test('accetta anche la lista con voci vuote (ripulite)', () {
      final cfg = SwapConfig.fromJsonFile(
        writeConfig({
          'allowedClientPubkeys': ['', 'AB' * 32],
        }),
      );
      expect(cfg.allowedClientPubkeys, ['ab' * 32]);
    });
  });

  group('riserva di liquidità (B2)', () {    test('default 20%', () {
      final cfg = SwapConfig.fromJsonFile(
        writeConfig({
          'allowedClientPubkeys': ['ab' * 32],
        }),
      );
      expect(cfg.limits.liquidityReservePpm, 200000);
    });

    test('valore fuori range → FormatException', () {
      expect(
        () => SwapConfig.fromJsonFile(
          writeConfig({
            'allowedClientPubkeys': ['ab' * 32],
            'limits': {'liquidityReservePpm': 1000000},
          }),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('valore valido → rispettato', () {
      final cfg = SwapConfig.fromJsonFile(
        writeConfig({
          'allowedClientPubkeys': ['ab' * 32],
          'limits': {'liquidityReservePpm': 100000},
        }),
      );
      expect(cfg.limits.liquidityReservePpm, 100000);
      // I limiti preesistenti non sono toccati (nessuna regressione).
      expect(cfg.limits.minSats, 5000);
      expect(cfg.limits.maxSats, 250000);
      expect(cfg.limits.maxPerPubkey, 2);
    });
  });

  group('auto-admit client (lista auto-popolata, 07/10/2026)', () {
    test('autoAdmit con allowlist vuota → accettata, file derivato', () {
      final cfg = SwapConfig.fromJsonFile(
        writeConfig({
          'clients': {'autoAdmit': true},
        }),
      );

      expect(cfg.autoAdmit, isTrue);
      expect(cfg.autoAdmitMaxPerDay, 20);
      expect(cfg.autoAdmitMaxTotal, 500);
      // Default: accanto allo storeFile (stessa cartella, stessi permessi).
      expect(
        cfg.clientsFile,
        '${tmp.path}${Platform.pathSeparator}allowed-clients.json',
      );
    });

    test('file esplicito → rispettato', () {
      final cfg = SwapConfig.fromJsonFile(
        writeConfig({
          'clients': {
            'autoAdmit': true,
            'file': '${tmp.path}${Platform.pathSeparator}cli.json',
          },
        }),
      );

      expect(cfg.clientsFile, '${tmp.path}${Platform.pathSeparator}cli.json');
    });

    test('tetti non validi → FormatException', () {
      expect(
        () => SwapConfig.fromJsonFile(
          writeConfig({
            'clients': {'autoAdmit': true, 'autoAdmitMaxPerDay': 0},
          }),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('senza autoAdmit e senza lista resta il rifiuto (fail-closed)', () {
      expect(
        () => SwapConfig.fromJsonFile(
          writeConfig(const {'clients': {'autoAdmit': false}}),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('denylist che interseca la allowlist → FormatException', () {
      expect(
        () => SwapConfig.fromJsonFile(
          writeConfig({
            'allowedClientPubkeys': ['ab' * 32],
            'deniedClientPubkeys': ['AB' * 32],
          }),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('denylist fuori dalla allowlist → accettata e normalizzata', () {
      final cfg = SwapConfig.fromJsonFile(
        writeConfig({
          'allowedClientPubkeys': ['ab' * 32],
          'deniedClientPubkeys': ['CD' * 32],
        }),
      );

      expect(cfg.deniedClientPubkeys, ['cd' * 32]);
    });
  });
}
