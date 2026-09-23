import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/core/models/send_output.dart';

/// Test del modello destinatario (P3 batch send).
void main() {
  const addr = 'bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu';

  group('SendOutput', () {
    test('isDust è false a 546 sat (soglia inclusa)', () {
      const output = SendOutput(address: addr, amountSats: 546);
      expect(output.isDust, isFalse);
    });

    test('isDust è true a 545 sat (sotto la soglia)', () {
      const output = SendOutput(address: addr, amountSats: 545);
      expect(output.isDust, isTrue);
    });

    test('uguaglianza per indirizzo + importo (serve al check duplicati)', () {
      const a = SendOutput(address: addr, amountSats: 1000);
      const b = SendOutput(address: addr, amountSats: 1000);
      const c = SendOutput(address: addr, amountSats: 1001);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('toString riporta indirizzo e importo (debug dei log)', () {
      const output = SendOutput(address: addr, amountSats: 21000);
      expect(output.toString(), contains(addr));
      expect(output.toString(), contains('21000'));
    });
  });
}
