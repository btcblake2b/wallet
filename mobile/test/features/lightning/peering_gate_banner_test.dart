import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/features/lightning/presentation/widgets/peering_gate_banner.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

/// Il banner è **self-gating**: si disegna solo quando il gate è dimostrabile.
/// Qui si verifica che non compaia negli scenari ambigui (dato mancante,
/// versione non riconosciuta, peer connessi).
void main() {
  const title = 'Peering restricted to bit 68 releases';

  Widget wrap(String? version, int? peersConnected) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: PeeringGateBanner(
            version: version,
            peersConnected: peersConnected,
          ),
        ),
      );

  testWidgets('release .4 con 0 peer connessi → avviso visibile',
      (tester) async {
    await tester.pumpWidget(wrap('v26.06.7-blake2b.4', 0));

    expect(find.text(title), findsOneWidget);
    expect(find.text('Compatibility matrix'), findsOneWidget);
  });

  testWidgets('release .4 con peer connessi → nessun avviso', (tester) async {
    await tester.pumpWidget(wrap('v26.06.7-blake2b.4', 1));

    expect(find.text(title), findsNothing);
  });

  testWidgets('release .3 (senza gate) → nessun avviso', (tester) async {
    await tester.pumpWidget(wrap('v26.06.7-blake2b.3', 0));

    expect(find.text(title), findsNothing);
  });

  testWidgets('versione non nota → nessun avviso (mai allarmi falsi)',
      (tester) async {
    await tester.pumpWidget(wrap(null, 0));
    expect(find.text(title), findsNothing);

    await tester.pumpWidget(wrap('v0.1.0', 0));
    expect(find.text(title), findsNothing);
  });

  testWidgets('conteggio peer sconosciuto → nessun avviso', (tester) async {
    await tester.pumpWidget(wrap('v26.06.7-blake2b.4', null));

    expect(find.text(title), findsNothing);
  });
}
