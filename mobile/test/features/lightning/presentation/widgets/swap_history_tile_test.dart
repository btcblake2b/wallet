import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:btc_blake2b_wallet/core/services/swap/swap_models.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/widgets/swap_history_tile.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

/// La riga dello storico deve rendere riconoscibile una transazione via
/// provider: importo, data e stato (P9, 07/10/2026).
void main() {
  SwapSession session({
    required SwapClientState state,
    int fundingAmountSats = 5251,
    int? amountSats = 5001,
  }) =>
      SwapSession(
        swapId: '76794282bb68bbf0e48ce2d9eb949cb1',
        invoice: 'lnbc50010n1p426phes',
        paymentHashHex: '64d69bcbfb12c2200947a52c63e5aec7'
            'f6ba4fc96cebd3d4f6dd14adf728a039',
        fundingAmountSats: fundingAmountSats,
        amountSats: amountSats,
        cltvHeight: 972919,
        fundingDeadlineHeight: 972911,
        claimPubkeyHex: '0291d1fca1a250bfd426b3276fa1a4001'
            '8d4a0bf3fb46b8e748c5892066d18b296',
        refundPubkeyHex: '03b3c027ebd87279243821556d9e308f1'
            '398b7746809d131ed3e571355af98913a',
        refundKeyIndex: 1,
        htlcAddress: 'bc1qnv256rfn79vy2phzm2kwa5ku3wc0yvwgwqzzvxwa6qahruxx502qnj8c98',
        witnessScriptHex: '63a82064d69bcb',
        providerPubkey: '91d1fca1a250bfd426b3276fa1a40018d4a0b'
            'f3fb46b8e748c5892066d18b296',
        relays: const ['wss://relay.primal.net'],
        walletId: 'w1',
        walletName: 'Wallet 1',
        state: state,
        createdAt: 1789724469,
        updatedAt: 1789725309,
        fundingTxid:
            'a539bc0431d1bc0a86d416677f0197fd4688695863eca9eb49704343bc818605',
        fundingVout: 0,
      );

  Widget wrap(SwapSession s, {VoidCallback? onTap}) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: SwapHistoryTile(
            session: s,
            stateLabel: 'Payment failed — funds recoverable',
            onTap: onTap,
          ),
        ),
      );

  testWidgets('mostra importo bloccato, data e stato', (tester) async {
    await tester.pumpWidget(wrap(session(state: SwapClientState.paymentFailed)));

    // PERCHÉ i formatter qui nel test: la data è in fuso LOCALE (la CI può
    // girare in UTC) — si confronta con lo stesso formatter della tile.
    final expectedDate = DateFormat('dd/MM/yyyy · HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(1789724469 * 1000),
    );
    // Importo mostrato = invoice (5.001 sat), NON il totale bloccato (5.251).
    expect(
      find.text('${NumberFormat.decimalPattern().format(5001)} sat'),
      findsOneWidget,
    );
    expect(
      find.text('$expectedDate · Payment failed — funds recoverable'),
      findsOneWidget,
    );
  });

  testWidgets('senza importo invoice (sessioni vecchie) usa il totale bloccato',
      (tester) async {
    await tester.pumpWidget(
      wrap(session(state: SwapClientState.completed, amountSats: null)),
    );

    expect(
      find.text('${NumberFormat.decimalPattern().format(5251)} sat'),
      findsOneWidget,
    );
  });

  testWidgets('tap → callback di apertura dettaglio', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      wrap(session(state: SwapClientState.completed), onTap: () => tapped++),
    );

    await tester.tap(find.byType(SwapHistoryTile));
    await tester.pump();

    expect(tapped, 1);
  });

  testWidgets('stati diversi → icone diverse', (tester) async {
    await tester.pumpWidget(wrap(session(state: SwapClientState.completed)));
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

    await tester.pumpWidget(wrap(session(state: SwapClientState.paymentFailed)));
    expect(find.byIcon(Icons.error_outline), findsOneWidget);

    await tester.pumpWidget(wrap(session(state: SwapClientState.refunded)));
    expect(find.byIcon(Icons.undo), findsOneWidget);
  });
}
