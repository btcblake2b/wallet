import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:btc_blake2b_wallet/core/models/transaction_record.dart';
import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';
import 'package:btc_blake2b_wallet/core/services/explorer_api.dart';
import 'package:btc_blake2b_wallet/core/services/pending_send_registry.dart';

/// Test vector BIP39/BIP84 noto:
/// Mnemonic: abandon abandon ... about
/// Derivation path: m/84'/0'/0'/0/0
/// Expected address (mainnet): bc1qcr8te4kr609gcawutmrza83j4j3l68v2p8s8p4
void main() {
  late BitcoinService bitcoinService;

  setUp(() {
    bitcoinService = BitcoinService();
    // PERCHÉ (audit P1-c): il registro è statico per-isolate — un broadcast
    // di un test precedente aggiungerebbe righe sintetiche ai test history.
    PendingSendRegistry.resetForTest();
  });

  group('BitcoinService - BIP39/BIP84 derivation (mainnet)', () {
    // Mainnet: m/84'/0'/0'/0/0
    test('generateMnemonic produces 12 words', () {
      final mnemonic = bitcoinService.generateMnemonic();
      final words = mnemonic.split(' ');
      expect(words.length, equals(12));
    });

    test('signMessage produces valid signature', () async {
      const mnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      const message = 'Hello Bitcoin';

      final signature = await bitcoinService.signMessage(mnemonic, message);

      expect(signature, isNotEmpty);
      // Firma ECDSA compact (r||s = 64 byte) in base64 = ~88 caratteri
      expect(signature.length, greaterThan(80));
    });

    test('deriveAddressFromMnemonic returns non-empty address', () async {
      const mnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

      final address = await bitcoinService.deriveAddressFromMnemonic(mnemonic);

      expect(address, isNotEmpty);
      // Deve iniziare con il prefisso Bech32 corretto per la rete attuale
      expect(
        address.startsWith('bc1') || address.startsWith('tb1'),
        isTrue,
        reason: 'Expected Bech32 address (bc1 for mainnet)',
      );
    });

    test(
      'deriveWalletDataFromMnemonic with known vector produces consistent results',
      () async {
        const mnemonic =
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

        final result = await bitcoinService.deriveWalletDataFromMnemonic(
          mnemonic,
          addressCount: 5,
        );

        expect(result.publicAddress, isNotEmpty);
        expect(result.masterFingerprint, isNotEmpty);
        expect(result.masterFingerprint.length, equals(8));
        expect(result.derivationPath, isNotEmpty);
        expect(result.xpub, isNotEmpty);
        expect(result.addresses.length, equals(5));

        // Tutti gli indirizzi devono essere Bech32
        for (final addr in result.addresses) {
          expect(
            addr.startsWith('bc1'),
            isTrue,
            reason: 'Address $addr is not Bech32 mainnet',
          );
        }
      },
    );

    test('deriveWalletDataFromMnemonic deriva anche la catena change',
        () async {
      const mnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

      final result = await bitcoinService.deriveWalletDataFromMnemonic(
        mnemonic,
        addressCount: 5,
      );

      // PERCHÉ: la catena change (/1/N) è necessaria per vedere il resto
      // delle spese — fix saldo/storico vs BlueWallet.
      expect(result.changeAddresses.length, equals(5));
      expect(
        result.changeAddresses.first,
        isNot(equals(result.addresses.first)),
      );
      expect(
        result.addresses.toSet().intersection(result.changeAddresses.toSet()),
        isEmpty,
        reason: 'external e change non devono sovrapporsi',
      );
    });

    test('fetchAddressInfo parses balance and tx_count from mocked API',
        () async {
      // PERCHÉ (P1.2): test deterministico con MockClient — nessuna rete reale,
      // niente flakiness in CI.
      final mock = MockClient((request) async {
        expect(request.url.path.endsWith('/address/bc1qtest'), isTrue);
        return http.Response(
          jsonEncode({
            'chain_stats': {
              'funded_txo_sum': 100000,
              'spent_txo_sum': 40000,
              'tx_count': 5,
            },
            'mempool_stats': {
              'funded_txo_sum': 5000,
              'spent_txo_sum': 0,
              'tx_count': 1,
            },
          }),
          200,
        );
      });
      final service = BitcoinService(client: mock);

      final info = await service.fetchAddressInfo('bc1qtest');

      expect(info['balance'], equals(65000)); // (100000+5000)-(40000+0)
      expect(info['tx_count'], equals(6));
    });

    test('fetchAddressInfo returns zeros for empty address', () async {
      final info = await bitcoinService.fetchAddressInfo('');
      expect(info['balance'], equals(0));
      expect(info['tx_count'], equals(0));
    });

    test('fetchAddressInfo propaga l\'errore API (mai mascherato su saldo 0)',
        () async {
      // PERCHÉ (F5): un errore NON è un saldo 0 — l'eccezione tipizzata si
      // propaga e la UI mostra "non disponibile" (0 reale solo con 200 OK).
      final mock = MockClient((_) async => http.Response('error', 500));
      final service = BitcoinService(client: mock);

      await expectLater(
        service.fetchAddressInfo('bc1qtest'),
        throwsA(isA<ApiException>()),
      );
    });

    test('fetchAddressInfo usa mempool.guide come unica fonte (1 richiesta)',
        () async {
      // PERCHÉ (2026-09-08): niente più backend personale — il saldo arriva
      // da mempool.guide con UNA sola richiesta, senza doppio salto.
      var calls = 0;
      final mock = MockClient((request) async {
        calls++;
        expect(request.url.host, equals('mempool.guide'));
        return http.Response(
          jsonEncode({
            'chain_stats': {
              'funded_txo_sum': 90000,
              'spent_txo_sum': 0,
              'tx_count': 2,
            },
            'mempool_stats': {
              'funded_txo_sum': 0,
              'spent_txo_sum': 0,
              'tx_count': 0,
            },
          }),
          200,
        );
      });
      final service = BitcoinService(client: mock);

      final info = await service.fetchAddressInfo('bc1qtest');

      expect(info['balance'], equals(90000));
      expect(info['tx_count'], equals(2));
      expect(calls, equals(1));
    });

    test('fetchFeeEstimates parses recommended fees from mocked API', () async {
      final mock = MockClient((request) async {
        expect(request.url.path.endsWith('/v1/fees/recommended'), isTrue);
        return http.Response(
          jsonEncode({'economyFee': 2, 'hourFee': 5, 'fastestFee': 12}),
          200,
        );
      });
      final service = BitcoinService(client: mock);

      final fees = await service.fetchFeeEstimates();

      expect(fees.lowSatVb, equals(2));
      expect(fees.normalSatVb, equals(5));
      expect(fees.highSatVb, equals(12));
    });

    test('fetchFeeEstimates falls back to defaults when API fails', () async {
      final mock = MockClient((_) async => http.Response('error', 500));
      final service = BitcoinService(client: mock);

      final fees = await service.fetchFeeEstimates();

      expect(fees.lowSatVb, greaterThan(0));
      expect(fees.lowSatVb, lessThanOrEqualTo(fees.highSatVb));
    });

    test('fetchUtxos parses UTXO list and tx script from mocked API', () async {
      final mock = MockClient((request) async {
        if (request.url.path.endsWith('/utxo')) {
          return http.Response(
            jsonEncode([
              {'txid': 'aabbccdd', 'vout': 0, 'value': 5000},
            ]),
            200,
          );
        }
        if (request.url.path.endsWith('/tx/aabbccdd')) {
          return http.Response(
            jsonEncode({
              'vout': [
                {
                  'scriptpubkey': '0014abcd',
                  'scriptpubkey_type': 'v0_p2wpkh',
                  'scriptpubkey_address': 'bc1qtest',
                },
              ],
            }),
            200,
          );
        }
        return http.Response('not found', 404);
      });
      final service = BitcoinService(client: mock);

      final utxos = await service.fetchUtxos('bc1qtest');

      expect(utxos, hasLength(1));
      expect(utxos.first.txid, equals('aabbccdd'));
      expect(utxos.first.vout, equals(0));
      expect(utxos.first.valueSat, equals(5000));
      expect(utxos.first.scriptPubKeyType, equals('v0_p2wpkh'));
      expect(utxos.first.scriptPubKeyAddress, equals('bc1qtest'));
    });

    // ── Coin control (S7): conferme UTXO ──────────────────
    test('fetchUtxos computes real confirmations from tip height', () async {
      final mock = MockClient((request) async {
        if (request.url.path.endsWith('/utxo')) {
          return http.Response(
            jsonEncode([
              {'txid': 'aabbccdd', 'vout': 0, 'value': 5000},
            ]),
            200,
          );
        }
        if (request.url.path.endsWith('/tx/aabbccdd')) {
          return http.Response(
            jsonEncode({
              'status': {'confirmed': true, 'block_height': 100},
              'vout': [
                {
                  'scriptpubkey': '0014abcd',
                  'scriptpubkey_type': 'v0_p2wpkh',
                  'scriptpubkey_address': 'bc1qtest',
                },
              ],
            }),
            200,
          );
        }
        return http.Response('not found', 404);
      });
      final service = BitcoinService(client: mock);

      // PERCHÉ (S7): tipHeight passato esplicitamente → nessuna chiamata
      // extra a /blocks/tip/height nel test.
      final utxos = await service.fetchUtxos('bc1qtest', tipHeight: 104);

      expect(utxos, hasLength(1));
      expect(utxos.first.confirmations, equals(5)); // 104 − 100 + 1
    });

    test('fetchUtxos marks pending UTXO with confirmations 0', () async {
      final mock = MockClient((request) async {
        if (request.url.path.endsWith('/utxo')) {
          return http.Response(
            jsonEncode([
              {'txid': 'aabbccdd', 'vout': 0, 'value': 5000},
            ]),
            200,
          );
        }
        if (request.url.path.endsWith('/tx/aabbccdd')) {
          return http.Response(
            jsonEncode({
              'status': {'confirmed': false},
              'vout': [
                {
                  'scriptpubkey': '0014abcd',
                  'scriptpubkey_type': 'v0_p2wpkh',
                  'scriptpubkey_address': 'bc1qtest',
                },
              ],
            }),
            200,
          );
        }
        return http.Response('not found', 404);
      });
      final service = BitcoinService(client: mock);

      final utxos = await service.fetchUtxos('bc1qtest', tipHeight: 104);

      expect(utxos, hasLength(1));
      expect(utxos.first.confirmations, equals(0));
    });

    test('fetchUtxos falls back to 1 confirmation when tip height unknown',
        () async {
      final mock = MockClient((request) async {
        if (request.url.path.endsWith('/utxo')) {
          return http.Response(
            jsonEncode([
              {'txid': 'aabbccdd', 'vout': 0, 'value': 5000},
            ]),
            200,
          );
        }
        if (request.url.path.endsWith('/tx/aabbccdd')) {
          return http.Response(
            jsonEncode({
              'status': {'confirmed': true, 'block_height': 100},
              'vout': [
                {
                  'scriptpubkey': '0014abcd',
                  'scriptpubkey_type': 'v0_p2wpkh',
                  'scriptpubkey_address': 'bc1qtest',
                },
              ],
            }),
            200,
          );
        }
        // /blocks/tip/height non gestito → 404 → tipHeight null → fallback
        return http.Response('not found', 404);
      });
      final service = BitcoinService(client: mock);

      final utxos = await service.fetchUtxos('bc1qtest');

      expect(utxos, hasLength(1));
      expect(utxos.first.confirmations, equals(1));
    });

    test('fetchUtxos throws on non-200 response', () async {
      final mock = MockClient((_) async => http.Response('error', 500));
      final service = BitcoinService(client: mock);

      await expectLater(
        () => service.fetchUtxos('bc1qtest'),
        throwsA(isA<Exception>()),
      );
    });

    test('broadcastTransaction returns txid on success', () async {
      final mock = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path.endsWith('/tx'), isTrue);
        return http.Response('deadbeef01', 200);
      });
      final service = BitcoinService(client: mock);

      final txid = await service.broadcastTransaction('rawhex');

      expect(txid, equals('deadbeef01'));
    });

    test('broadcastTransaction throws on failure', () async {
      final mock = MockClient((_) async => http.Response('rejected', 400));
      final service = BitcoinService(client: mock);

      await expectLater(
        () => service.broadcastTransaction('rawhex'),
        throwsA(isA<Exception>()),
      );
    });

    test('circuit breaker opens after 3 consecutive failures', () async {
      final mock = MockClient((_) async => http.Response('error', 500));
      final service = BitcoinService(client: mock);

      // 3 fallimenti consecutivi aprono il circuito
      for (var i = 0; i < 3; i++) {
        await expectLater(
          () => service.fetchUtxos('bc1qtest'),
          throwsA(isA<Exception>()),
        );
      }
      // Il quarto tentativo viene respinto subito dal circuit breaker
      await expectLater(
        () => service.fetchUtxos('bc1qtest'),
        throwsA(isA<CircuitBreakerOpenException>()),
      );
    });

    test('broadcast falliti NON aprono il breaker delle letture', () async {
      // POST /tx fallisce, le letture UTXO rispondono OK.
      final mock = MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response('rejected', 500);
        }
        if (request.url.path.endsWith('/utxo')) {
          return http.Response(
            jsonEncode([
              {'txid': 'aabbccdd', 'vout': 0, 'value': 5000},
            ]),
            200,
          );
        }
        if (request.url.path.endsWith('/tx/aabbccdd')) {
          return http.Response(
            jsonEncode({
              'vout': [
                {
                  'scriptpubkey': '0014abcd',
                  'scriptpubkey_type': 'v0_p2wpkh',
                  'scriptpubkey_address': 'bc1qtest',
                },
              ],
            }),
            200,
          );
        }
        return http.Response('not found', 404);
      });
      final service = BitcoinService(client: mock);

      // 3 broadcast falliti aprono SOLO il breaker del broadcast.
      for (var i = 0; i < 3; i++) {
        await expectLater(
          () => service.broadcastTransaction('rawhex'),
          throwsA(isA<Exception>()),
        );
      }
      // Le letture continuano a funzionare (breaker separato).
      final utxos = await service.fetchUtxos('bc1qtest');
      expect(utxos, hasLength(1));
    });

    test('letture fallite NON bloccano il broadcast', () async {
      // GET falliscono, POST /tx risponde OK.
      final mock = MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response('txidOK', 200);
        }
        return http.Response('error', 500);
      });
      final service = BitcoinService(client: mock);

      // 3 letture fallite aprono SOLO il breaker delle letture.
      for (var i = 0; i < 3; i++) {
        await expectLater(
          () => service.fetchUtxos('bc1qtest'),
          throwsA(isA<Exception>()),
        );
      }
      // Il broadcast (breaker dedicato) riesce ancora.
      final txid = await service.broadcastTransaction('rawhex');
      expect(txid, 'txidOK');
    });

    test('buildSignAndSend builds, signs and broadcasts (mock)', () async {
      // PERCHÉ (P1.2): test del flusso critico — selezione UTXO, costruzione
      // transazione, firma e broadcast — interamente deterministico.
      const mnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

      final derived = await bitcoinService
          .deriveWalletDataFromMnemonic(mnemonic, addressCount: 1);
      final firstAddress = derived.addresses.first;
      final ownerPath = '${derived.derivationPath}/0/0';

      final utxo = UtxoInfo(
        txid: 'a' * 64, // txid finto (32 byte hex)
        vout: 0,
        valueSat: 100000,
        scriptPubKeyType: 'v0_p2wpkh',
        ownerAddress: firstAddress,
        ownerDerivationPath: ownerPath,
      );

      final mock = MockClient((request) async {
        if (request.method == 'POST' && request.url.path.endsWith('/tx')) {
          return http.Response('mocktxid123', 200);
        }
        return http.Response('not found', 404);
      });
      final service = BitcoinService(client: mock);

      final result = await service.buildSignAndSend(
        mnemonic: mnemonic,
        toAddress: firstAddress,
        amountSats: 50000,
        feeRateSatVb: 5,
        utxos: [utxo],
        derivationPath: derived.derivationPath,
      );

      expect(result.txid, equals('mocktxid123'));
      expect(result.feePaid, greaterThan(0));
    });

    test('buildSignAndSend throws when no spendable UTXOs', () async {
      const mnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      final derived = await bitcoinService
          .deriveWalletDataFromMnemonic(mnemonic, addressCount: 1);

      // UTXO con tipo p2sh ma script invalido → non spendibile
      final utxo = UtxoInfo(
        txid: 'b' * 64,
        vout: 0,
        valueSat: 100000,
        scriptPubKeyType: 'p2sh',
        scriptPubKeyHex: '0014',
        ownerDerivationPath: '${derived.derivationPath}/0/0',
      );

      final service = BitcoinService(
        client: MockClient((_) async => http.Response('nope', 400)),
      );

      await expectLater(
        () => service.buildSignAndSend(
          mnemonic: mnemonic,
          toAddress: derived.addresses.first,
          amountSats: 50000,
          feeRateSatVb: 5,
          utxos: [utxo],
          derivationPath: derived.derivationPath,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('sweepAll sweeps all spendable UTXOs (mock)', () async {
      const mnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      final derived = await bitcoinService
          .deriveWalletDataFromMnemonic(mnemonic, addressCount: 1);
      final firstAddress = derived.addresses.first;

      final utxo = UtxoInfo(
        txid: 'c' * 64,
        vout: 1,
        valueSat: 500000,
        scriptPubKeyType: 'v0_p2wpkh',
        ownerAddress: firstAddress,
        ownerDerivationPath: '${derived.derivationPath}/0/0',
      );

      final mock = MockClient((request) async {
        if (request.method == 'POST' && request.url.path.endsWith('/tx')) {
          return http.Response('sweeptxid', 200);
        }
        return http.Response('not found', 404);
      });
      final service = BitcoinService(client: mock);

      final result = await service.sweepAll(
        mnemonic: mnemonic,
        toAddress: firstAddress,
        feeRateSatVb: 5,
        utxos: [utxo],
        derivationPath: derived.derivationPath,
      );

      expect(result.txid, equals('sweeptxid'));
      expect(result.feePaid, greaterThan(0));
    });

    test('fetchSpendableWalletUtxos returns empty when API has no UTXOs',
        () async {
      const mnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      final mock = MockClient((request) async {
        if (request.url.path.endsWith('/utxo')) {
          return http.Response('[]', 200);
        }
        return http.Response('{}', 200);
      });
      final service = BitcoinService(client: mock);

      final utxos = await service.fetchSpendableWalletUtxos(
        mnemonic,
        gapLimit: 2,
        maxAddresses: 2,
      );

      expect(utxos, isEmpty);
    });

    test('scanDerivedAddressesForUtxos trova UTXO sulla catena change (/1/0)',
        () async {
      const mnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      // Deriva gli indirizzi (external + change) per costruire il mock.
      final derived = await bitcoinService
          .deriveWalletDataFromMnemonic(mnemonic, addressCount: 1);
      final changeAddr = derived.changeAddresses.first;

      final mock = MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/blocks/tip/height')) {
          return http.Response('100', 200);
        }
        if (path.endsWith('/utxo')) {
          if (path.contains(changeAddr)) {
            return http.Response(
              jsonEncode([
                {
                  'txid': 'a' * 64,
                  'vout': 0,
                  'value': 50000,
                  'status': {'confirmed': true, 'block_height': 90},
                },
              ]),
              200,
            );
          }
          return http.Response('[]', 200);
        }
        if (path.endsWith('/tx/${'a' * 64}')) {
          return http.Response(
            jsonEncode({
              'txid': 'a' * 64,
              'vout': [
                {
                  'scriptpubkey': '0014${'00' * 20}',
                  'scriptpubkey_type': 'v0_p2wpkh',
                  'scriptpubkey_address': changeAddr,
                  'value': 50000,
                },
              ],
              'status': {'confirmed': true, 'block_height': 90},
            }),
            200,
          );
        }
        return http.Response('not found', 404);
      });
      final service = BitcoinService(client: mock);

      final found = await service.scanDerivedAddressesForUtxos(
        mnemonic,
        gapLimit: 1,
        maxAddresses: 1,
      );

      expect(found.containsKey(changeAddr), isTrue);
      final utxos = found[changeAddr]!;
      expect(utxos, hasLength(1));
      // PERCHÉ: il ramo /1 è obbligatorio per firmare UTXO di change.
      expect(utxos.first.ownerDerivationPath, endsWith('/1/0'));
    });

    test('scanDerivedAddressesForUtxos si ferma dopo il gap-limit', () async {
      const mnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      var utxoCalls = 0;
      final mock = MockClient((request) async {
        if (request.url.path.endsWith('/blocks/tip/height')) {
          return http.Response('100', 200);
        }
        if (request.url.path.endsWith('/utxo')) {
          utxoCalls++;
          return http.Response('[]', 200);
        }
        return http.Response('not found', 404);
      });
      final service = BitcoinService(client: mock);

      final found = await service.scanDerivedAddressesForUtxos(
        mnemonic,
        gapLimit: 2,
        maxAddresses: 100,
      );

      expect(found, isEmpty);
      // PERCHÉ: gapLimit=2 → 2 indirizzi vuoti per catena (2 external + 2
      // change) = 4 chiamate /utxo totali; nessuna scansione oltre il gap.
      expect(utxoCalls, lessThanOrEqualTo(4));
    });

    test('scanDerivedAddressesForUtxos propaga l\'errore UTXO (mai vuoto finto)',
        () async {
      // PERCHÉ (F5): un errore su /utxo non equivale a "indirizzo vuoto" —
      // mascherarlo produrrebbe un saldo 0/parziale presentato come vero.
      const mnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      final mock = MockClient((request) async {
        if (request.url.path.endsWith('/blocks/tip/height')) {
          return http.Response('100', 200);
        }
        if (request.url.path.endsWith('/utxo')) {
          return http.Response('error', 500);
        }
        return http.Response('not found', 404);
      });
      final service = BitcoinService(client: mock);

      await expectLater(
        service.scanDerivedAddressesForUtxos(
          mnemonic,
          gapLimit: 2,
          maxAddresses: 2,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('fetchWalletBalance somma UTXO di external e change', () async {
      const mnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      final derived = await bitcoinService
          .deriveWalletDataFromMnemonic(mnemonic, addressCount: 1);
      final extAddr = derived.addresses.first;
      final changeAddr = derived.changeAddresses.first;

      final mock = MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/blocks/tip/height')) {
          return http.Response('100', 200);
        }
        if (path.endsWith('/utxo')) {
          if (path.contains(extAddr)) {
            return http.Response(
              jsonEncode([
                {'txid': 'a' * 64, 'vout': 0, 'value': 50000},
              ]),
              200,
            );
          }
          if (path.contains(changeAddr)) {
            return http.Response(
              jsonEncode([
                {'txid': 'b' * 64, 'vout': 0, 'value': 30000},
              ]),
              200,
            );
          }
          return http.Response('[]', 200);
        }
        if (path.endsWith('/tx/${'a' * 64}') ||
            path.endsWith('/tx/${'b' * 64}')) {
          return http.Response(
            jsonEncode({
              'txid': path.endsWith('/tx/${'a' * 64}') ? 'a' * 64 : 'b' * 64,
              'vout': [
                {
                  'scriptpubkey': '0014${'00' * 20}',
                  'scriptpubkey_type': 'v0_p2wpkh',
                  'scriptpubkey_address': extAddr,
                  'value': 50000,
                },
              ],
              'status': {'confirmed': true, 'block_height': 90},
            }),
            200,
          );
        }
        return http.Response('not found', 404);
      });
      final service = BitcoinService(client: mock);

      final balance = await service.fetchWalletBalance(
        mnemonic,
        gapLimit: 1,
        maxAddresses: 1,
      );

      // PERCHÉ: saldo = Σ UTXO su entrambe le catene (external 50k + change
      // 30k) — come calcola BlueWallet.
      expect(balance.balanceSats, 80000);
      expect(balance.txCount, 2);
    });
  });

  group('BitcoinService - Transaction history (Esplora)', () {
    const addr = 'tb1qqws3aatj6jz2nz8d7zefwmtmcccx4umlc5ygr7';

    Map<String, dynamic> txJson({
      required String txid,
      required String voutAddress,
      bool confirmed = true,
      int? blockHeight = 149987,
      int? blockTime = 1787842810,
    }) {
      return {
        'txid': txid,
        'fee': 51000,
        'vin': [
          {
            'txid': 'b' * 64,
            'vout': 0,
            'prevout': {
              'value': 3700000,
              'scriptpubkey_address': 'tb1qother000000000000000000000000',
            },
          },
        ],
        'vout': [
          {'value': 3645814, 'scriptpubkey_address': voutAddress},
        ],
        'status': {
          'confirmed': confirmed,
          if (blockHeight != null) 'block_height': blockHeight,
          if (blockTime != null) 'block_time': blockTime,
        },
      };
    }

    test('fetchTransactionHistory parses tx with real confirmations', () async {
      final mock = MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/blocks/tip/height')) {
          return http.Response('149990', 200);
        }
        if (path.endsWith('/address/$addr/txs')) {
          return http.Response(
            jsonEncode([txJson(txid: 'a' * 64, voutAddress: addr)]),
            200,
          );
        }
        return http.Response('not found', 404);
      });
      final service = BitcoinService(client: mock);

      final txs = await service.fetchTransactionHistory(addr);

      expect(txs, hasLength(1));
      expect(txs.first.txid, 'a' * 64);
      expect(txs.first.direction, TxDirection.incoming);
      expect(txs.first.amountSats, 3645814);
      expect(txs.first.feeSats, 51000);
      expect(txs.first.confirmations, 4); // 149990 − 149987 + 1
    });

    test('fetchTransactionHistory returns empty on API error', () async {
      final mock = MockClient((_) async => http.Response('error', 500));
      final service = BitcoinService(client: mock);

      final txs = await service.fetchTransactionHistory(addr);

      expect(txs, isEmpty);
    });

    test('fetchTransactionHistory returns empty on empty array', () async {
      final mock = MockClient((request) async {
        if (request.url.path.endsWith('/blocks/tip/height')) {
          return http.Response('149990', 200);
        }
        return http.Response('[]', 200);
      });
      final service = BitcoinService(client: mock);

      final txs = await service.fetchTransactionHistory(addr);

      expect(txs, isEmpty);
    });

    test('fetchTransactionHistory handles coinbase address gracefully',
        () async {
      // // PERCHÉ: l'API reale restituisce errore per indirizzi coinbase —
      // il servizio non deve lanciare ma ritornare lista vuota.
      final mock = MockClient((request) async {
        if (request.url.path.endsWith('/blocks/tip/height')) {
          return http.Response('149990', 200);
        }
        return http.Response(
          '{"error":"Failed to get address transactions"}',
          500,
        );
      });
      final service = BitcoinService(client: mock);

      final txs = await service.fetchTransactionHistory(addr);

      expect(txs, isEmpty);
    });

    test('fetchWalletHistory dedups txids across derived addresses', () async {
      const mnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      // Deriva gli indirizzi per costruire il mock (stessa logica del servizio).
      final derived = await bitcoinService
          .deriveWalletDataFromMnemonic(mnemonic, addressCount: 2);
      final firstAddr = derived.addresses.first;

      final mock = MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/blocks/tip/height')) {
          return http.Response('149990', 200);
        }
        if (path.endsWith('/txs')) {
          // Stessa tx restituita per OGNI indirizzo derivato → deve essere
          // deduplicata per txid.
          return http.Response(
            jsonEncode([txJson(txid: 'a' * 64, voutAddress: firstAddr)]),
            200,
          );
        }
        return http.Response('not found', 404);
      });
      final service = BitcoinService(client: mock);

      final txs = await service.fetchWalletHistory(
        mnemonic,
        gapLimit: 2,
        maxAddresses: 2,
      );

      // Dedup: 2 indirizzi → 1 sola transazione.
      expect(txs, hasLength(1));
      expect(txs.first.txid, 'a' * 64);
      expect(txs.first.direction, TxDirection.incoming);
      expect(txs.first.amountSats, 3645814);
    });

    test('fetchWalletHistory riconosce il change nel netto outgoing', () async {
      const mnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      final derived = await bitcoinService
          .deriveWalletDataFromMnemonic(mnemonic, addressCount: 1);
      final extAddr = derived.addresses.first;
      final changeAddr = derived.changeAddresses.first;

      // Spesa reale: vin da external (100000) → vout a destinatario (10000,
      // NON nostro) + change a changeAddr (90000, nostro).
      final tx = {
        'txid': 'd' * 64,
        'fee': 0,
        'vin': [
          {
            'txid': 'e' * 64,
            'vout': 0,
            'prevout': {
              'value': 100000,
              'scriptpubkey_address': extAddr,
            },
          },
        ],
        'vout': [
          {
            'value': 10000,
            'scriptpubkey_address': 'bc1qrecipient00000000000000000000000',
          },
          {'value': 90000, 'scriptpubkey_address': changeAddr},
        ],
        'status': {
          'confirmed': true,
          'block_height': 100,
          'block_time': 1787842810,
        },
      };

      final mock = MockClient((request) async {
        if (request.url.path.endsWith('/blocks/tip/height')) {
          return http.Response('101', 200);
        }
        if (request.url.path.endsWith('/txs')) {
          return http.Response(jsonEncode([tx]), 200);
        }
        return http.Response('not found', 404);
      });
      final service = BitcoinService(client: mock);

      final txs = await service.fetchWalletHistory(
        mnemonic,
        gapLimit: 2,
        maxAddresses: 2,
      );

      expect(txs, hasLength(1));
      expect(txs.first.direction, TxDirection.outgoing);
      // PERCHÉ: netto = ricevuto (90000 change riconosciuto) − speso (100000)
      // = −10000 → outgoing 10000 (non lordo 100000 come senza change).
      expect(txs.first.amountSats, 10000);
    });
  });
}
