import 'package:btc_blake2b_wallet/core/models/lightning_connection.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_service_mock.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/lightning_onchain_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LightningServiceMock service;

  const connection = LightningConnection(
    walletPubkey:
        'f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9',
    relays: ['wss://relay.test'],
    secretHex:
        'b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d9045190cfef',
  );

  Widget wrap(LightningServiceMock lightningService) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: LightningOnchainScreen(lightningService: lightningService),
      );

  /// I test degli appunti hanno bisogno di un handler sul canale di piattaforma.
  void mockClipboard(WidgetTester tester) {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    addTearDown(() => calls.clear());
  }

  testWidgets('saldo on-chain con confermati e in attesa', (tester) async {
    service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    expect(find.text('On-chain balance'), findsOneWidget);
    // 25.000 sat di saldo mock: 20.000 confermati + 5.000 in attesa.
    expect(find.text('25,000 sat'), findsOneWidget);
    expect(find.text('Confirmed: 20,000 sat'), findsOneWidget);
    expect(find.text('Pending: 5,000 sat'), findsOneWidget);
  });

  testWidgets('indirizzi: badge "con saldo" e copia', (tester) async {
    mockClipboard(tester);
    service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    expect(find.text('Node addresses'), findsOneWidget);
    expect(find.text('With funds'), findsOneWidget); // solo il primo indirizzo
    expect(find.text('New address'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.copy).first);
    await tester.pumpAndSettle();
    expect(find.text('Copied'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('nuovo indirizzo taproot dal dialog', (tester) async {
    service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New address'));
    await tester.pumpAndSettle();

    expect(find.text('Address type'), findsOneWidget);
    await tester.tap(find.text('Taproot (bc1p)'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Confirm'));
    await tester.pumpAndSettle();

    // Il mock genera un indirizzo col prefisso taproot e la snackbar lo mostra.
    expect(find.textContaining('bc1pmock'), findsWidgets);
  });

  testWidgets('UTXO: stati, riserva e svuotamento', (tester) async {
    service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    expect(find.text('UTXOs'), findsOneWidget);
    expect(find.text('20,000 sat'), findsWidgets);
    expect(find.textContaining('Reserved'), findsWidgets);
    expect(find.textContaining('Pending'), findsWidgets);
    // Il mock ha due UTXO: nessuno stato vuoto.
    expect(find.text('No UTXOs'), findsNothing);
  });
}
