import 'package:btc_blake2b_wallet/core/models/wallet_record.dart';
import 'package:btc_blake2b_wallet/features/merchant/presentation/merchant_convert_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final wallet = WalletRecord(
    walletId: 'shop',
    encryptedSeed: 'enc',
    publicAddress: 'bc1qshopaddress0000000000000000000000',
    deviceId: 'dev',
    createdAt: DateTime.utc(2026, 10, 27),
    name: 'Negozio',
  );

  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: child,
      );

  testWidgets('mostra l\'indirizzo da copiare e i servizi di conversione',
      (tester) async {
    await tester.pumpWidget(wrap(MerchantConvertScreen(wallet: wallet)));
    await tester.pump();

    expect(find.text('Convert to BTC'), findsOneWidget);
    expect(find.text('Negozio'), findsOneWidget);
    expect(
      find.text('bc1qshopaddress0000000000000000000000'),
      findsOneWidget,
    );
    expect(find.text('Paperclip Bridge (beta)'), findsOneWidget);
    expect(find.text('Lightning Fork Swap'), findsOneWidget);
  });

  testWidgets('dice che la conversione NON è nostra (onestà)', (tester) async {
    await tester.pumpWidget(wrap(MerchantConvertScreen(wallet: wallet)));
    await tester.pump();

    // Il testo deve negare esplicitamente custodia e cambio: è il vincolo
    // legale (CASP/OAM) scritto dove l'utente legge.
    expect(find.textContaining('does not do it'), findsOneWidget);
    expect(find.textContaining('no custody'), findsOneWidget);
    // E deve avvisare di non consegnare la seed.
    expect(find.textContaining('seed phrase'), findsOneWidget);
    // L'avviso finale è sotto la piega: si scorre (ListView) prima di cercarlo.
    await tester.scrollUntilVisible(
      find.text('Before you convert'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Before you convert'), findsOneWidget);
  });

  testWidgets('wallet senza nome → etichetta neutra', (tester) async {
    final unnamed = wallet.copyWith(name: '');
    await tester.pumpWidget(wrap(MerchantConvertScreen(wallet: unnamed)));
    await tester.pump();

    expect(find.text('Wallet'), findsOneWidget);
  });
}
