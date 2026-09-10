import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/features/wallet/presentation/scan_qr_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

void main() {
  group('ScanQrScreen', () {
    testWidgets('should render the scan screen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ScanQrScreen(),
        ),
      );
      // PERCHÉ: in ambiente di test la camera non è disponibile: il widget
      // monta comunque e l'errorBuilder gestisce l'errore del plugin.
      await tester.pump();

      expect(find.byType(ScanQrScreen), findsOneWidget);
    });
  });
}
