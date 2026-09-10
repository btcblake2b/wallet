import 'package:flutter_test/flutter_test.dart';
import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;

import 'package:btc_blake2b_wallet/core/config/bitcoin_network_config.dart';
import 'package:btc_blake2b_wallet/core/utils/crypto_utils.dart';
import 'package:btc_blake2b_wallet/core/utils/watch_only_derivation.dart';

/// Gate di correttezza della derivazione watch-only: partendo dall'xpub
/// prodotto dalla derivazione hot (già validata dai vettori ufficiali BIP),
/// gli indirizzi derivati devono coincidere ESATTAMENTE — stesso seed, stessa
/// catena, stesso encoding → solo il punto di partenza cambia (xpub vs seed).
void main() {
  const mnemonic = 'abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon abandon abandon about';

  // xpub BIP84 mainnet dell'account m/84'/0'/0' derivato dal vettore.
  late WalletDerivationResult hotResult;
  late String accountXpub;

  setUpAll(() {
    hotResult = deriveWalletData(
      AddressDerivationData(mnemonic, BitcoinNetworkConfig.defaultDerivationPath, 5),
    );
    accountXpub = hotResult.xpub;
  });

  group('deriveWatchOnlyAddresses — round-trip vs derivazione hot', () {
    test('l\'xpub della derivazione hot è NEUTERED (mai xprv)', () {
      // PERCHÉ (sicurezza): regressione sul fix crypto_utils — l'xpub
      // esposto dal dialog "Mostra XPUB" non deve mai contenere una chiave
      // privata. Un xprv parsato qui avrebbe privateKey != null.
      final network = BitcoinNetworkConfig.bip32NetworkType;
      final node = bip32.BIP32.fromBase58(accountXpub, network);
      expect(node.privateKey, isNull);
      expect(accountXpub, startsWith('xpub'));
    });

    test('gli indirizzi external/change coincidono con quelli dal seed', () {
      final wo = deriveWatchOnlyAddresses(
        WatchOnlyDerivationData(
          accountXpub: accountXpub,
          scriptType: WalletScriptType.p2wpkh,
          addressCount: 5,
        ),
      );

      expect(wo.externalAddresses, hotResult.addresses);
      expect(wo.changeAddresses, hotResult.changeAddresses);
      expect(wo.publicAddress, hotResult.addresses.first);
      expect(wo.externalAddresses.length, 5);
      expect(wo.changeAddresses.length, 5);
    });

    test('il fingerprint è quello dell\'ACCOUNT (non del master)', () {
      final wo = deriveWatchOnlyAddresses(
        WatchOnlyDerivationData(
          accountXpub: accountXpub,
          scriptType: WalletScriptType.p2wpkh,
          addressCount: 1,
        ),
      );
      final network = BitcoinNetworkConfig.bip32NetworkType;
      final root = bip32.BIP32.fromSeed(bip39.mnemonicToSeed(mnemonic), network);
      final account = root.derivePath(BitcoinNetworkConfig.defaultDerivationPath);
      final expectedFp = account.fingerprint
          .map((e) => e.toRadixString(16).padLeft(2, '0'))
          .join('')
          .toUpperCase();

      // PERCHÉ: l'xpub è a livello account → il fingerprint disponibile è
      // quello dell'account (come nei descriptor), non quello del master.
      expect(wo.fingerprint, expectedFp);
      expect(wo.fingerprint.length, 8);
    });
  });

  group('deriveWatchOnlyAddresses — validazioni di sicurezza', () {
    test('rifiuta una chiave privata estesa (xprv)', () {
      final network = BitcoinNetworkConfig.bip32NetworkType;
      final root = bip32.BIP32.fromSeed(bip39.mnemonicToSeed(mnemonic), network);
      final xprv = root.toBase58();

      expect(
        () => deriveWatchOnlyAddresses(
          WatchOnlyDerivationData(accountXpub: xprv),
        ),
        throwsStateError,
      );
    });

    test('rifiuta un xpub di rete diversa (tpub testnet)', () {
      // PERCHÉ: il prefisso versione deve combaciare con la rete corrente
      // (mainnet blake2b, 0x0488b21e) — un tpub è un errore di rete.
      final testnet = bip32.NetworkType(
        wif: 0xef,
        bip32: bip32.Bip32Type(public: 0x043587cf, private: 0x04358394),
      );
      final root = bip32.BIP32.fromSeed(bip39.mnemonicToSeed(mnemonic), testnet);
      final tpub = root.derivePath("m/84'/1'/0'").toBase58();

      expect(
        () => deriveWatchOnlyAddresses(
          WatchOnlyDerivationData(accountXpub: tpub),
        ),
        throwsFormatException,
      );
    });

    test('rifiuta una stringa non valida', () {
      expect(
        () => deriveWatchOnlyAddresses(
          const WatchOnlyDerivationData(accountXpub: 'non-un-xpub'),
        ),
        throwsFormatException,
      );
    });
  });
}
