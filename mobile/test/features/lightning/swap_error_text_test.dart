import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/features/lightning/presentation/swap_error_text.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

void main() {
  group('swapErrorReason', () {
    late AppLocalizations loc;

    setUpAll(() async {
      // PERCHÉ: stesso pattern degli altri test l10n — si carica il delegate
      // reale, così una chiave assente o vuota nel template EN fa fallire il
      // test invece di passare su una classe generata obsoleta.
      loc = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('mappa i codici noti su stringhe non vuote', () {
      const knownCodes = <String>[
        'RELAY_NOT_ALLOWED_WEB',
        'CONNECT_FAILED',
        'DISCONNECTED',
        'NOT_CONNECTED',
      ];

      for (final code in knownCodes) {
        final reason = swapErrorReason(loc, code);
        expect(reason, isNotNull, reason: 'codice $code non mappato');
        expect(reason!.trim(), isNotEmpty, reason: 'stringa vuota per $code');
      }
    });

    test('il messaggio del relay non consentito spiega la variante web', () {
      final reason = swapErrorReason(loc, 'RELAY_NOT_ALLOWED_WEB');

      // PERCHÉ: è un limite di sicurezza della PWA, non un guasto di rete —
      // il testo deve indirizzare l'utente alla versione mobile.
      expect(reason!.toLowerCase(), contains('web'));
      expect(reason.toLowerCase(), contains('phone'));
    });

    test('codice sconosciuto → null (fallback al messaggio tecnico)', () {
      expect(swapErrorReason(loc, 'QUALCOSA_DI_NUOVO'), isNull);
      expect(swapErrorReason(loc, ''), isNull);
    });
  });
}
