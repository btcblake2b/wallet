import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:btc_blake2b_wallet/core/widgets/glass_container.dart';

void main() {
  group('GlassContainer', () {
    testWidgets('should render', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GlassContainer(child: Text('test')),
        ),
      );

      expect(find.byType(GlassContainer), findsOneWidget);
    });
  });
}
