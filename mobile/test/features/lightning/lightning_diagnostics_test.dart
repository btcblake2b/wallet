import 'package:btc_blake2b_wallet/core/models/lightning_connection.dart';
import 'package:btc_blake2b_wallet/core/models/lightning_node_stats.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_service.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_service_mock.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/lightning_diagnostics_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Servizio che fallisce le statistiche (bkpr non disponibile sul nodo).
class _FailingStatsService extends LightningServiceMock {
  @override
  Future<LightningNodeStats> getNodeStats() async {
    throw const LightningException('OTHER', 'bkpr non disponibile');
  }
}

void main() {
  // PERCHÉ: la schermata carica in initState — il mock deve essere CONNESSO
  // prima del montaggio, altrimenti il test verifica la pagina d'errore.
  const connection = LightningConnection(
    walletPubkey:
        'f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9',
    relays: ['wss://relay.test'],
    secretHex:
        'b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d9045190cfef',
  );

  Widget wrap(LightningServiceMock service) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: LightningDiagnosticsScreen(lightningService: service),
      );

  testWidgets('economia e plugin del nodo', (tester) async {
    final service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    expect(find.text('Diagnostics'), findsOneWidget);
    expect(find.text('Economy'), findsOneWidget);
    expect(find.text('Net'), findsOneWidget);
    expect(find.text('34.382 sat'), findsOneWidget);
    // Tag noti tradotti, con numero di voci.
    expect(find.text('Deposits'), findsOneWidget);
    expect(find.text('2 entries'), findsOneWidget);
    expect(find.text('Invoices'), findsOneWidget);
    // Due tag hanno una sola voce ciascuno (invoice, onchain_fee).
    expect(find.text('1 entry'), findsNWidgets(2));
    expect(find.text('On-chain fees'), findsOneWidget);
    // La fonte è dichiarata: il numero non è magia.
    expect(
        find.text("From the node's accounting (bookkeeper)"), findsOneWidget,);
    // Plugin: nome corto + il non attivo è marcato.
    expect(find.text('Plugins'), findsOneWidget);
    expect(find.text('keysend'), findsOneWidget);
    expect(find.text('bookkeeper'), findsOneWidget);
  });

  testWidgets('forwarding: empty state e lista', (tester) async {
    final service = LightningServiceMock(forwardCount: 2);
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    expect(find.text('Forwarding'), findsOneWidget);
    expect(find.text('Settled'), findsNWidgets(2));
    expect(find.text('No forwarded payments yet'), findsNothing);
  });

  testWidgets('forwarding vuoto → empty state', (tester) async {
    final service = LightningServiceMock();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    expect(find.text('No forwarded payments yet'), findsOneWidget);
  });

  testWidgets('stats non disponibili → messaggio del nodo', (tester) async {
    final service = _FailingStatsService();
    await tester.runAsync(() => service.connect(connection));
    await tester.pumpWidget(wrap(service));
    await tester.pumpAndSettle();

    expect(
      find.text('Lightning error: bkpr non disponibile'),
      findsOneWidget,
    );
  });
}
