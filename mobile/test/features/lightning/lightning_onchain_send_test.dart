import 'package:btc_blake2b_wallet/core/models/lightning_connection.dart';
import 'package:btc_blake2b_wallet/core/models/lightning_onchain_fees.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_service_mock.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/lightning_onchain_send_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LightningServiceMock service;

  // Valori pubblici di test (vettori BIP340).
  const connection = LightningConnection(
    walletPubkey:
        'f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9',
    relays: ['wss://relay.test'],
    secretHex:
        'b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d9045190cfef',
  );

  // Indirizzo mainnet blake2b valido (vettore usato anche nei test wallet).
  const validAddress = 'bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq';

  setUp(() {
    service = LightningServiceMock();
  });

  Widget buildScreen({int? availableSats = 25000}) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: LightningOnchainSendScreen(
          lightningService: service,
          availableSats: availableSats,
        ),
      );

  testWidgets('indirizzo non valido → errore, nessuna chiamata',
      (tester) async {
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'not-an-address');
    await tester.enterText(find.byType(TextField).at(1), '1000');
    await tester.tap(find.text('Confirm send'));
    await tester.pump();

    expect(find.text('Invalid blake2b address'), findsOneWidget);
  });

  testWidgets('importo oltre il saldo → errore', (tester) async {
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, validAddress);
    await tester.enterText(find.byType(TextField).at(1), '999999');
    await tester.tap(find.text('Confirm send'));
    await tester.pump();

    expect(find.text('Insufficient on-chain funds'), findsOneWidget);
  });

  testWidgets('invio confermato → successo con txid', (tester) async {
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, validAddress);
    await tester.enterText(find.byType(TextField).at(1), '1000');
    await tester.tap(find.text('Confirm send'));
    await tester.pumpAndSettle();

    // Dialog di conferma forte → conferma.
    expect(find.text('Confirm on-chain send?'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('Transaction sent'), findsOneWidget);
  });

  testWidgets('stime fee visibili dal nodo (mock)', (tester) async {
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.textContaining('sat/vB'), findsWidgets);
  });

  testWidgets('fee di rete: livelli con lo STESSO sat/vB restano selezionabili',
      (tester) async {
    // Caso reale (segnalato il 15/09): `feerates` può restituire lo stesso
    // sat/vB su più livelli — con la selezione sul valore tutti i chip
    // risultavano selezionati e non cliccabili.
    service = LightningServiceMock(
      onchainFeesOverride: const LightningOnchainFees(
        minSatVb: 1,
        economicalSatVb: 1,
        prioritySatVb: 1,
      ),
    );
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    final chips = find.byType(ChoiceChip);
    expect(chips, findsNWidgets(3));
    // Default: solo il livello economico, NON tutti e tre.
    expect(tester.widget<ChoiceChip>(chips.at(0)).selected, isFalse);
    expect(tester.widget<ChoiceChip>(chips.at(1)).selected, isTrue);
    expect(tester.widget<ChoiceChip>(chips.at(2)).selected, isFalse);

    // Cliccando il prioritario la selezione si sposta davvero.
    await tester.tap(chips.at(2));
    await tester.pumpAndSettle();

    expect(tester.widget<ChoiceChip>(chips.at(0)).selected, isFalse);
    expect(tester.widget<ChoiceChip>(chips.at(1)).selected, isFalse);
    expect(tester.widget<ChoiceChip>(chips.at(2)).selected, isTrue);
  });

  testWidgets('fee di rete: selezione tra livelli diversi', (tester) async {
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    final chips = find.byType(ChoiceChip);
    // Default economico (mock: 1/2/4 sat/vB).
    expect(tester.widget<ChoiceChip>(chips.at(1)).selected, isTrue);

    await tester.tap(chips.at(0));
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(chips.at(0)).selected, isTrue);
    expect(tester.widget<ChoiceChip>(chips.at(1)).selected, isFalse);
  });
}
