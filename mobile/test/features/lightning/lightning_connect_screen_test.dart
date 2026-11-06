import 'package:btc_blake2b_wallet/core/models/lightning_connection.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_connection_store.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_service.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_service_mock.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/lightning_connect_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Store in memoria: stessa semantica del vero (più recente in testa, un nodo
/// per pubkey) senza secure storage.
class _MemoryStore extends LightningConnectionStore {
  final List<LightningConnection> _entries = <LightningConnection>[];

  @override
  Future<List<LightningConnection>> history() async =>
      List<LightningConnection>.unmodifiable(_entries);

  @override
  Future<void> remember(LightningConnection connection) async {
    _entries.removeWhere((e) => e.walletPubkey == connection.walletPubkey);
    _entries.insert(0, connection);
  }

  @override
  Future<void> save(LightningConnection connection) => remember(connection);

  @override
  Future<LightningConnection?> load() async =>
      _entries.isEmpty ? null : _entries.first;

  @override
  Future<void> clear() async => _entries.clear();
}

/// Nodo irraggiungibile: il connect fallisce dopo l'URI valida.
class _OfflineService extends LightningServiceMock {
  @override
  Future<void> connect(LightningConnection connection) async {
    throw const LightningException('UNAVAILABLE', 'node offline');
  }
}

void main() {
  const connection = LightningConnection(
    walletPubkey:
        'f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9',
    relays: ['wss://relay.test'],
    secretHex:
        'b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d9045190cfef',
    lud16: 'node@example.com',
  );

  late _MemoryStore store;

  setUp(() {
    store = _MemoryStore();
  });

  Widget buildScreen({LightningService? service}) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: LightningConnectScreen(
          lightningService: service ?? LightningServiceMock(),
          connectionStore: store,
        ),
      );

  testWidgets('storico vuoto: nessun menu a tendina', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Recent nodes'), findsNothing);
  });

  testWidgets('storico pieno: menu a tendina e selezione riempie il campo',
      (tester) async {
    await store.remember(connection);
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Recent nodes'), findsOneWidget);
    // Il nodo più recente è già riproposto: riconnettersi è un tocco solo.
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      connection.toUri(),
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('node@example.com · f9308a019258…'), findsWidgets);
    await tester.tap(find.text('node@example.com · f9308a019258…').last);
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, connection.toUri());
  });

  // PERCHÉ: il nodo deve restare nello storico anche se il collegamento
  // fallisce — altrimenti chi ha il nodo offline perde il riferimento e il menu
  // non compare mai.
  testWidgets('connect fallito: il nodo resta nello storico e nel menu',
      (tester) async {
    await tester.pumpWidget(buildScreen(service: _OfflineService()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), connection.toUri());
    await tester.tap(find.text('Connect node'));
    await tester.pumpAndSettle();

    final history = await store.history();
    expect(history.single.walletPubkey, connection.walletPubkey);
    expect(find.text('Recent nodes'), findsOneWidget);
  });
}
