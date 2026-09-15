import 'package:btc_blake2b_wallet/core/models/lightning_connection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const pub =
      'f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9';
  const secret =
      'b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d9045190cfef';
  final relay = Uri.encodeComponent('wss://relay.example.com');

  String buildUri({String? extra}) =>
      'nostr+walletconnect://$pub?relay=$relay&secret=$secret${extra ?? ''}';

  group('fromUri', () {
    test('URI valida completa', () {
      final conn = LightningConnection.fromUri(buildUri());
      expect(conn.walletPubkey, pub);
      expect(conn.relays, ['wss://relay.example.com']);
      expect(conn.secretHex, secret);
      expect(conn.lud16, isNull);
    });

    test('con lud16', () {
      final conn = LightningConnection.fromUri(
        buildUri(extra: '&lud16=${Uri.encodeComponent('user@example.com')}'),
      );
      expect(conn.lud16, 'user@example.com');
    });

    test('multi-relay: lista completa', () {
      final conn = LightningConnection.fromUri(
        'nostr+walletconnect://$pub'
        '?relay=${Uri.encodeComponent('wss://a.example')}'
        '&relay=${Uri.encodeComponent('wss://b.example')}'
        '&secret=$secret',
      );
      expect(conn.relays, ['wss://a.example', 'wss://b.example']);
    });

    test('pubkey maiuscola → normalizzata lowercase', () {
      final conn = LightningConnection.fromUri(
        'nostr+walletconnect://${pub.toUpperCase()}?relay=$relay&secret=$secret',
      );
      expect(conn.walletPubkey, pub);
    });

    test('schema errato → FormatException', () {
      expect(
        () => LightningConnection.fromUri('https://example.com?secret=$secret'),
        throwsA(isA<FormatException>()),
      );
    });

    test('pubkey non valida → FormatException', () {
      expect(
        () => LightningConnection.fromUri(
          'nostr+walletconnect://xyz?relay=$relay&secret=$secret',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('secret mancante → FormatException', () {
      expect(
        () => LightningConnection.fromUri(
          'nostr+walletconnect://$pub?relay=$relay',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('secret non hex → FormatException', () {
      expect(
        () => LightningConnection.fromUri(
          'nostr+walletconnect://$pub?relay=$relay&secret=not-hex',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('relay mancante → FormatException', () {
      expect(
        () => LightningConnection.fromUri(
          'nostr+walletconnect://$pub?secret=$secret',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('relay non websocket → FormatException', () {
      expect(
        () => LightningConnection.fromUri(
          'nostr+walletconnect://$pub'
          '?relay=${Uri.encodeComponent('https://relay.example.com')}'
          '&secret=$secret',
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('toUri', () {
    test('round-trip: fromUri(toUri()) preserva i campi', () {
      const original = LightningConnection(
        walletPubkey: pub,
        relays: ['wss://a.example', 'wss://b.example'],
        secretHex: secret,
        lud16: 'user@example.com',
      );
      final restored = LightningConnection.fromUri(original.toUri());
      expect(restored.walletPubkey, original.walletPubkey);
      expect(restored.relays, original.relays);
      expect(restored.secretHex, original.secretHex);
      expect(restored.lud16, original.lud16);
    });
  });

  group('sicurezza', () {
    test('toString NON contiene il secret', () {
      const conn = LightningConnection(
        walletPubkey: pub,
        relays: ['wss://a.example'],
        secretHex: secret,
      );
      expect(conn.toString().contains(secret), isFalse);
    });
  });
}
