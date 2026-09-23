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

    test('espone host Esplora in ordine e lista broadcast senza maveth', () {
      // PERCHÉ (2026-09-16): failover su mirror comunitari verificati live
      // (stesso tip e stesso saldo netto del primario). maveth.ca NON espone
      // POST /tx → non deve mai entrare nella lista di broadcast.
      final hosts = BitcoinNetworkConfig.explorerApiBaseUrls;
      expect(hosts.first, 'https://mempool.guide/api');
      expect(hosts, hasLength(3));
      expect(hosts, contains('https://mempool.kilombino.com/api'));
      expect(hosts, contains('https://mempool.maveth.ca/api'));

      final broadcast = BitcoinNetworkConfig.broadcastApiBaseUrls;
      expect(broadcast.first, 'https://mempool.guide/api');
      expect(broadcast, contains('https://mempool.kilombino.com/api'));
      expect(broadcast, isNot(contains('https://mempool.maveth.ca/api')));
    });

    test('txExplorerUrl punta alla UI web, non all\'API', () {
      // PERCHÉ (18/09/2026): il link "verifica" del claim deve aprire la
      // pagina web della transazione; la base API termina in `/api` e NON è
      // una pagina navigabile → il suffisso va rimosso.
      final url = BitcoinNetworkConfig.txExplorerUrl('abcd' * 16);
      expect(url, 'https://mempool.guide/tx/${'abcd' * 16}');
      expect(url, isNot(contains('/api/')));
      expect(Uri.parse(url).path, '/tx/${'abcd' * 16}');
    });

    test('txExplorerUrl conserva il prefisso di rete dell\'host', () {
      // PERCHÉ: il prefisso viene dalla base primaria reale, quindi un
      // eventuale `/testnetN` resta nel percorso (solo `/api` viene tolto).
      final url = BitcoinNetworkConfig.txExplorerUrl('ff' * 32);
      final base = BitcoinNetworkConfig.primaryExplorerApiBaseUrl
          .replaceFirst(RegExp(r'/api$'), '');
      expect(url.endsWith('/tx/${'ff' * 32}'), isTrue);
      expect(url.startsWith(base), isTrue);
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
