import 'package:btc_blake2b_wallet/core/models/lightning_connection.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_connection_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStorage extends Mock implements FlutterSecureStorage {}

/// Chiave dello storico (privata nello store): usata solo per iniettare casi
/// corrotti nello storage finto.
const _historyKey = 'lightning_nwc_history';

/// Secret di default per i test (una costante di default non può contenere
/// l'operatore `*`: per questo è un `final` a livello di file).
final _defaultSecret = 'aa' * 32;

String uriFor(String pubkey, {String? secret}) =>
    'nostr+walletconnect://$pubkey'
    '?relay=wss%3A%2F%2Frelay.test&secret=${secret ?? _defaultSecret}';

void main() {
  late MockStorage storage;
  late Map<String, String> data;
  late LightningConnectionStore store;

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
    store = LightningConnectionStore(storage: storage);
  });

  test('save: connessione attiva E ingresso nello storico', () async {
    await store.save(LightningConnection.fromUri(uriFor('11' * 32)));
    expect((await store.load())!.walletPubkey, '11' * 32);
    final history = await store.history();
    expect(history.single.walletPubkey, '11' * 32);
  });

  test('storico: più recente in testa, un solo nodo per pubkey', () async {
    await store.remember(LightningConnection.fromUri(uriFor('11' * 32)));
    await store.remember(LightningConnection.fromUri(uriFor('22' * 32)));
    // Stesso nodo con un secret nuovo: resta UNA voce, in testa, aggiornata.
    await store.remember(
      LightningConnection.fromUri(uriFor('11' * 32, secret: 'bb' * 32)),
    );
    final history = await store.history();
    expect(history.length, 2);
    expect(history.first.walletPubkey, '11' * 32);
    expect(history.first.secretHex, 'bb' * 32);
    expect(history.last.walletPubkey, '22' * 32);
  });

  test('storico: tetto a historyMax voci', () async {
    for (var i = 0; i < LightningConnectionStore.historyMax + 3; i++) {
      final pub = i.toRadixString(16).padLeft(2, '0').padRight(64, '0');
      await store.remember(LightningConnection.fromUri(uriFor(pub)));
    }
    expect(
      (await store.history()).length,
      LightningConnectionStore.historyMax,
    );
  });

  test('storico: voce corrotta ignorata, le valide restano', () async {
    data[_historyKey] = '["spazzatura","${uriFor('33' * 32)}"]';
    final history = await store.history();
    expect(history.single.walletPubkey, '33' * 32);
  });

  test('clear cancella la connessione attiva ma NON lo storico', () async {
    await store.save(LightningConnection.fromUri(uriFor('11' * 32)));
    await store.clear();
    expect(await store.load(), isNull);
    expect((await store.history()).length, 1);
  });
}
