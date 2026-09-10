import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:btc_blake2b_wallet/core/config/bitcoin_network_config.dart';
import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';

/// Test del percorso watch-only di BitcoinService: lo snapshot parte da un
/// xpub (nessun seed) e riusa la stessa scan/storico dei wallet hot.
///
/// Vettore noto BIP84 mainnet (stesso di bitcoin_service_test.dart):
/// mnemonic "abandon … about", m/84'/0'/0'/0/0 →
/// bc1qcr8te4kr609gcawutmrza83j4j3l68v2p8s8p4
void main() {
  const mnemonic = 'abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon abandon abandon about';

  late String accountXpub;
  late String firstExternal;

  setUpAll(() async {
    final derivation = await BitcoinService()
        .deriveWalletDataFromMnemonic(mnemonic, addressCount: 3);
    // PERCHÉ: l'xpub deriva dalla hot (neutered, nessuna chiave privata); il
    // primo indirizzo external si deriva a runtime invece di hardcodare il
    // vettore Bitcoin (l'encoding bech32 di questa chain può differire).
    accountXpub = derivation.xpub;
    firstExternal = derivation.addresses.first;
  });

  MockClient emptyApi() {
    return MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/blocks/tip/height')) {
        return http.Response('100000', 200);
      }
      if (path.contains('/utxo')) {
        return http.Response('[]', 200);
      }
      if (path.endsWith('/txs')) {
        return http.Response('[]', 200);
      }
      return http.Response('{}', 404);
    });
  }

  test('fetchWatchOnlySnapshot su wallet vuoto: saldo 0, nessun utxo/tx',
      () async {
    final service = BitcoinService(client: emptyApi());

    final snapshot = await service.fetchWatchOnlySnapshot(
      accountXpub: accountXpub,
      scriptType: WalletScriptType.p2wpkh,
      maxAddresses: 3,
    );

    expect(snapshot.balanceSats, 0);
    expect(snapshot.utxos, isEmpty);
    expect(snapshot.transactions, isEmpty);
  });

  test('fetchWatchOnlySnapshot aggrega il saldo degli UTXO derivati dall\'xpub',
      () async {
    final txid = 'ab12cd34' * 8; // 64 hex chars
    final mock = MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/blocks/tip/height')) {
        return http.Response('1000', 200);
      }
      // Primo indirizzo external: 1 UTXO da 50.000 sats.
      if (path.endsWith('/address/$firstExternal/utxo')) {
        return http.Response(
          jsonEncode([
            {'txid': txid, 'vout': 0, 'value': 50000},
          ]),
          200,
        );
      }
      if (path.contains('/utxo')) {
        return http.Response('[]', 200);
      }
      if (path.endsWith('/tx/$txid')) {
        return http.Response(
          jsonEncode({
            'vout': [
              {
                'scriptpubkey': '0014${'00' * 20}',
                'scriptpubkey_type': 'witness_v0_keyhash',
                'scriptpubkey_address': firstExternal,
              },
            ],
            'status': {'confirmed': true, 'block_height': 990},
          }),
          200,
        );
      }
      if (path.endsWith('/txs')) {
        return http.Response('[]', 200);
      }
      return http.Response('{}', 404);
    });
    final service = BitcoinService(client: mock);

    final snapshot = await service.fetchWatchOnlySnapshot(
      accountXpub: accountXpub,
      scriptType: WalletScriptType.p2wpkh,
      maxAddresses: 3,
    );

    expect(snapshot.balanceSats, 50000);
    expect(snapshot.utxos, hasLength(1));
    expect(snapshot.utxos!.first.valueSat, 50000);
    expect(snapshot.utxos!.first.ownerAddress, firstExternal);
  });
}
