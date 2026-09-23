import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/core/config/bitcoin_network_config.dart';
import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';

/// Verifica di derivazione BIP49 (nested segwit) sulla rete corrente (mainnet)
/// tramite il servizio reale — solo derivazione pura, nessuna chiamata HTTP.
void main() {
  group('BitcoinService - BIP49 nested segwit (mainnet)', () {
    const mnemonic = 'abandon abandon abandon abandon abandon abandon '
        'abandon abandon abandon abandon abandon about';

    test(
        'deriveWalletDataFromMnemonic con m/49\'/0\'/0\' produce P2SH '
        '(external + change)', () async {
      final service = BitcoinService();
      final result = await service.deriveWalletDataFromMnemonic(
        mnemonic,
        derivationPath: "m/49'/0'/0'",
        addressCount: 5,
      );

      expect(result.derivationPath, "m/49'/0'/0'");
      // P2SH mainnet: base58 con prefisso '3'.
      expect(
        result.publicAddress.startsWith('3'),
        isTrue,
        reason: 'indirizzo P2SH mainnet deve iniziare con 3',
      );
      for (final addr in [...result.addresses, ...result.changeAddresses]) {
        expect(
          addr.startsWith('3'),
          isTrue,
          reason: 'indirizzo $addr non è P2SH mainnet',
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

    test('BIP49 differisce da BIP84 per la stessa mnemonic', () async {
      final service = BitcoinService();
      final native =
          await service.deriveWalletDataFromMnemonic(mnemonic, addressCount: 1);
      final nested = await service.deriveWalletDataFromMnemonic(
        mnemonic,
        derivationPath: "m/49'/0'/0'",
        addressCount: 1,
      );

      expect(
        native.publicAddress.startsWith('bc1'),
        isTrue,
        reason: 'BIP84 native = bech32',
      );
      expect(
        nested.publicAddress.startsWith('3'),
        isTrue,
        reason: 'BIP49 nested = P2SH base58',
      );
      expect(nested.publicAddress, isNot(native.publicAddress));
    });

    test('estimateTxVbytes pesa gli input nested P2SH più dei native', () {
      UtxoInfo utxo({String? type}) => UtxoInfo(
            txid: 'a' * 64,
            vout: 0,
            valueSat: 1000,
            scriptPubKeyType: type,
          );
      final nativeOnly = [
        utxo(type: 'v0_p2wpkh'),
        utxo(type: 'v0_p2wpkh'),
      ];
      final mixed = [
        utxo(type: 'v0_p2wpkh'),
        utxo(type: 'p2sh'),
      ];
      // 1 output: header 10 + 68*2 native (witness incluso) + 3 overhead
      // segwit + 31 = 180 (audit MED-1: prima 123, sotto-stimava i segwit)
      expect(estimateTxVbytes(nativeOnly, 1), 192);
      // nested: 10 + 68 + 91 + 3 + 31 = 203 → più pesante del solo native
      expect(estimateTxVbytes(mixed, 1), 215);
      expect(
        estimateTxVbytes(mixed, 1),
        greaterThan(estimateTxVbytes(nativeOnly, 1)),
      );
    });
  });
}
