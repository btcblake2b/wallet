import 'package:btc_blake2b_wallet/core/utils/bip21.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('satsToBtcAmount', () {
    test('interi e frazioni esatte, senza errori di virgola mobile', () {
      expect(satsToBtcAmount(100000000), '1');
      expect(satsToBtcAmount(150000000), '1.5');
      expect(satsToBtcAmount(12345), '0.00012345');
      expect(satsToBtcAmount(1), '0.00000001');
      expect(satsToBtcAmount(1000), '0.00001');
      expect(satsToBtcAmount(2100000000000000), '21000000');
    });

    test('zeri finali rimossi ma i decimali interni restano', () {
      expect(satsToBtcAmount(100000010), '1.0000001');
      expect(satsToBtcAmount(50000000), '0.5');
    });

    test('zero o negativo → "0"', () {
      expect(satsToBtcAmount(0), '0');
      expect(satsToBtcAmount(-5), '0');
    });
  });

  group('buildBip21Uri', () {
    const addr = 'bc1qexampleaddress000000000000000000000';

    test('con importo', () {
      expect(
        buildBip21Uri(address: addr, amountSats: 12345),
        'bitcoin:$addr?amount=0.00012345',
      );
    });

    test('senza importo il parametro amount non compare', () {
      expect(buildBip21Uri(address: addr), 'bitcoin:$addr');
      expect(buildBip21Uri(address: addr, amountSats: 0), 'bitcoin:$addr');
    });

    test('etichetta codificata (spazi e & non rompono il QR)', () {
      final uri = buildBip21Uri(
        address: addr,
        amountSats: 1000,
        label: 'Caffè & cornetto',
      );
      expect(uri, startsWith('bitcoin:$addr?amount=0.00001&label='));
      expect(uri, contains('Caff%C3%A8'));
      // Nessun carattere non codificato che spezzerebbe i parametri.
      expect(uri.split('&').length, 2);
      expect(Uri.parse(uri).queryParameters['label'], 'Caffè & cornetto');
    });

    test('etichetta vuota o di soli spazi non viene aggiunta', () {
      expect(
        buildBip21Uri(address: addr, amountSats: 500, label: '   '),
        'bitcoin:$addr?amount=0.000005',
      );
    });

    test('message opzionale accanto a label', () {
      final uri = buildBip21Uri(
        address: addr,
        label: 'Ordine 42',
        message: 'Tavolo 7',
      );
      expect(
        uri,
        'bitcoin:$addr?label=Ordine%2042&message=Tavolo%207',
      );
    });

    test('indirizzo vuoto → ArgumentError (mai un QR verso nessuno)', () {
      expect(
        () => buildBip21Uri(address: '  ', amountSats: 1000),
        throwsArgumentError,
      );
    });
  });
}
