import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:btc_blake2b_wallet/core/widgets/safe_qr_image.dart';

void main() {
  group('SafeQrImage', () {
    testWidgets('should render', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SafeQrImage(data: 'test_data'),
        ),
      );
      await tester.pump();

      expect(find.byType(SafeQrImage), findsOneWidget);
    });
  });
}
