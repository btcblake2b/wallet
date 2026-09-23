import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:btc_blake2b_wallet/core/models/lightning_node_info.dart';
import 'package:btc_blake2b_wallet/core/models/lightning_peer.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_service.dart';
import 'package:btc_blake2b_wallet/features/lightning/presentation/lightning_peers_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

class MockLightningService extends Mock implements LightningService {}

/// Schermata Peer: il banner del gate bit 68 deve comparire solo con versione
/// riconosciuta + zero peer connessi, e il degrado deve essere pulito quando la
/// versione non è leggibile.
void main() {
  const gateTitle = 'Peering restricted to bit 68 releases';
  const disconnectedPeer = LightningPeer(
    id: '02bfcaa8328a89aa03ef55b3b810dc0dc43ee6df1e8d4cc8badb219ba303063389',
    connected: false,
    numChannels: 1,
  );

  late MockLightningService service;

  setUp(() {
    service = MockLightningService();
    when(() => service.listPeers())
        .thenAnswer((_) async => const [disconnectedPeer]);
  });

  void stubVersion(String? version) {
    when(() => service.getInfo()).thenAnswer(
      (_) async => LightningNodeInfo(
        alias: 'nodo-test',
        version: version,
        numPeersConnected: 0,
      ),
    );
  }

  Widget wrap() => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: LightningPeersScreen(lightningService: service),
      );

  testWidgets('release .4 + peer registrato disconnesso → avviso e conteggio',
      (tester) async {
    stubVersion('v26.06.7-blake2b.4');

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text(gateTitle), findsOneWidget);
    expect(find.text('1 registered peers, none connected'), findsOneWidget);
  });

  testWidgets('release .3 → nessun avviso', (tester) async {
    stubVersion('v26.06.7-blake2b.3');

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text(gateTitle), findsNothing);
    expect(find.text('1 registered peers, none connected'), findsOneWidget);
  });

  testWidgets('getInfo non disponibile → lista peer usabile, nessun avviso',
      (tester) async {
    when(() => service.getInfo())
        .thenThrow(const LightningException('X', 'non disponibile'));

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text(gateTitle), findsNothing);
    // La schermata resta funzionante: i peer sono comunque elencati.
    expect(find.text('Peers'), findsOneWidget);
  });
}
