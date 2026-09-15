import 'package:btc_blake2b_wallet/core/utils/lightning_invoice_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Esempio canonico dalla spec BOLT #11 (lnbc2500u…).
  const bolt11Example =
      'lnbc2500u1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypq'
      'dq5xysxxatsyp3k7enxv4jsxqzpuaztrnwngzn3kdzw5hydlzf03qdgm2hdq27cqv3agm2a'
      'whz5se903vruatfhq77w3ls4evs3ch9zw97j25emudupq63nyw24cg27h2rspfj9srp';

  group('isValidLightningInvoice', () {
    test('accetta una invoice BOLT11 valida', () {
      expect(isValidLightningInvoice(bolt11Example), isTrue);
    });

    test('accetta il formato URI lightning:', () {
      expect(isValidLightningInvoice('lightning:$bolt11Example'), isTrue);
      expect(isValidLightningInvoice('LIGHTNING:$bolt11Example'), isTrue);
    });

    test('accetta maiuscole (bech32) e prefissi testnet/regtest', () {
      expect(isValidLightningInvoice('LNTB1${'A' * 30}'), isTrue);
      expect(isValidLightningInvoice('lnbcrt1${'q' * 30}'), isTrue);
    });

    test('rifiuta indirizzi BTC on-chain', () {
      expect(
        isValidLightningInvoice('bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4'),
        isFalse,
      );
    });

    test('rifiuta lnurl e testo generico', () {
      expect(
        isValidLightningInvoice('lnurl1dp68gurn8ghj7mrww4exctt5dahkcuew'),
        isFalse,
      );
      expect(isValidLightningInvoice('ciao mondo'), isFalse);
    });

    test('rifiuta stringhe vuote o troppo corte', () {
      expect(isValidLightningInvoice(''), isFalse);
      expect(isValidLightningInvoice('   '), isFalse);
      expect(isValidLightningInvoice('lnbc'), isFalse);
    });
  });

  group('normalizeLightningInvoice', () {
    test('rimuove spazi e prefisso URI', () {
      expect(normalizeLightningInvoice('  lightning:lnbc1x  '), 'lnbc1x');
      expect(normalizeLightningInvoice(bolt11Example), bolt11Example);
    });
  });
}
