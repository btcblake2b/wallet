import 'package:flutter_test/flutter_test.dart';
import 'package:bip39/bip39.dart' as bip39;

import 'package:btc_blake2b_wallet/core/utils/mnemonic_utils.dart';

/// Validazione condivisa da import manuale e scan QR della seed: stessa
/// verità per entrambe le vie (lunghezze BIP39 + checksum).
void main() {
  // Vettore ufficiale BIP39 128-bit.
  const mnemonic12 = 'abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon abandon abandon about';

  group('normalizeMnemonic', () {
    test('minuscole, trim e separatori singoli', () {
      expect(
        normalizeMnemonic('  ABANDON\n abandon\tABOUT  '),
        'abandon abandon about',
      );
    });

    test('stringa vuota o soli spazi resta vuota', () {
      expect(normalizeMnemonic('   \n\t '), '');
    });
  });

  group('mnemonicWordCount', () {
    test('conta le parole dopo la normalizzazione', () {
      expect(mnemonicWordCount(mnemonic12), 12);
      expect(mnemonicWordCount('  '), 0);
    });
  });

  group('isValidMnemonic', () {
    test('accetta una seed valida anche con a-capo (caso QR)', () {
      final fromQr = mnemonic12.replaceAll(' ', '\n');
      expect(isValidMnemonic(fromQr), isTrue);
    });

    test('accetta tutte le lunghezze BIP39 ammesse', () {
      // Entropia per 12/15/18/21/24 parole: 16/20/24/28/32 byte.
      for (final entropyBytes in [16, 20, 24, 28, 32]) {
        final mnemonic =
            bip39.entropyToMnemonic(List.filled(entropyBytes, '00').join());
        expect(isValidMnemonic(mnemonic), isTrue, reason: '$entropyBytes byte');
      }
    });

    test('rifiuta una lunghezza non ammessa', () {
      expect(isValidMnemonic(List.filled(13, 'abandon').join(' ')), isFalse);
    });

    test('rifiuta un checksum non valido', () {
      expect(isValidMnemonic(List.filled(12, 'abandon').join(' ')), isFalse);
    });

    test('rifiuta parole non BIP39', () {
      expect(
        isValidMnemonic(List.filled(12, 'notaword').join(' ')),
        isFalse,
      );
    });

    test('rifiuta una stringa vuota', () {
      expect(isValidMnemonic(''), isFalse);
      expect(isValidMnemonic('   '), isFalse);
    });
  });
}
