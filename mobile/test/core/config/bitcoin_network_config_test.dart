import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/core/config/bitcoin_network_config.dart';

void main() {
  group('BitcoinNetworkConfig', () {
    test('should use mainnet blake2b API', () {
      // PERCHÉ: dal 2026-08-31 la rete è mainnet blake2b; mempool.guide/api
      // espone l'API Esplora-compatibile della mainnet (verificato il
      // 31/08: chain=main).
      expect(BitcoinNetworkConfig.current, BtcNetwork.mainnet);
      expect(
        BitcoinNetworkConfig.blockstreamApiBaseUrl,
        contains('mempool.guide/api'),
      );
      expect(
        BitcoinNetworkConfig.mempoolApiBaseUrl,
        contains('mempool.guide/api'),
      );
    });

    test('should use mainnet BIP32/Bech32/coin_type parameters', () {
      expect(BitcoinNetworkConfig.bech32Hrp, 'bc');
      expect(BitcoinNetworkConfig.coinType, 0);
      expect(BitcoinNetworkConfig.defaultDerivationPath, "m/84'/0'/0'");
      expect(BitcoinNetworkConfig.ticker, 'BTC');
      expect(BitcoinNetworkConfig.networkName, 'Mainnet');
    });

    test('should validate mainnet address prefixes', () {
      expect(BitcoinNetworkConfig.isValidAddressPrefix('bc1q...'), isTrue);
      expect(BitcoinNetworkConfig.isValidAddressPrefix('1abc'), isTrue);
      expect(BitcoinNetworkConfig.isValidAddressPrefix('3abc'), isTrue);
      expect(BitcoinNetworkConfig.isValidAddressPrefix('tb1q...'), isFalse);
      expect(BitcoinNetworkConfig.isValidAddressPrefix('m...'), isFalse);
    });

    test('should provide mainnet fee fallback estimates (rete blake2b)', () {
      final fees = BitcoinNetworkConfig.fallbackFeeEstimates;
      // // PERCHÉ: mempool reale blake2b {economy:1, hour:1, fastest:2} —
      // non i valori Bitcoin SHA256 (3/12/30).
      expect(fees.low, 1);
      expect(fees.normal, 2);
      expect(fees.high, 3);
    });
  });
}
