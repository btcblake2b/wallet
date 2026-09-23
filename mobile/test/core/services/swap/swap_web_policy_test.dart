import 'package:btc_blake2b_wallet/core/services/swap/swap_web_policy.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test della policy relay della variante web/PWA (allowlist CSP).
///
/// // PERCHÉ: `kIsWeb` è una costante di compilazione e nei test vale sempre
/// // `false` → la policy è verificata con il seam `useWebPolicy`, mentre il
/// // ramo nativo verifica che NON venga applicata alcuna restrizione.
void main() {
  group('swap_web_policy', () {
    test('relay in allowlist: esatto, con slash finale e maiuscole', () {
      expect(isRelayInWebAllowlist('wss://relay.primal.net'), isTrue);
      expect(isRelayInWebAllowlist('wss://relay.primal.net/'), isTrue);
      expect(isRelayInWebAllowlist('  wss://Relay.Primal.NET '), isTrue);
    });

    test('relay fuori allowlist (o senza TLS) → false', () {
      expect(isRelayInWebAllowlist('wss://relay.example.com'), isFalse);
      expect(isRelayInWebAllowlist('ws://relay.primal.net'), isFalse);
      expect(isRelayInWebAllowlist(''), isFalse);
    });

    test('fuori dal web: lista invariata (nessuna restrizione aggiunta)', () {
      const relays = ['wss://relay.example.com', 'wss://relay.primal.net'];
      expect(filterRelaysForPlatform(relays, useWebPolicy: false), relays);
    });

    test('su web: tiene solo i relay consentiti', () {
      const relays = ['wss://relay.example.com', 'wss://relay.primal.net'];
      expect(
        filterRelaysForPlatform(relays, useWebPolicy: true),
        const ['wss://relay.primal.net'],
      );
    });

    test('su web senza relay consentiti → lista vuota (errore chiaro a monte)',
        () {
      const relays = ['wss://relay.example.com'];
      expect(filterRelaysForPlatform(relays, useWebPolicy: true), isEmpty);
    });
  });
}
