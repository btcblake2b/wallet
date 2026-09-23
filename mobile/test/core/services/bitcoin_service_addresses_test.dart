import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:btc_blake2b_wallet/core/config/bitcoin_network_config.dart';
import 'package:btc_blake2b_wallet/core/models/wallet_address.dart';
import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';
import 'package:btc_blake2b_wallet/core/services/explorer_mirrors.dart';

/// Mnemonic di test BIP39 (BIP84, m/84'/0'/0'). Nessun fondo reale: le API
/// sono mockate, qui si testa la MECCANICA (stato, gap-limit, errori).
const _mnemonic =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon '
    'abandon abandon about';

/// Risposta Esplora-compatibile di un indirizzo: `{balance, tx_count}`.
/// // PERCHÉ: la fonte reale (`/address/{a}`) ritorna chain_stats +
/// mempool_stats; `BitcoinService.fetchAddressInfo` li somma in balance/tx_count.
http.Response _stats({int balance = 0, int txCount = 0}) {
  return http.Response(
    jsonEncode({
      'chain_stats': {
        'funded_txo_sum': balance,
        'spent_txo_sum': 0,
        'tx_count': txCount,
      },
      'mempool_stats': <String, dynamic>{},
    }),
    200,
  );
}

bool _isAddressStats(http.Request request) =>
    request.url.path.contains('/address/') &&
    !request.url.path.endsWith('/utxo');

void main() {
  setUp(() {
    // PERCHÉ: la politica dei mirror è di processo (default ON) — un test
    // precedente non deve cambiare gli host usati da questo.
    ExplorerMirrors.resetForTest();
  });

  group('BitcoinService.fetchWalletAddresses — hot (seed)', () {
    test('stato e saldo per indirizzo, con path di derivazione corretto',
        () async {
      final deriveService = BitcoinService();
      final derived = await deriveService.deriveWalletDataFromMnemonic(
        _mnemonic,
        addressCount: 4,
      );
      // Indice 1 della catena di ricezione: usato, con saldo.
      final funded = derived.addresses[1];

      final mock = MockClient((request) async {
        if (_isAddressStats(request)) {
          final addr = request.url.path.split('/address/').last;
          if (addr == funded) return _stats(balance: 2121, txCount: 3);
          return _stats();
        }
        return http.Response('not found', 404);
      });
      final service = BitcoinService(client: mock);

      final list = await service.fetchWalletAddresses(
        mnemonic: _mnemonic,
        gapLimit: 4,
        maxAddresses: 4,
      );

      final match = list.firstWhere((a) => a.address == funded);
      expect(match.status, WalletAddressStatus.hasFunds);
      expect(match.balanceSats, 2121);
      expect(match.txCount, 3);
      expect(match.branch, WalletAddressBranch.external);
      expect(match.index, 1);
      expect(match.derivationPath, "${derived.derivationPath}/0/1");
    });

    test('gap-limit: si ferma dopo N indirizzi consecutivi inattivi', () async {
      var statsCalls = 0;
      final mock = MockClient((request) async {
        if (_isAddressStats(request)) {
          statsCalls++;
          return _stats();
        }
        return http.Response('not found', 404);
      });
      final service = BitcoinService(client: mock);

      final list = await service.fetchWalletAddresses(
        mnemonic: _mnemonic,
        gapLimit: 2,
        maxAddresses: 10,
      );

      // 2 indirizzi per ramo (ricezione + resto) e nessuna richiesta oltre.
      expect(list, hasLength(4));
      expect(statsCalls, 4);
      expect(
        list.every((a) => a.status == WalletAddressStatus.unused),
        isTrue,
      );
    });

    test('errore di rete: propaga (mai saldo 0 spacciato per vero)', () async {
      final mock = MockClient((_) async => http.Response('boom', 500));
      final service = BitcoinService(client: mock);

      await expectLater(
        () => service.fetchWalletAddresses(
          mnemonic: _mnemonic,
          gapLimit: 1,
          maxAddresses: 1,
        ),
        throwsA(anything),
      );
    });
  });

  group('BitcoinService.fetchWalletAddresses — watch-only (xpub)', () {
    test('deriva dallo xpub e produce gli stessi indirizzi del seed', () async {
      final deriveService = BitcoinService();
      final hot = await deriveService.deriveWalletDataFromMnemonic(
        _mnemonic,
        addressCount: 3,
      );

      final mock = MockClient((request) async {
        if (_isAddressStats(request)) return _stats();
        return http.Response('not found', 404);
      });
      final service = BitcoinService(client: mock);

      final list = await service.fetchWalletAddresses(
        accountXpub: hot.xpub,
        scriptType: WalletScriptType.p2wpkh,
        gapLimit: 2,
        maxAddresses: 3,
      );

      expect(
        list.map((a) => a.address),
        contains(hot.addresses.first),
      );
      expect(list.first.branch, WalletAddressBranch.external);
      expect(list.first.derivationPath, "m/84'/0'/0'/0/0");
    });
  });
}
