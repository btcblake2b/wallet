import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/core/services/receive_address_fallback.dart';

void main() {
  group('firstUnusedReceiveAddress (ADR 01/11-25 §2)', () {
    test('nessun UTXO: si usa fallback (publicAddress = /0/0)', () {
      expect(
        firstUnusedReceiveAddress(
          used: <String>{},
          derived: <String>['a0', 'a1', 'a2'],
          fallback: 'a0',
        ),
        'a0',
      );
    });

    test('/0/0 e /0/1 usati: si mostra /0/2 (NON un riuso)', () {
      // È il caso che giustifica l'euristica: il rollback non deve tornare a
      // mostrare un indirizzo già usato.
      expect(
        firstUnusedReceiveAddress(
          used: <String>{'a0', 'a1'},
          derived: <String>['a0', 'a1', 'a2', 'a3'],
          fallback: 'a0',
        ),
        'a2',
      );
    });

    test('utente con buco (solo /0/0 e /0/2 usati): mostra /0/1', () {
      expect(
        firstUnusedReceiveAddress(
          used: <String>{'a0', 'a2'},
          derived: <String>['a0', 'a1', 'a2'],
          fallback: 'a0',
        ),
        'a1',
      );
    });

    test('tutti usati: fallback conservativo', () {
      expect(
        firstUnusedReceiveAddress(
          used: <String>{'a0', 'a1'},
          derived: <String>['a0', 'a1'],
          fallback: 'a0',
        ),
        'a0',
      );
    });
  });
}
