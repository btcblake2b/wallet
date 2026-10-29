import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/core/services/swap/swap_models.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/lightning_swap_detail_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

/// Dettaglio di una transazione dello storico swap (P9, 07/10/2026):
/// dati leggibili/copiabili e — se lo swap è fallito — il recupero fondi.
void main() {
  const fundingTxid =
      'a539bc0431d1bc0a86d416677f0197fd4688695863eca9eb49704343bc818605';
  const htlcAddress =
      'bc1qnv256rfn79vy2phzm2kwa5ku3wc0yvwgwqzzvxwa6qahruxx502qnj8c98';

  SwapSession session({
    SwapClientState state = SwapClientState.paymentFailed,
    int? amountSats = 5001,
    String? claimTxid,
    String? errorCode = 'PAYMENT_FAILED',
    String? errorMessage = 'lightning-cli pay fallito (exit 1): …',
  }) =>
      SwapSession(
        swapId: '76794282bb68bbf0e48ce2d9eb949cb1',
        invoice: 'lnbc50010n1p426phesp5w4qwljzhdj8lyd5mtxpeezt49zu3w3224x',
        paymentHashHex: '64d69bcbfb12c2200947a52c63e5aec7'
            'f6ba4fc96cebd3d4f6dd14adf728a039',
        fundingAmountSats: 5251,
        amountSats: amountSats,
        cltvHeight: 972919,
        fundingDeadlineHeight: 972911,
        claimPubkeyHex: '0291d1fca1a250bfd426b3276fa1a4001'
            '8d4a0bf3fb46b8e748c5892066d18b296',
        refundPubkeyHex: '03b3c027ebd87279243821556d9e308f1'
            '398b7746809d131ed3e571355af98913a',
        refundKeyIndex: 1,
        htlcAddress: htlcAddress,
        witnessScriptHex: '63a82064d69bcb',
        providerPubkey: '91d1fca1a250bfd426b3276fa1a40018d4a0b'
            'f3fb46b8e748c5892066d18b296',
        relays: const ['wss://relay.primal.net'],
        walletId: 'w1',
        walletName: 'Wallet 1',
        state: state,
        createdAt: 1789724469,
        updatedAt: 1789725309,
        fundingTxid: fundingTxid,
        fundingVout: 0,
        claimTxid: claimTxid,
        errorCode: errorCode,
        errorMessage: errorMessage,
      );

  Widget wrap(
    SwapSession s, {
    Future<String> Function()? onRefund,
  }) =>
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: LightningSwapDetailScreen(
          session: s,
          recoveryBlob: 'swaprecover1.eyJzd2FwX2lkIjoiNzY3OTQyODIifQ==',
          onRefund: onRefund,
        ),
      );

  testWidgets('mostra riepilogo, dati on-chain e protocollo', (tester) async {
    await tester.pumpWidget(wrap(session()));

    expect(find.text('Swap details'), findsOneWidget);
    // Importo invoice in evidenza + totale bloccato nella riga sotto.
    expect(find.text('5,001 sat'), findsNWidgets(2));
    expect(find.text('5,251 sat'), findsOneWidget);
    expect(find.text('Wallet 1'), findsOneWidget);
    // Valori abbreviati (12…8) ma copiabili interi.
    expect(find.textContaining('bc1qnv256rfn'), findsOneWidget);
    expect(find.textContaining('a539bc0431d1'), findsOneWidget);
    expect(find.text('Payment hash'), findsOneWidget);
    expect(find.text('Provider'), findsOneWidget);
  });

  testWidgets('senza importo invoice resta il solo totale bloccato',
      (tester) async {
    await tester.pumpWidget(wrap(session(amountSats: null)));

    expect(find.text('5,251 sat'), findsNWidgets(2));
    expect(find.text('5,001 sat'), findsNothing);
  });

  testWidgets('errore del provider: motivo localizzato, non il testo grezzo',
      (tester) async {
    await tester.pumpWidget(wrap(session()));

    // PERCHÉ (incidente 18/09/2026): il messaggio grezzo troncato faceva
    // credere che il pagamento fosse avvenuto — ora vince il testo localizzato.
    expect(
      find.textContaining('could not pay this invoice'),
      findsOneWidget,
    );
    expect(find.textContaining('lightning-cli pay fallito'), findsNothing);
  });

  testWidgets('refund disponibile solo per stati rimborsabili', (tester) async {
    // paymentFailed + callback → bottone presente.
    await tester.pumpWidget(
      wrap(session(), onRefund: () async => fundingTxid),
    );
    expect(find.text('Recover funds (refund)'), findsOneWidget);

    // completed → nessun bottone anche col callback.
    await tester.pumpWidget(
      wrap(session(state: SwapClientState.completed), onRefund: () async => ''),
    );
    await tester.pumpAndSettle();
    expect(find.text('Recover funds (refund)'), findsNothing);
  });

  testWidgets('refund riuscito: snackbar localizzata e pop(true)',
      (tester) async {
    final s = session();
    bool? popResult;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  popResult = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => LightningSwapDetailScreen(
                        session: s,
                        recoveryBlob: 'swaprecover1.x',
                        onRefund: () async => fundingTxid,
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recover funds (refund)'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Refund sent: a539bc0431d1…'), findsOneWidget);
    expect(popResult, isTrue);
  });

  testWidgets('refund troppo presto: messaggio dedicato col blocco CLTV',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        session(),
        onRefund: () async => throw const SwapException(
          'REFUND_TOO_EARLY',
          'troppo presto',
        ),
      ),
    );

    await tester.tap(find.text('Recover funds (refund)'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('opens from block 972919'),
      findsOneWidget,
    );
  });

  testWidgets('copia del blob di recupero negli appunti', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await tester.pumpWidget(wrap(session()));
    // PERCHÉ lo scroll: la card di recupero è in fondo alla ListView (non
    // costruita finché non entra nel viewport del test).
    await tester.scrollUntilVisible(
      find.text('Copy recovery blob'),
      300,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy recovery blob'));
    await tester.pumpAndSettle();

    expect(copied, 'swaprecover1.eyJzd2FwX2lkIjoiNzY3OTQyODIifQ==');
    expect(find.text('Recovery blob copied'), findsOneWidget);
  });
}
