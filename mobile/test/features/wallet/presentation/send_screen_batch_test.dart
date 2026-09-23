import 'package:bech32/bech32.dart' as bech32;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:btc_blake2b_wallet/core/models/wallet_record.dart';
import 'package:btc_blake2b_wallet/core/services/biometric_service.dart';
import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';
import 'package:btc_blake2b_wallet/core/services/wallet_repository.dart';
import 'package:btc_blake2b_wallet/features/wallet/presentation/send_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

class MockWalletRepository extends Mock implements WalletRepository {}

class MockBitcoinService extends Mock implements BitcoinService {}

class MockBiometricService extends Mock implements BiometricService {}

/// Widget test della modalità "più destinatari" (P3).
///
/// // PERCHÉ: la logica di insieme (minimo 2, dust per riga, cap 20) vive solo
/// // nella UI — i test di servizio non la coprono.
void main() {
  /// Indirizzo bech32 mainnet valido (checksum corretto).
  String validAddress(int seed) => bech32.segwit.encode(
    bech32.Segwit('bc', 0, List<int>.generate(20, (i) => (i + seed) % 256)),
  );

  Future<void> pumpSendScreen(WidgetTester tester) async {
    final wallet = WalletRecord(
      walletId: 'test_id',
      encryptedSeed: 'test_seed',
      publicAddress: 'test_address',
      deviceId: 'test_device',
      createdAt: DateTime(2024, 1, 1),
    );
    final bitcoinService = MockBitcoinService();
    when(() => bitcoinService.fetchFeeEstimates()).thenAnswer(
      (_) async => FeeEstimates(lowSatVb: 1, normalSatVb: 1, highSatVb: 2),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SendScreen(
          wallet: wallet,
          walletRepository: MockWalletRepository(),
          bitcoinService: bitcoinService,
          biometricService: MockBiometricService(),
          balanceSats: 1000000,
          initialUtxos: [
            UtxoInfo(txid: 'txid1', vout: 0, valueSat: 1000000),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('il toggle apre la lista destinatari e nasconde i campi singoli',
      (tester) async {
    await pumpSendScreen(tester);

    // In modalità singola: un solo campo indirizzo/importo.
    expect(find.text('Add recipient'), findsNothing);

    await tester.tap(find.text('Multiple recipients'));
    await tester.pumpAndSettle();

    // In batch: riga 1 + pulsante di aggiunta, e nessun campo singolo.
    expect(find.text('Add recipient'), findsOneWidget);
    expect(find.text('1/20'), findsOneWidget);
  });

  testWidgets('aggiungi destinatario alza il contatore', (tester) async {
    await pumpSendScreen(tester);
    await tester.tap(find.text('Multiple recipients'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add recipient'));
    await tester.pumpAndSettle();

    expect(find.text('2/20'), findsOneWidget);
    expect(find.text('Recipient 2'), findsOneWidget);
  });

  testWidgets('rimuovi è attivo solo da 2 righe in poi', (tester) async {
    await pumpSendScreen(tester);
    await tester.tap(find.text('Multiple recipients'));
    await tester.pumpAndSettle();

    // Con una sola riga il cestino è disabilitato.
    final removeBtn = find.ancestor(
      of: find.byIcon(Icons.remove_circle_outline),
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(removeBtn).onPressed, isNull);

    await tester.tap(find.text('Add recipient'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<IconButton>(
            find
                .ancestor(
                  of: find.byIcon(Icons.remove_circle_outline),
                  matching: find.byType(IconButton),
                )
                .first,
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('il cap di 20 destinatari disabilita "aggiungi"', (tester) async {
    await pumpSendScreen(tester);
    await tester.tap(find.text('Multiple recipients'));
    await tester.pumpAndSettle();

    for (var i = 1; i < 20; i++) {
      await tester.ensureVisible(find.text('Add recipient'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add recipient'));
      await tester.pumpAndSettle();
    }

    expect(find.text('20/20'), findsOneWidget);
    expect(find.text('Maximum 20 recipients'), findsOneWidget);
    final addBtn = find.ancestor(
      of: find.text('Maximum 20 recipients'),
      matching: find.byType(TextButton),
    );
    expect(tester.widget<TextButton>(addBtn).onPressed, isNull);
  });

  testWidgets('un solo destinatario in batch → errore "servono 2"',
      (tester) async {
    await pumpSendScreen(tester);
    await tester.tap(find.text('Multiple recipients'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), validAddress(1));
    await tester.enterText(fields.at(1), '0.0005');
    await tester.pump();

    await tester.ensureVisible(find.widgetWithIcon(FilledButton, Icons.send));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithIcon(FilledButton, Icons.send));
    await tester.pumpAndSettle();

    expect(
      find.text('Add at least 2 recipients to send a batch'),
      findsOneWidget,
    );
  });

  testWidgets('importo sotto dust → errore del validator di riga',
      (tester) async {
    await pumpSendScreen(tester);
    await tester.tap(find.text('Multiple recipients'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), validAddress(1));
    await tester.enterText(fields.at(1), '0.000001'); // 100 sat: polvere
    await tester.pump();

    await tester.ensureVisible(find.widgetWithIcon(FilledButton, Icons.send));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithIcon(FilledButton, Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Minimum 546 sat per recipient'), findsOneWidget);
  });
}
