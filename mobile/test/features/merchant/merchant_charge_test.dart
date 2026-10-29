import 'package:btc_blake2b_wallet/core/models/lightning_connection.dart';
import 'package:btc_blake2b_wallet/core/models/wallet_record.dart';
import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_service_mock.dart';
import 'package:btc_blake2b_wallet/features/merchant/presentation/merchant_charge_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MockBitcoinService extends Mock implements BitcoinService {}

void main() {
  late MockBitcoinService bitcoinService;

  final wallet = WalletRecord(
    walletId: 'shop',
    encryptedSeed: 'enc',
    publicAddress: 'bc1qshopaddress0000000000000000000000',
    deviceId: 'dev',
    createdAt: DateTime.utc(2026, 10, 27),
    seedBackupConfirmed: true,
  );

  const connection = LightningConnection(
    walletPubkey:
        'f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9',
    relays: ['wss://relay.test'],
    secretHex:
        'b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d9045190cfef',
  );

  setUp(() {
    bitcoinService = MockBitcoinService();
    when(() => bitcoinService.fetchAddressInfo(any()))
        .thenAnswer((_) async => {'balance': 0, 'tx_count': 0});
  });

  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: child,
      );

  testWidgets('on-chain: il QR contiene l\'importo (BIP21)', (tester) async {
    await tester.pumpWidget(
      wrap(
        MerchantChargeScreen(wallet: wallet, bitcoinService: bitcoinService),
      ),
    );
    await tester.pump();

    // Senza nodo Lightning lo dice subito, senza far scoprire il limite a metà.
    expect(find.textContaining('No Lightning node connected'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '12500');
    await tester.enterText(find.byType(TextField).last, 'Caffè');
    await tester.tap(find.text('Create payment request'));
    // PERCHÉ niente pumpAndSettle: il QR genera un PNG con API async del
    // motore che non si "settla" sotto clock fake (come nel test Ricevi).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Il QR è disegnato dagli stessi byte del testo selezionabile qui sotto:
    // verificare il testo è la prova che l'IMPORTO è dentro la richiesta.
    expect(
      find.text(
        'bitcoin:bc1qshopaddress0000000000000000000000?amount=0.000125&label=Caff%C3%A8',
      ),
      findsOneWidget,
    );
    expect(find.byType(QrImageView), findsOneWidget);
    // Il testo selezionabile è la stessa stringa del QR: copia manuale e
    // controllo automatico guardano lo stesso dato.
    expect(
      find.textContaining('bc1qshopaddress0000000000000000000000'),
      findsWidgets,
    );
    expect(find.text('Waiting for payment…'), findsOneWidget);
  });

  testWidgets('importo non valido → errore, nessuna richiesta', (tester) async {
    await tester.pumpWidget(
      wrap(
        MerchantChargeScreen(wallet: wallet, bitcoinService: bitcoinService),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Create payment request'));
    await tester.pump();

    expect(find.text('Enter an amount greater than zero.'), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);
  });

  testWidgets('on-chain: il movimento sull\'indirizzo segna «pagato»',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        MerchantChargeScreen(
          wallet: wallet,
          bitcoinService: bitcoinService,
          pollInterval: const Duration(seconds: 1),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, '5000');
    await tester.tap(find.text('Create payment request'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Il cliente paga: l'explorer ora riporta un movimento.
    when(() => bitcoinService.fetchAddressInfo(any()))
        .thenAnswer((_) async => {'balance': 5000, 'tx_count': 1});

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Payment received'), findsOneWidget);
  });

  testWidgets('on-chain: saldo PREESISTENTE non conta come pagamento',
      (tester) async {
    // PERCHÉ: l'esercente usa lo stesso indirizzo da mesi — senza baseline
    // l'app direbbe «pagato» appena creata la richiesta.
    when(() => bitcoinService.fetchAddressInfo(any()))
        .thenAnswer((_) async => {'balance': 42000, 'tx_count': 7});

    await tester.pumpWidget(
      wrap(
        MerchantChargeScreen(
          wallet: wallet,
          bitcoinService: bitcoinService,
          pollInterval: const Duration(seconds: 1),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, '5000');
    await tester.tap(find.text('Create payment request'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Payment received'), findsNothing);
  });

  testWidgets('Lightning collegato: fattura con importo e pagamento rilevato',
      (tester) async {
    final lightning = LightningServiceMock();
    await tester.runAsync(() => lightning.connect(connection));

    await tester.pumpWidget(
      wrap(
        MerchantChargeScreen(
          wallet: wallet,
          bitcoinService: bitcoinService,
          lightningService: lightning,
          pollInterval: const Duration(seconds: 1),
        ),
      ),
    );
    await tester.pump();

    // Con il nodo collegato la modalità predefinita è Lightning e il selettore
    // on-chain/off-chain è disponibile.
    expect(find.text('Lightning'), findsOneWidget);
    expect(find.text('On-chain'), findsOneWidget);
    expect(find.textContaining('No Lightning node connected'), findsNothing);

    await tester.enterText(find.byType(TextField).first, '2100');
    await tester.tap(find.text('Create payment request'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Lightning invoice'), findsOneWidget);

    await tester.runAsync(() async {
      final invoices = await lightning.listInvoices(limit: 1);
      lightning.markInvoicePaid(invoices.first.paymentHash);
    });
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Payment received'), findsOneWidget);
  });
}
