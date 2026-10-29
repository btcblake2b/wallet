import 'package:bech32/bech32.dart';
import 'package:btc_blake2b_wallet/core/models/lightning_connection.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_service_mock.dart';
import 'package:btc_blake2b_wallet/core/utils/bolt12_offer_utils.dart';
import 'package:btc_blake2b_wallet/core/utils/lightning_invoice_utils.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/lightning_receive_screen.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/lightning_send_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// BOLT12 (offers): ricevere con un codice riutilizzabile e pagare un'offerta.
///
/// // PERCHÉ: è la metà "ricevi senza fattura" e la metà "paga un'offerta" —
/// // la seconda ha un vincolo di sicurezza: un'offerta senza importo NON deve
/// // poter partire senza che l'utente lo abbia dichiarato.
void main() {
  late LightningServiceMock service;

  const connection = LightningConnection(
    walletPubkey:
        'f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9',
    relays: ['wss://relay.test'],
    secretHex:
        'b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d9045190cfef',
  );

  const offer = 'lno1qgsqvgnwgcg35z6ee2h3yczraddm72xrfua9uve2rlrm9deu7xyfzrc';

  /// Offerta con importo fisso di [amountMsat] (TLV `offer_amount`).
  String offerWithAmount(int amountMsat) {
    final amount = <int>[
      if (amountMsat < 0xfd)
        amountMsat
      else if (amountMsat <= 0xffff) ...[
        0xfd,
        (amountMsat >> 8) & 0xff,
        amountMsat & 0xff,
      ] else ...[
        0xfe,
        (amountMsat >> 24) & 0xff,
        (amountMsat >> 16) & 0xff,
        (amountMsat >> 8) & 0xff,
        amountMsat & 0xff,
      ],
    ];
    final bytes = <int>[8, amount.length, ...amount];
    final groups = <int>[];
    var acc = 0;
    var bits = 0;
    for (final byte in bytes) {
      acc = (acc << 8) | byte;
      bits += 8;
      while (bits >= 5) {
        bits -= 5;
        groups.add((acc >> bits) & 31);
      }
    }
    if (bits > 0) groups.add((acc << (5 - bits)) & 31);
    return bech32.encode(Bech32('lno', groups), 2048);
  }

  Widget wrapReceive() => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: LightningReceiveScreen(lightningService: service),
      );

  Widget wrapSend() => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: LightningSendScreen(lightningService: service),
      );

  /// Invio aperto SOPRA una rotta: dopo il pagamento la schermata fa pop e
  /// l'avviso di esito resta visibile sulla schermata sottostante.
  Widget wrapSendPushed() => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        LightningSendScreen(lightningService: service),
                  ),
                ),
                child: const Text('open-send'),
              ),
            ),
          ),
        ),
      );

  group('riconoscimento del codice', () {
    test('lno1 è un\'offerta, non una fattura', () {
      expect(isLightningOffer(offer), isTrue);
      expect(isValidLightningInvoice(offer), isFalse);
      expect(isLightningOffer('lnbc1test'), isFalse);
      expect(isLightningOffer('lightning:$offer'), isTrue);
    });
  });

  group('ricezione', () {
    testWidgets('modalità offerta → codice mostrato, nessun polling',
        (tester) async {
      service = LightningServiceMock();
      await tester.runAsync(() => service.connect(connection));
      await tester.pumpWidget(wrapReceive());

      await tester.tap(find.text('Reusable code'));
      await tester.pumpAndSettle();

      // Importo facoltativo: nessun errore se resta vuoto.
      await tester.tap(find.text('Create invoice'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(service.lastOffer, isNotNull);
      expect(service.lastOffer!.amountMsat, isNull);
      expect(find.text('Reusable payment code'), findsOneWidget);
    });

    testWidgets('modalità offerta con importo → importo passato al nodo',
        (tester) async {
      service = LightningServiceMock();
      await tester.runAsync(() => service.connect(connection));
      await tester.pumpWidget(wrapReceive());

      await tester.tap(find.text('Reusable code'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '5000');
      await tester.tap(find.text('Create invoice'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(service.lastOffer!.amountMsat, 5000000);
    });
  });

  group('invio', () {
    testWidgets('un\'offerta mostra il campo importo', (tester) async {
      service = LightningServiceMock();
      await tester.runAsync(() => service.connect(connection));
      await tester.pumpWidget(wrapSend());

      expect(find.text('Amount (sat)'), findsNothing);
      await tester.enterText(find.byType(TextField).first, offer);
      await tester.pumpAndSettle();
      expect(find.text('Amount (sat)'), findsOneWidget);
    });

    testWidgets('offerta senza importo → nessun pagamento', (tester) async {
      service = LightningServiceMock();
      await tester.runAsync(() => service.connect(connection));
      await tester.pumpWidget(wrapSend());

      await tester.enterText(find.byType(TextField).first, offer);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Pay offer'));
      await tester.pumpAndSettle();

      expect(
        find.text('Enter the amount to pay this offer'),
        findsOneWidget,
      );
      // Nessun dialog di conferma: il pagamento non è mai partito.
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('offerta con importo → pagata con amount_msat', (tester) async {
      service = LightningServiceMock();
      await tester.runAsync(() => service.connect(connection));
      await tester.pumpWidget(wrapSend());

      await tester.enterText(find.byType(TextField).first, offer);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '2000');
      await tester.tap(find.widgetWithText(FilledButton, 'Pay offer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(service.lastPayAmountMsat, 2000000);
    });

    testWidgets('offerta con importo fisso → campo importo assente',
        (tester) async {
      final fixed = offerWithAmount(21000000);
      // La fixture deve davvero portare l'importo, altrimenti il test è vuoto.
      expect(bolt12OfferAmountMsat(fixed), 21000000);

      service = LightningServiceMock();
      await tester.runAsync(() => service.connect(connection));
      await tester.pumpWidget(wrapSend());

      await tester.enterText(find.byType(TextField).first, fixed);
      await tester.pumpAndSettle();

      expect(find.text('Amount (sat)'), findsNothing);
      expect(find.text('Offer amount: 21,000 sat'), findsOneWidget);
    });

    testWidgets('offerta con importo fisso → pagata senza amount_msat',
        (tester) async {
      service = LightningServiceMock();
      await tester.runAsync(() => service.connect(connection));
      await tester.pumpWidget(wrapSendPushed());
      await tester.pumpAndSettle();
      await tester.tap(find.text('open-send'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).first,
        offerWithAmount(21000000),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Pay offer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      // L'importo lo legge il nodo dall'offerta: non va inviato.
      expect(service.lastPayAmountMsat, isNull);
      expect(find.text('Payment sent'), findsOneWidget);
    });
  });
}
