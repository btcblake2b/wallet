import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/features/lightning/presentation/widgets/peering_gate_banner.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

/// Il banner è **self-gating**: si disegna solo quando il gate è dimostrabile.
/// Qui si verifica che non compaia negli scenari ambigui (dato mancante,
/// versione non riconosciuta, peer connessi).
void main() {
  // Titolo del gate storico (bit 68, release `.4`).
  const title = 'Peering restricted to bit 68 releases';
  // Titolo del gate nuovo (bits 512/514, release `.5+`) — A5, 30/09/2026.
  const newBitsTitle = 'Peering limited to the new protocol releases';

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

  testWidgets('release .5 con 0 peer → avviso con il testo del nuovo gate',
      (tester) async {
    await tester.pumpWidget(wrap('v26.06.8-blake2b.5', 0));

    expect(find.text(newBitsTitle), findsOneWidget);
    expect(find.text(title), findsNothing);
    expect(find.text('Compatibility matrix'), findsOneWidget);
  });

  testWidgets('release .5 con peer connessi → nessun avviso', (tester) async {
    await tester.pumpWidget(wrap('v26.06.8-blake2b.5', 1));

    expect(find.text(newBitsTitle), findsNothing);
  });

  testWidgets('release .10 (numero a più cifre) → testo del nuovo gate',
      (tester) async {
    await tester.pumpWidget(wrap('v26.06.8-blake2b.10', 0));

    expect(find.text(newBitsTitle), findsOneWidget);
  });

  testWidgets('release .4 continua a mostrare il testo del bit 68',
      (tester) async {
    await tester.pumpWidget(wrap('v26.06.7-blake2b.4', 0));

    expect(find.text(title), findsOneWidget);
    expect(find.text(newBitsTitle), findsNothing);
  });
}
