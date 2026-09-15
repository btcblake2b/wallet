import 'package:btc_blake2b_wallet/core/utils/lightning_peer_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseNodeConnectionString', () {
    test('solo pubkey → nessun host', () {
      final r = parseNodeConnectionString(
        '023e300917fde06d24038083489cc9f31cce54ae8ff169b02e408a2f58533ebead',
      );
      expect(r.nodeId.length, 66);
      expect(r.host, isNull);
    });

    test('stringa compatta pubkey@host:port → separata', () {
      final r = parseNodeConnectionString(
        '023e300917fde06d24038083489cc9f31cce54ae8ff169b02e408a2f58533ebead'
        '@w4otb2jwynxfeojbii57a7osybfisepzdfwxe4xueqfuew276h7l2hyd.onion:9735',
      );
      expect(
        r.nodeId,
        '023e300917fde06d24038083489cc9f31cce54ae8ff169b02e408a2f58533ebead',
      );
      expect(
        r.host,
        'w4otb2jwynxfeojbii57a7osybfisepzdfwxe4xueqfuew276h7l2hyd.onion:9735',
      );
    });

    test('maiuscole e spazi → normalizzati', () {
      final r = parseNodeConnectionString(
        '  023E300917FDE06D24038083489CC9F31CCE54AE8FF169B02E408A2F58533EBEAD  ',
      );
      expect(
        r.nodeId,
        '023e300917fde06d24038083489cc9f31cce54ae8ff169b02e408a2f58533ebead',
      );
      expect(r.host, isNull);
    });

    test('stringa vuota', () {
      final r = parseNodeConnectionString('   ');
      expect(r.nodeId, isEmpty);
      expect(r.host, isNull);
    });
  });

  group('isValidLightningNodeId', () {
    test('pubkey valida', () {
      expect(
        isValidLightningNodeId(
          '023e300917fde06d24038083489cc9f31cce54ae8ff169b02e408a2f58533ebead',
        ),
        isTrue,
      );
    });

    test('stringa con @ → non valida per il campo pubkey', () {
      expect(
        isValidLightningNodeId(
          '023e300917fde06d24038083489cc9f31cce54ae8ff169b02e408a2f58533ebead@x:9735',
        ),
        isFalse,
      );
    });

    test('troppo corta → non valida', () {
      expect(isValidLightningNodeId('02bfca'), isFalse);
    });
  });

  group('isValidPeerHost', () {
    test('ip:porta', () {
      expect(isValidPeerHost('127.0.0.1:9735'), isTrue);
    });

    test('onion:porta', () {
      expect(
        isValidPeerHost(
          'w4otb2jwynxfeojbii57a7osybfisepzdfwxe4xueqfuew276h7l2hyd.onion:9735',
        ),
        isTrue,
      );
    });

    test('senza porta → non valido', () {
      expect(isValidPeerHost('example.com'), isFalse);
    });

    test('porta fuori range → non valido', () {
      expect(isValidPeerHost('example.com:99999'), isFalse);
    });

    test('vuoto → non valido', () {
      expect(isValidPeerHost('  '), isFalse);
    });
  });
}
