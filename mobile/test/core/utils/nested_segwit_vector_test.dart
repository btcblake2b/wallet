import 'package:flutter_test/flutter_test.dart';
import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:bitcoin_base/bitcoin_base.dart' as bitcoin_base;

import 'package:btc_blake2b_wallet/core/config/bitcoin_network_config.dart';
import 'package:btc_blake2b_wallet/core/utils/crypto_utils.dart';

/// Vettore ufficiale BIP49 (bip-0049.mediawiki), ramo TESTNET.
///
/// masterseedWords = abandon abandon … about
/// path = m/49'/1'/0'/0/0
/// account0recvPublicKeyHex = 0x03a1af804ac108a8a51782198c2d034b28bf90c8803f5a53f76276fa69a4eae77f
/// address = base58check(P2SH) = 2Mww8dCYPUpKHofjgcXcBCEGmniw9CoaiD2
void main() {
  const mnemonic = 'abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon abandon abandon about';
  const expectedPubKeyHex =
      '03a1af804ac108a8a51782198c2d034b28bf90c8803f5a53f76276fa69a4eae77f';
  const expectedTestnetAddress = '2Mww8dCYPUpKHofjgcXcBCEGmniw9CoaiD2';

  group('Nested SegWit (BIP49) — vettore ufficiale', () {
    test('la derivazione testnet del vettore produce l\'indirizzo atteso', () {
      // PERCHÉ: il vettore BIP49 è su testnet (coin_type 1') e indipendente
      // dalla rete corrente dell'app → derivazione manuale con bip32 testnet
      // + encoder pubblico con network testnet. È il gate di correttezza
      // dell'encoding P2SH (base58check del witness program 0014{pkh}).
      final seed = bip39.mnemonicToSeed(mnemonic);
      final testnet = bip32.NetworkType(
        wif: 0xef,
        bip32: bip32.Bip32Type(public: 0x043587cf, private: 0x04358394),
      );
      final root = bip32.BIP32.fromSeed(seed, testnet);
      final child = root.derivePath("m/49'/1'/0'/0/0");

      final pubHex = child.publicKey
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      expect(
        pubHex,
        expectedPubKeyHex,
        reason: 'la chiave derivata deve coincidere col vettore',
      );

      final address = pubKeyToAddressForType(
        child.publicKey,
        type: WalletScriptType.p2shP2wpkh,
        network: bitcoin_base.BitcoinNetwork.testnet,
      );
      expect(address, expectedTestnetAddress);
    });
  });
}
