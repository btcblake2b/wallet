import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:btc_blake2b_wallet/core/widgets/skeleton.dart';

void main() {
  group('EmptyStateWidget', () {
    testWidgets('should render', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EmptyStateWidget(
            icon: Icons.info,
            title: 'Test Title',
            subtitle: 'Test Subtitle',
          ),
        ),
      );

      expect(find.byType(EmptyStateWidget), findsOneWidget);
    });

    // PERCHÉ: la terza azione (guida "Come funziona") è l'unica porta verso le
    // spiegazioni al primo avvio — se sparisce, nessun test se ne accorge.
    testWidgets('terza azione opzionale: visibile e tappabile', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: EmptyStateWidget(
            icon: Icons.info,
            title: 'Test Title',
            subtitle: 'Test Subtitle',
            actionLabel: 'Create',
            onAction: () {},
            secondaryLabel: 'Import',
            onSecondaryAction: () {},
            tertiaryLabel: 'How it works',
            onTertiaryAction: () => tapped++,
          ),
        ),
      );

      expect(find.text('How it works'), findsOneWidget);
      await tester.tap(find.text('How it works'));
      expect(tapped, 1);
    });

    testWidgets('senza callback la terza azione non esiste', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EmptyStateWidget(
            icon: Icons.info,
            title: 'Test Title',
            subtitle: 'Test Subtitle',
            tertiaryLabel: 'How it works',
          ),
        ),
      );

      expect(find.text('How it works'), findsNothing);
    });
  });
}
