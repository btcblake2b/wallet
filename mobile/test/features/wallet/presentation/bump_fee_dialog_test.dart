import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';
import 'package:btc_blake2b_wallet/features/wallet/presentation/widgets/bump_fee_dialog.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

Future<void> _pumpDialog(
  WidgetTester tester,
  int originalFeeRateSatVb,
  FeeEstimates? estimates,
  ValueChanged<int?> onResult,
) async {
  await tester.pumpWidget(
    _wrap(
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                final fee = await showBumpFeeDialog(
                  context,
                  originalFeeRateSatVb: originalFeeRateSatVb,
                  estimates: estimates,
                );
                onResult(fee);
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
}

void main() {
  final estimates = FeeEstimates(lowSatVb: 3, normalSatVb: 12, highSatVb: 30);

  testWidgets('mostra fee attuale e filtra opzioni <= originale',
      (tester) async {
    int? result;
    await _pumpDialog(tester, 5, estimates, (v) => result = v);

    expect(find.text('Current fee: 5 sat/vB'), findsOneWidget);
    // low (3) è filtrata perché ≤ originale; normal/high visibili.
    expect(find.text('3 sat/vB'), findsNothing);
    expect(find.text('12 sat/vB'), findsOneWidget);
    expect(find.text('30 sat/vB'), findsOneWidget);

    // Conferma con l'opzione di default (normal = 12).
    await tester.tap(find.text('Increase fee'));
    await tester.pumpAndSettle();
    expect(result, 12);
  });

  testWidgets('seleziona custom valida (8 > 5)', (tester) async {
    int? result;
    await _pumpDialog(tester, 5, estimates, (v) => result = v);

    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '8');
    await tester.tap(find.text('Increase fee'));
    await tester.pumpAndSettle();

    expect(result, 8);
  });

  testWidgets('custom non valida (<= originale) mostra errore e non chiude',
      (tester) async {
    int? result;
    await _pumpDialog(tester, 5, estimates, (v) => result = v);

    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '3');
    await tester.tap(find.text('Increase fee'));
    await tester.pumpAndSettle();

    expect(
      find.text('The new fee must be higher than the current one'),
      findsOneWidget,
    );
    expect(result, isNull);
  });

  testWidgets('senza stime (null) mostra avviso e solo custom',
      (tester) async {
    int? result;
    await _pumpDialog(tester, 5, null, (v) => result = v);

    expect(
      find.text('Recommended fees unavailable — enter a custom rate'),
      findsOneWidget,
    );
    // Nessuna radio raccomandata; custom già selezionato (campo visibile).
    expect(find.text('3 sat/vB'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), '20');
    await tester.tap(find.text('Increase fee'));
    await tester.pumpAndSettle();
    expect(result, 20);
  });

  testWidgets('annulla (Close) ritorna null', (tester) async {
    int? result;
    await _pumpDialog(tester, 5, estimates, (v) => result = v);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}
