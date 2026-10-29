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
        'PAYMENT_FAILED',
        'PROVIDER_UNAVAILABLE',
        'RATE_LIMITED',
        'DUPLICATE_SWAP',
        'QUOTE_EXPIRED',
        'INVOICE_INVALID',
        'INVOICE_EXPIRED',
        'AMOUNT_TOO_SMALL',
        'AMOUNT_TOO_LARGE',
        'FUNDING_TIMEOUT',
        'TOO_LATE',
      ];

      for (final code in knownCodes) {
        final reason = swapErrorReason(loc, code);
        expect(reason, isNotNull, reason: 'codice $code non mappato');
        expect(reason!.trim(), isNotEmpty, reason: 'stringa vuota per $code');
      }
    });

    test('PAYMENT_FAILED spiega che i fondi restano nell HTLC', () {
      // PERCHÉ (incidente 18/09/2026): senza questa spiegazione l'utente non
      // capiva se il pagamento fosse avvenuto — il testo deve dire che i fondi
      // sono ancora suoi e recuperabili.
      final reason = swapErrorReason(loc, 'PAYMENT_FAILED')!;

      expect(reason, contains('HTLC'));
      expect(reason.toLowerCase(), contains('recover'));
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
