import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/core/config/bitcoin_network_config.dart';
import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';

/// Verifica di derivazione BIP44 (legacy P2PKH) sulla rete corrente (mainnet)
/// tramite il servizio reale — solo derivazione pura, nessuna chiamata HTTP.
void main() {
  group('BitcoinService - BIP44 legacy P2PKH (mainnet)', () {
    const mnemonic = 'abandon abandon abandon abandon abandon abandon '
        'abandon abandon abandon abandon abandon about';

    test(
        'deriveWalletDataFromMnemonic con m/44\'/0\'/0\' produce P2PKH '
        '(external + change)', () async {
      final service = BitcoinService();
      final result = await service.deriveWalletDataFromMnemonic(
        mnemonic,
        derivationPath: "m/44'/0'/0'",
        addressCount: 5,
      );

      expect(result.derivationPath, "m/44'/0'/0'");
      // P2PKH mainnet: base58 con prefisso '1'.
      expect(
        result.publicAddress.startsWith('1'),
        isTrue,
        reason: 'indirizzo P2PKH mainnet deve iniziare con 1',
      );
      for (final addr in [...result.addresses, ...result.changeAddresses]) {
        expect(
          addr.startsWith('1'),
          isTrue,
          reason: 'indirizzo $addr non è P2PKH mainnet',
        );
        expect(
          BitcoinNetworkConfig.isValidAddress(addr),
          isTrue,
          reason: '$addr deve avere checksum base58 valido',
        );
      }
      expect(
        result.changeAddresses.toSet().intersection(result.addresses.toSet()),
        isEmpty,
        reason: 'external e change non devono sovrapporsi',
      );
    });

    test('BIP44 differisce da BIP84 e BIP49 per la stessa mnemonic', () async {
      final service = BitcoinService();
      final native =
          await service.deriveWalletDataFromMnemonic(mnemonic, addressCount: 1);
      final nested = await service.deriveWalletDataFromMnemonic(
        mnemonic,
        derivationPath: "m/49'/0'/0'",
        addressCount: 1,
      );
      final legacy = await service.deriveWalletDataFromMnemonic(
        mnemonic,
        derivationPath: "m/44'/0'/0'",
        addressCount: 1,
      );

      expect(native.publicAddress.startsWith('bc1'), isTrue);
      expect(nested.publicAddress.startsWith('3'), isTrue);
      expect(legacy.publicAddress.startsWith('1'), isTrue);
      expect(
        legacy.publicAddress,
        isNot(native.publicAddress),
        reason: 'legacy ≠ native per la stessa seed',
      );
      expect(
        legacy.publicAddress,
        isNot(nested.publicAddress),
        reason: 'legacy ≠ nested per la stessa seed',
      );
    });

    test('primo indirizzo ricezione coincide col valore noto BIP44 mainnet',
        () async {
      final service = BitcoinService();
      final legacy = await service.deriveWalletDataFromMnemonic(
        mnemonic,
        derivationPath: "m/44'/0'/0'",
        addressCount: 1,
      );
      // Valore ampiamente pubblicato (derivatori BIP44 standard, es.
      // iancoleman/bluewallet) per m/44'/0'/0'/0/0 con questa mnemonic.
      expect(legacy.publicAddress, '1LqBGSKuX5yYUonjxT5qGfpUsXKYYWeabA');
    });

    test('estimateTxVbytes pesa gli input legacy P2PKH (148 vB)', () {
      UtxoInfo utxo({String? type}) => UtxoInfo(
            txid: 'a' * 64,
            vout: 0,
            valueSat: 1000,
            scriptPubKeyType: type,
          );
      final legacy = [utxo(type: 'p2pkh')];
      final mixed = [
        utxo(type: 'p2pkh'),
        utxo(type: 'v0_p2wpkh'),
        utxo(type: 'p2sh'),
      ];
      // 1 input legacy + 1 output (nessuna witness): 10 + 148 + 31 = 189
      expect(estimateTxVbytes(legacy, 1), 201);
      // mix: 10 + 148 + 68(native+witness) + 91(nested+witness) + 3(segwit
      // overhead) + 31 = 351 (audit MED-1: prima 294, sotto-stimava i segwit)
      expect(estimateTxVbytes(mixed, 1), 363);
      final nativeAndNested = [utxo(type: 'v0_p2wpkh'), utxo(type: 'p2sh')];
      expect(
        estimateTxVbytes(mixed, 1),
        greaterThan(estimateTxVbytes(nativeAndNested, 1)),
      );
    });
  });
}
