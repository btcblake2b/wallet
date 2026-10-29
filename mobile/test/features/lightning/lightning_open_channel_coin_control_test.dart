import 'package:btc_blake2b_wallet/core/models/lightning_connection.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_service_mock.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/lightning_open_channel_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Coin control sull'apertura di un canale (A8).
///
/// // PERCHÉ: il valore del coin control è tutto nel percorso UI → bridge: se
/// gli outpoint scelti non arrivano a `openChannel`, l'utente crede di aver
/// deciso gli input e invece il nodo sceglie da sé. Un test lo blocca.
void main() {
  // Output confermato del mock (`LightningServiceMock.listUtxos`).
  const confirmed =
      'b34ada856e581d18a5f6ef2718767b159aaa88f2e32abf34f97d89f037b10cd6:0';

  // PERCHÉ: il mock (come il nodo reale) risponde solo se connesso.
  const connection = LightningConnection(
    walletPubkey:
        'f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9',
    relays: ['wss://relay.test'],
    secretHex:
        'b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d9045190cfef',
  );

  Future<LightningServiceMock> pumpScreen(WidgetTester tester) async {
    final service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: LightningOpenChannelScreen(lightningService: service),
      ),
    );
    await tester.pumpAndSettle();
    return service;
  }

  Future<void> fillForm(WidgetTester tester) async {
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '02${'cc' * 32}');
    await tester.enterText(fields.at(2), '20000');
    await tester.pumpAndSettle();
  }

  testWidgets('senza selezione il coin control non viaggia (auto)',
      (tester) async {
    final service = await pumpScreen(tester);
    await fillForm(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Open channel'));
    await tester.pumpAndSettle();

    expect(service.lastOpenChannelUtxos, isEmpty);
  });

  testWidgets('l\'output scelto arriva al servizio', (tester) async {
    final service = await pumpScreen(tester);
    await fillForm(tester);

    await tester.tap(find.text('Coin control (optional)'));
    await tester.pumpAndSettle();

    final tiles = find.byType(CheckboxListTile);
    expect(tiles, findsNWidgets(2));
    // Edge case: l'output non confermato/riservato NON è selezionabile.
    expect(tester.widget<CheckboxListTile>(tiles.at(1)).onChanged, isNull);

    await tester.tap(tiles.first);
    await tester.pumpAndSettle();
    // PERCHÉ: con la sezione espansa il pulsante esce dal viewport (ListView
    // lazy) → va riportato in vista prima del tap.
    await tester.dragUntilVisible(
      find.widgetWithText(FilledButton, 'Open channel'),
      find.byType(ListView),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Open channel'));
    await tester.pumpAndSettle();

    expect(service.lastOpenChannelUtxos, [confirmed]);
  });
}
