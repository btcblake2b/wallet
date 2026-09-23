import 'package:btc_blake2b_wallet/core/services/swap/swap_models.dart';
import 'package:btc_blake2b_wallet/core/services/swap/swap_session_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStorage extends Mock implements FlutterSecureStorage {}

SwapSession sessionOf({
  String? swapId,
  int refundKeyIndex = 0,
  SwapClientState state = SwapClientState.awaitingFunding,
  int createdAt = 1758100000,
}) =>
    SwapSession(
      swapId: swapId ?? 'aa' * 16,
      invoice: 'lnbc50u1ptest',
      paymentHashHex: 'ab' * 32,
      fundingAmountSats: 5250,
      cltvHeight: 972144,
      fundingDeadlineHeight: 971998,
      claimPubkeyHex: '02${'11' * 32}',
      refundPubkeyHex: '02${'22' * 32}',
      refundKeyIndex: refundKeyIndex,
      htlcAddress: 'bc1qexample',
      witnessScriptHex: '63a82000',
      providerPubkey: 'cd' * 32,
      relays: const ['wss://relay.test'],
      state: state,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

void main() {
  late MockStorage storage;
  late Map<String, String> data;
  late SwapSessionStore store;

  setUp(() {
    storage = MockStorage();
    data = <String, String>{};
    when(() => storage.read(key: any(named: 'key')))
        .thenAnswer((inv) async => data[inv.namedArguments[#key] as String]);
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((inv) async {
      data[inv.namedArguments[#key] as String] =
          inv.namedArguments[#value] as String;
    });
    when(() => storage.delete(key: any(named: 'key')))
        .thenAnswer((inv) async => data.remove(inv.namedArguments[#key]));
    store = SwapSessionStore(storage: storage);
  });

  test('registro vuoto → lista vuota', () async {
    expect(await store.all(), isEmpty);
    expect(await store.byId('aa' * 16), isNull);
  });

  test('upsert → all: persistito con round-trip fedele', () async {
    final session = sessionOf(refundKeyIndex: 3);
    await store.upsert(session);
    final restored = (await store.all()).single;
    expect(restored.swapId, session.swapId);
    expect(restored.refundKeyIndex, 3);
    expect(restored.witnessScriptHex, session.witnessScriptHex);
    expect(restored.relays, session.relays);
    expect(await store.byId(session.swapId), isNotNull);
  });

  test('upsert sullo stesso swap_id: aggiorna, non duplica', () async {
    await store.upsert(sessionOf());
    await store.upsert(
      sessionOf(state: SwapClientState.completed, refundKeyIndex: 0),
    );
    final all = await store.all();
    expect(all.length, 1);
    expect(all.single.state, SwapClientState.completed);
    expect(all.single.needsAttention, false);
  });

  test('remove: elimina solo la sessione indicata', () async {
    await store.upsert(sessionOf(swapId: 'aa' * 16));
    await store.upsert(sessionOf(swapId: 'bb' * 16, refundKeyIndex: 1));
    await store.remove('bb' * 16);
    final all = await store.all();
    expect(all.length, 1);
    expect(all.single.swapId, 'aa' * 16);
  });

  test('nextRefundKeyIndex: max+1 (mai riuso di chiave)', () async {
    expect(await store.nextRefundKeyIndex(), 0);
    await store.upsert(sessionOf(swapId: 'aa' * 16, refundKeyIndex: 0));
    await store.upsert(sessionOf(swapId: 'bb' * 16, refundKeyIndex: 2));
    expect(await store.nextRefundKeyIndex(), 3);
  });

  test('all: più recenti prima', () async {
    await store.upsert(sessionOf(swapId: 'aa' * 16, createdAt: 100));
    await store.upsert(sessionOf(swapId: 'bb' * 16, createdAt: 200));
    final all = await store.all();
    expect(all.first.swapId, 'bb' * 16);
  });

  test('registro corrotto → tollerato (lista vuota)', () async {
    data['swap_sessions'] = '{non-json';
    expect(await store.all(), isEmpty);
  });

  test('voce corrotta nel JSON → saltata, le altre restano', () async {
    data['swap_sessions'] = '[{"swap_id":"x"}, ${_validJsonEntry()}]';
    final all = await store.all();
    expect(all.length, 1);
    expect(all.single.swapId, 'aa' * 16);
  });
}

String _validJsonEntry() {
  final session = sessionOf();
  final json = session.toJson().entries
      .map((e) => '"${e.key}": ${_jsonValue(e.value)}')
      .join(', ');
  return '{$json}';
}

String _jsonValue(Object? value) {
  if (value == null) return 'null';
  if (value is num) return '$value';
  if (value is List) return '[${value.map((v) => '"$v"').join(',')}]';
  return '"$value"';
}
