import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/core/models/transaction_record.dart';
import 'package:btc_blake2b_wallet/features/wallet/presentation/widgets/transaction_history_section.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

TransactionRecord _tx({
  String txid = 'tx123',
  TxDirection direction = TxDirection.incoming,
  int amountSats = 100000,
  int? feeSats = 500,
  bool confirmed = true,
  int confirmations = 3,
  int? blockHeight = 149987,
  DateTime? timestamp,
}) {
  return TransactionRecord(
    txid: txid,
    direction: direction,
    amountSats: amountSats,
    feeSats: feeSats,
    confirmations: confirmations,
    blockHeight: blockHeight,
    timestamp: timestamp ?? DateTime(2026, 8, 27, 10, 30),
  );
}

void main() {
  testWidgets('mostra spinner durante il caricamento', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const TransactionHistorySection(
          transactions: [],
          isLoading: true,
        ),
      ),
    );
    await tester.tap(find.text('Transactions'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('mostra empty state quando non ci sono transazioni',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const TransactionHistorySection(
          transactions: [],
          isLoading: false,
        ),
      ),
    );
    await tester.tap(find.text('Transactions'));
    await tester.pump();

    expect(find.text('No transactions'), findsOneWidget);
  });

  testWidgets('mostra errore con retry', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      _wrap(
        TransactionHistorySection(
          transactions: const [],
          isLoading: false,
          error: 'boom',
          onRetry: () => retried = true,
        ),
      ),
    );
    await tester.tap(find.text('Transactions'));
    await tester.pump();

    expect(find.text('Failed to load transactions'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  testWidgets('rende righe in/out con segno e colore', (tester) async {
    final txs = [
      _tx(direction: TxDirection.incoming, amountSats: 50000),
      _tx(
        txid: 'tx456',
        direction: TxDirection.outgoing,
        amountSats: 20000,
      ),
    ];
    await tester.pumpWidget(
      _wrap(
        TransactionHistorySection(transactions: txs, isLoading: false),
      ),
    );
    await tester.tap(find.text('Transactions'));
    await tester.pump();

    // In entrata: "Received · +0.00050000 BTC"
    expect(find.textContaining('Received'), findsOneWidget);
    expect(find.textContaining('+0.00050000'), findsOneWidget);
    // In uscita: "Sent · -0.00020000 BTC"
    expect(find.textContaining('Sent'), findsOneWidget);
    expect(find.textContaining('-0.00020000'), findsOneWidget);
  });

  testWidgets('mostra badge Pending per tx non confermate', (tester) async {
    final txs = [
      _tx(txid: 'txpending', confirmed: false, confirmations: 0),
    ];
    await tester.pumpWidget(
      _wrap(
        TransactionHistorySection(transactions: txs, isLoading: false),
      ),
    );
    await tester.tap(find.text('Transactions'));
    await tester.pump();

    expect(find.text('Pending'), findsOneWidget);
  });

  testWidgets('tap su riga apre dialog con dettagli', (tester) async {
    final txs = [_tx()];
    await tester.pumpWidget(
      _wrap(
        TransactionHistorySection(transactions: txs, isLoading: false),
      ),
    );
    await tester.tap(find.text('Transactions'));
    await tester.pump();

    // // PERCHÉ: il txid non è visibile nella riga (solo nel dialog) —
    // il tap va sulla ListTile, non sul testo del txid.
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    expect(find.text('Transaction details'), findsOneWidget);
    expect(find.text('tx123'), findsOneWidget);
    expect(find.text('Fee'), findsOneWidget);
    expect(find.text('500 sat'), findsOneWidget);
  });

  testWidgets('tx outgoing pending bumpabile: azione Aumenta fee nel dettaglio',
      (tester) async {
    final txs = [
      _tx(
        txid: 'txbump',
        direction: TxDirection.outgoing,
        amountSats: 20000,
        confirmations: 0,
        blockHeight: null,
        timestamp: null,
      ),
    ];
    TransactionRecord? bumped;
    await tester.pumpWidget(
      _wrap(
        TransactionHistorySection(
          transactions: txs,
          isLoading: false,
          isBumpable: (tx) => tx.txid == 'txbump',
          onBumpFee: (tx) async => bumped = tx,
        ),
      ),
    );
    await tester.tap(find.text('Transactions'));
    await tester.pump();
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    // Dialog dettaglio con l'azione RBF.
    expect(find.text('Transaction details'), findsOneWidget);
    expect(find.text('Increase fee'), findsOneWidget);

    await tester.tap(find.text('Increase fee'));
    await tester.pumpAndSettle();

    // // PERCHÉ: il dettaglio si chiude PRIMA di avviare il flusso bump
    // (evita dialog sovrapposti) e la callback riceve la transazione.
    expect(find.text('Transaction details'), findsNothing);
    expect(bumped?.txid, 'txbump');
  });

  testWidgets('nessuna azione Aumenta fee se predicato falso', (tester) async {
    final txs = [
      _tx(
        txid: 'txno',
        direction: TxDirection.outgoing,
        amountSats: 20000,
        confirmations: 0,
        blockHeight: null,
        timestamp: null,
      ),
    ];
    await tester.pumpWidget(
      _wrap(
        TransactionHistorySection(
          transactions: txs,
          isLoading: false,
          isBumpable: (_) => false,
          onBumpFee: (_) async {},
        ),
      ),
    );
    await tester.tap(find.text('Transactions'));
    await tester.pump();
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    expect(find.text('Transaction details'), findsOneWidget);
    expect(find.text('Increase fee'), findsNothing);
  });

  testWidgets('nessuna azione Aumenta fee senza callback (default)',
      (tester) async {
    final txs = [
      _tx(
        txid: 'txdef',
        direction: TxDirection.outgoing,
        amountSats: 20000,
        confirmations: 0,
        blockHeight: null,
        timestamp: null,
      ),
    ];
    await tester.pumpWidget(
      _wrap(
        TransactionHistorySection(transactions: txs, isLoading: false),
      ),
    );
    await tester.tap(find.text('Transactions'));
    await tester.pump();
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    expect(find.text('Increase fee'), findsNothing);
  });
}
