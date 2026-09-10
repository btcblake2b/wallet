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
  });
}
