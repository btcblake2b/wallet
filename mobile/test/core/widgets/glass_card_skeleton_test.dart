import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:btc_blake2b_wallet/core/widgets/skeleton.dart';

void main() {
  group('GlassCardSkeleton', () {
    testWidgets('should render', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GlassCardSkeleton(),
        ),
      );

      expect(find.byType(GlassCardSkeleton), findsOneWidget);
    });

    // TODO: Aggiungi test per interazioni e comportamento
  });
}
