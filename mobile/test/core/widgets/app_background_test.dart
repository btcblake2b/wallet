import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:btc_blake2b_wallet/core/widgets/app_background.dart';

void main() {
  group('AppBackground', () {
    testWidgets('should render', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppBackground(child: Text('test')),
        ),
      );

      expect(find.byType(AppBackground), findsOneWidget);
    });
  });
}
