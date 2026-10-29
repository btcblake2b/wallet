import 'dart:convert';
import 'dart:io';

import 'package:nwc_cln_bridge/src/swap/swap_client_admission.dart';
import 'package:nwc_cln_bridge/src/swap/swap_config.dart';
import 'package:test/test.dart';

/// Ammissione client dello swap: denylist, auto-admit e tetti.
///
/// // PERCHÉ (07/10/2026): la lista non va mantenuta a mano in produzione, ma
/// // deve restare fail-closed e controllabile (espulsione + tetti). Questi
/// // test bloccano le regressioni su un punto che decide chi consuma la
/// // liquidità del nodo.
void main() {
  late Directory tmp;
  late File clientsFile;
  var now = DateTime.utc(2026, 10, 7, 12);

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('swap_adm_');
    clientsFile = File('${tmp.path}/allowed-clients.json');
    now = DateTime.utc(2026, 10, 7, 12);
  });
  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  SwapConfig buildConfig({
    List<String> allowed = const [],
    bool allowAny = false,
    bool autoAdmit = false,
    int maxPerDay = 20,
    int maxTotal = 500,
    List<String> denied = const [],
  }) =>
      SwapConfig(
        relays: const ['wss://relay.test'],
        clnUrl: 'http://127.0.0.1:3001',
        providerKeyFile: '${tmp.path}/provider.key',
        storeFile: '${tmp.path}/swap-store.json',
        chain: const SwapChainConfig(esploraUrl: 'https://example.test/api'),
        allowedClientPubkeys: allowed,
        allowAnyClient: allowAny,
        autoAdmit: autoAdmit,
        autoAdmitMaxPerDay: maxPerDay,
        autoAdmitMaxTotal: maxTotal,
        clientsFile: clientsFile.path,
        deniedClientPubkeys: denied,
      );

  SwapClientAdmission build(SwapConfig cfg) =>
      SwapClientAdmission(config: cfg, clock: () => now);

  final clientA = 'aa' * 32;
  final clientB = 'bb' * 32;
  final clientC = 'cc' * 32;

  group('fail-closed', () {
    test('senza auto-admit un client sconosciuto è ignorato', () async {
      final adm = build(buildConfig(allowed: [clientA]));

      expect(await adm.admit(clientB), isFalse);
      expect(adm.isAllowed(clientB), isFalse);
      expect(clientsFile.existsSync(), isFalse);
    });

    test('chiave non esadecimale → rifiutata', () async {
      final adm = build(buildConfig(autoAdmit: true));

      expect(await adm.admit('non-una-pubkey'), isFalse);
      expect(adm.admittedCount, 0);
    });

    test('la denylist vince su allowlist e modo aperto', () async {
      final adm = build(
        buildConfig(allowed: [clientA], allowAny: true, denied: [clientA]),
      );

      expect(await adm.admit(clientA), isFalse);
      expect(adm.isAllowed(clientA), isFalse);
    });
  });

  group('auto-admit', () {
    test('il primo contatto viene ammesso e persistito', () async {
      final adm = build(buildConfig(autoAdmit: true));

      expect(await adm.admit(clientA), isTrue);
      expect(adm.isAllowed(clientA), isTrue);
      expect(clientsFile.existsSync(), isTrue);

      final raw = jsonDecode(clientsFile.readAsStringSync()) as Map;
      expect((raw['admitted'] as Map).keys, contains(clientA));
    });

    test('è idempotente e sopravvive al riavvio', () async {
      final adm = build(buildConfig(autoAdmit: true));
      await adm.admit(clientA);
      await adm.admit(clientA);
      expect(adm.admittedCount, 1);

      // Nuova istanza = riavvio del daemon: la lista si ricarica dal file.
      final reborn = build(buildConfig(autoAdmit: true));
      await reborn.load();
      expect(reborn.isAllowed(clientA), isTrue);
      // Client noto: ammesso anche senza auto-admit acceso (persistito).
      expect(await reborn.admit(clientA), isTrue);
    });

    test('tetto giornaliero: il terzo client viene rifiutato', () async {
      final cfg = buildConfig(autoAdmit: true, maxPerDay: 2);
      final adm = build(cfg);

      expect(await adm.admit(clientA), isTrue);
      expect(await adm.admit(clientB), isTrue);
      expect(await adm.admit(clientC), isFalse);
    });

    test('il tetto giornaliero si azzera dopo 24h', () async {
      final cfg = buildConfig(autoAdmit: true, maxPerDay: 1);
      final adm = build(cfg);

      expect(await adm.admit(clientA), isTrue);
      expect(await adm.admit(clientB), isFalse);

      now = now.add(const Duration(hours: 25));
      expect(await adm.admit(clientB), isTrue);
    });

    test('tetto totale: oltre il massimo non si ammette più nessuno',
        () async {
      final cfg = buildConfig(autoAdmit: true, maxPerDay: 100, maxTotal: 2);
      final adm = build(cfg);

      expect(await adm.admit(clientA), isTrue);
      expect(await adm.admit(clientB), isTrue);
      now = now.add(const Duration(hours: 25));
      expect(await adm.admit(clientC), isFalse);
    });
  });

  group('denylist su lista persistita', () {
    test('al load le chiavi espulse vengono rimosse dal file', () async {
      final adm = build(buildConfig(autoAdmit: true));
      await adm.admit(clientA);
      await adm.admit(clientB);

      // L'admin espelle A e riavvia il daemon.
      final reborn = build(buildConfig(autoAdmit: true, denied: [clientA]));
      await reborn.load();

      expect(reborn.admittedCount, 1);
      expect(reborn.isAllowed(clientA), isFalse);
      expect(await reborn.admit(clientA), isFalse);
      final raw = jsonDecode(clientsFile.readAsStringSync()) as Map;
      expect((raw['admitted'] as Map).keys, isNot(contains(clientA)));
    });
  });
}
