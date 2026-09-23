import 'dart:convert';
import 'dart:io';

import 'package:nwc_cln_bridge/src/swap/swap_models.dart';
import 'package:nwc_cln_bridge/src/swap/swap_store.dart';
import 'package:test/test.dart';

import 'swap_fixtures.dart';

/// Store delle sessioni swap: persistenza, atomicità, idempotenza, corruzione.
void main() {
  late Directory dir;
  late String path;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('swap_store_');
    path = '${dir.path}/swap-store.json';
  });

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('round-trip: upsert → load su una nuova istanza', () async {
    final store = SwapStore(path);
    final session = SwapFixtures.session(id: 'id-1');
    await store.upsert(session);
    expect(File(path).existsSync(), isTrue);

    final reloaded = SwapStore(path);
    await reloaded.load();
    final got = reloaded.byId('id-1');
    expect(got, isNotNull);
    expect(got!.paymentHashHex, session.paymentHashHex);
    expect(got.state, SwapState.awaitingFunding);
    expect(got.fundingAmountSats, 5250);
    expect(got.toJson(), session.toJson());
  });

  test('blockingByPaymentHash: completata/refunded non bloccano più', () async {
    final store = SwapStore(path);
    await store.upsert(
      SwapFixtures.session(id: 'a', paymentHashHex: 'aa' * 32),
    );
    await store.upsert(
      SwapFixtures.session(
        id: 'b',
        paymentHashHex: 'bb' * 32,
        state: SwapState.completed,
      ),
    );
    await store.upsert(
      SwapFixtures.session(
        id: 'c',
        paymentHashHex: 'cc' * 32,
        state: SwapState.refunded,
      ),
    );
    expect(store.blockingByPaymentHash('aa' * 32)?.id, 'a');
    expect(store.blockingByPaymentHash('bb' * 32), isNull);
    expect(store.blockingByPaymentHash('cc' * 32), isNull);
  });

  test('active: solo gli stati vivi', () async {
    final store = SwapStore(path);
    await store.upsert(
      SwapFixtures.session(id: 'a', state: SwapState.awaitingFunding),
    );
    await store.upsert(
      SwapFixtures.session(id: 'b', state: SwapState.claiming),
    );
    await store.upsert(
      SwapFixtures.session(id: 'c', state: SwapState.expired),
    );
    await store.upsert(
      SwapFixtures.session(id: 'd', state: SwapState.completed),
    );
    final ids = store.active().map((s) => s.id).toList();
    expect(ids, containsAll(['a', 'b']));
    expect(ids, isNot(contains('c')));
    expect(ids, isNot(contains('d')));
  });

  test('idempotenza: remember → get (anche dopo reload), scadenza esclusa',
      () async {
    final store = SwapStore(path, idempotencyTtlSeconds: 3600);
    await store.rememberResponse('k1', {'swap_id': 'xyz'});
    expect(store.idempotentResponse('k1'), {'swap_id': 'xyz'});

    final reloaded = SwapStore(path, idempotencyTtlSeconds: 3600);
    await reloaded.load();
    expect(reloaded.idempotentResponse('k1'), {'swap_id': 'xyz'});

    // Entry scaduta nel file → non caricata.
    final raw = (jsonDecode(File(path).readAsStringSync()) as Map)
        .cast<String, dynamic>();
    (raw['idempotency'] as Map)['k2'] = {
      'ts': 1,
      'response': {'old': true},
    };
    File(path).writeAsStringSync(jsonEncode(raw));
    final timeTraveler = SwapStore(path, idempotencyTtlSeconds: 3600);
    await timeTraveler.load();
    expect(timeTraveler.idempotentResponse('k2'), isNull);
    expect(timeTraveler.idempotentResponse('k1'), isNotNull);
  });

  test('file corrotto: una sessione invalida non blocca le altre', () async {
    final store = SwapStore(path);
    await store.upsert(SwapFixtures.session(id: 'good'));
    final raw = (jsonDecode(File(path).readAsStringSync()) as Map)
        .cast<String, dynamic>();
    (raw['sessions'] as List).add({'id': 'broken'});
    File(path).writeAsStringSync(jsonEncode(raw));

    final reloaded = SwapStore(path);
    await reloaded.load();
    expect(reloaded.byId('good'), isNotNull);
    expect(reloaded.byId('broken'), isNull);
  });

  test('save crea la directory di destinazione', () async {
    final nested = '${dir.path}/deep/nested/swap.json';
    final store = SwapStore(nested);
    await store.upsert(SwapFixtures.session(id: 'x'));
    expect(File(nested).existsSync(), isTrue);
  });
}
