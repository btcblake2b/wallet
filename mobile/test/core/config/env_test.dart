import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/core/config/env.dart';

void main() {
  group('Env', () {
    test('appSignature è vuota oppure una SHA-256 valida (formato AA:BB:…:ZZ)', () {
      // PERCHÉ: con `.env` popolato il generato (`env.g.dart`) incorpora la
      // firma del certificato APK; senza `.env` (dev/CI) resta vuota. Il test
      // accetta entrambe le configurazioni ma rifiuta valori malformati, che
      // in release bloccherebbero l'avvio (fail-closed, vedi fix v0.1.1).
      final sig = Env.appSignature;
      if (sig.isEmpty) return;
      expect(
        RegExp(r'^([0-9A-Fa-f]{2}:){31}[0-9A-Fa-f]{2}$').hasMatch(sig),
        isTrue,
        reason: 'APP_SIGNATURE deve essere lo SHA-256 del certificato di '
            'firma (32 byte separati da ":"): $sig',
      );
    });
  });
}
