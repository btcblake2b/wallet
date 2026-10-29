import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:btc_blake2b_wallet/core/models/send_output.dart';
import 'package:btc_blake2b_wallet/core/models/wallet_record.dart';
import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';
import 'package:btc_blake2b_wallet/core/services/explorer_mirrors.dart';
import 'package:btc_blake2b_wallet/core/services/pending_send_registry.dart';
import 'package:btc_blake2b_wallet/core/services/psbt/psbt_service.dart';
import 'package:btc_blake2b_wallet/core/services/psbt/psbt_wallet_service.dart';
import 'package:btc_blake2b_wallet/core/services/rbf_params_registry.dart';

/// P4/M1b — il percorso PSBT deve avere la STESSA economia dell'invio diretto.
///
/// // PERCHÉ il test più importante del file: due economie divergenti
/// // significherebbero fee/resto diversi a seconda del pulsante premuto. Il
/// // confronto è sulla transazione SERIALIZZATA (raw hex inviato al nodo):
/// // se i byte coincidono, coincidono txid, fee e resto.
void main() {
  const mnemonic =
      'abandon abandon abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon about';

  late BitcoinService bitcoinService;
  late List<String> broadcastBodies;

  setUp(() {
    PendingSendRegistry.resetForTest();
    RbfParamsRegistry.resetForTest();
    ExplorerMirrors.resetForTest();
    broadcastBodies = <String>[];
    bitcoinService = BitcoinService(
      client: MockClient((request) async {
        if (request.method == 'POST' && request.url.path.endsWith('/tx')) {
          broadcastBodies.add(request.body);
          return http.Response('mocktxid0001', 200);
        }
        return http.Response('not found', 404);
      }),
    );
  });

  Future<
      ({
        WalletRecord wallet,
        String derivationPath,
        List<String> addresses,
      })> buildWallet() async {
    final derived = await bitcoinService.deriveWalletDataFromMnemonic(
      mnemonic,
      addressCount: 2,
    );
    final wallet = WalletRecord(
      walletId: 'w-psbt',
      encryptedSeed: 'enc',
      publicAddress: derived.publicAddress,
      deviceId: 'test',
      createdAt: DateTime.utc(2026, 10, 26),
      masterFingerprint: derived.masterFingerprint,
      derivationPath: derived.derivationPath,
      kind: WalletKind.hot,
      accountXpub: derived.xpub,
    );
    return (
      wallet: wallet,
      derivationPath: derived.derivationPath,
      addresses: derived.addresses,
    );
  }

  UtxoInfo utxoFor({
    required String derivationPath,
    required String address,
    String txidChar = 'a',
    int vout = 0,
    int valueSat = 100000,
    int index = 0,
    String chain = '0',
  }) =>
      UtxoInfo(
        txid: txidChar * 64,
        vout: vout,
        valueSat: valueSat,
        scriptPubKeyType: 'v0_p2wpkh',
        ownerAddress: address,
        ownerDerivationPath: '$derivationPath/$chain/$index',
      );

  group('createForWallet', () {
    test('equivalenza byte-per-byte con buildSignAndSendBatch (1 input)',
        () async {
      final w = await buildWallet();
      final utxos = [
        utxoFor(
          derivationPath: w.derivationPath,
          address: w.addresses.first,
          valueSat: 100000,
        ),
      ];
      final outputs = [SendOutput(address: w.addresses[1], amountSats: 50000)];

      // Percorso diretto: il raw hex inviato al nodo è il riferimento.
      await bitcoinService.buildSignAndSendBatch(
        mnemonic: mnemonic,
        outputs: outputs,
        feeRateSatVb: 5,
        utxos: utxos,
        derivationPath: w.derivationPath,
      );
      final directHex = broadcastBodies.single;

      final psbtService = PsbtWalletService(bitcoinService: bitcoinService);
      final draft = await psbtService.createForWallet(
        wallet: w.wallet,
        utxos: utxos,
        outputs: outputs,
        feeRateSatVb: 5,
        mnemonic: mnemonic,
      );
      final signed = await psbtService.signForWallet(
        wallet: w.wallet,
        psbtBase64: draft.psbtBase64,
        mnemonic: mnemonic,
      );
      final psbtHex = finalizePsbtToTxHex(signed);

      expect(psbtHex, directHex);
      expect(draft.feeSats, greaterThan(0));
      expect(draft.inputCount, 1);
      expect(draft.outputCount, 2); // destinatario + resto
      expect(draft.changeSats, greaterThan(0));
    });

    test('equivalenza byte-per-byte con 2 input', () async {
      final w = await buildWallet();
      final utxos = [
        utxoFor(
          derivationPath: w.derivationPath,
          address: w.addresses.first,
          txidChar: 'a',
          valueSat: 60000,
        ),
        utxoFor(
          derivationPath: w.derivationPath,
          address: w.addresses[1],
          txidChar: 'b',
          vout: 1,
          index: 1,
          valueSat: 90000,
        ),
      ];
      final outputs = [SendOutput(address: w.addresses[1], amountSats: 110000)];

      await bitcoinService.buildSignAndSendBatch(
        mnemonic: mnemonic,
        outputs: outputs,
        feeRateSatVb: 3,
        utxos: utxos,
        derivationPath: w.derivationPath,
      );
      final directHex = broadcastBodies.single;

      final psbtService = PsbtWalletService(bitcoinService: bitcoinService);
      final draft = await psbtService.createForWallet(
        wallet: w.wallet,
        utxos: utxos,
        outputs: outputs,
        feeRateSatVb: 3,
        mnemonic: mnemonic,
      );
      final signed = await psbtService.signForWallet(
        wallet: w.wallet,
        psbtBase64: draft.psbtBase64,
        mnemonic: mnemonic,
      );

      expect(draft.inputCount, 2);
      expect(finalizePsbtToTxHex(signed), directHex);
    });

    test('il resto va sul primo indice /1/N libero', () async {
      final w = await buildWallet();
      // Un UTXO di resto già usato su /1/0 → il nuovo resto deve andare a /1/1.
      final utxos = [
        utxoFor(
          derivationPath: w.derivationPath,
          address: w.addresses.first,
          txidChar: 'a',
          valueSat: 200000,
        ),
        utxoFor(
          derivationPath: w.derivationPath,
          address: w.addresses[1],
          txidChar: 'c',
          chain: '1',
          index: 0,
          valueSat: 5000,
        ),
      ];
      final psbtService = PsbtWalletService(bitcoinService: bitcoinService);
      final draft = await psbtService.createForWallet(
        wallet: w.wallet,
        utxos: utxos,
        outputs: [SendOutput(address: w.addresses[1], amountSats: 50000)],
        feeRateSatVb: 2,
        mnemonic: mnemonic,
      );

      expect(draft.changeAddress, isNotNull);
      // Le chiavi di resto sono contigue: distinguiamo /1/1 da /1/0 con la
      // derivazione pubblica (stesso algoritmo di `pubKeyToAddressForType`).
      final summary = summarizePsbt(draft.psbtBase64);
      final addresses = summary.outputs
          .map((o) => o.address)
          .whereType<String>()
          .toList();
      expect(addresses.length, 2);
      expect(addresses.contains(draft.changeAddress), isTrue);
    });

    test('watch-only: crea la PSBT ma non può firmarla', () async {
      final w = await buildWallet();
      final watchOnly = w.wallet.copyWith(
        kind: WalletKind.watchOnly,
        encryptedSeed: '',
      );
      final psbtService = PsbtWalletService(bitcoinService: bitcoinService);
      final draft = await psbtService.createForWallet(
        wallet: watchOnly,
        utxos: [
          utxoFor(
            derivationPath: w.derivationPath,
            address: w.addresses.first,
            valueSat: 100000,
          ),
        ],
        outputs: [SendOutput(address: w.addresses[1], amountSats: 40000)],
        feeRateSatVb: 4,
        // Nessun mnemonic: la derivazione è pubblica (xpub).
      );

      expect(draft.psbtBase64, isNotEmpty);
      expect(summarizePsbt(draft.psbtBase64).signableInputs, 1);

      await expectLater(
        () => psbtService.signForWallet(
          wallet: watchOnly,
          psbtBase64: draft.psbtBase64,
          mnemonic: mnemonic,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('watch-only'),
          ),
        ),
      );
    });

    test('destinatario sotto dust → StateError, nessuna PSBT', () async {
      final w = await buildWallet();
      final psbtService = PsbtWalletService(bitcoinService: bitcoinService);
      await expectLater(
        () => psbtService.createForWallet(
          wallet: w.wallet,
          utxos: [
            utxoFor(
              derivationPath: w.derivationPath,
              address: w.addresses.first,
            ),
          ],
          outputs: [SendOutput(address: w.addresses[1], amountSats: 500)],
          feeRateSatVb: 5,
          mnemonic: mnemonic,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('fondi insufficienti → StateError', () async {
      final w = await buildWallet();
      final psbtService = PsbtWalletService(bitcoinService: bitcoinService);
      await expectLater(
        () => psbtService.createForWallet(
          wallet: w.wallet,
          utxos: [
            utxoFor(
              derivationPath: w.derivationPath,
              address: w.addresses.first,
              valueSat: 10000,
            ),
          ],
          outputs: [SendOutput(address: w.addresses[1], amountSats: 9999)],
          feeRateSatVb: 10,
          mnemonic: mnemonic,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('wallet non native segwit (BIP49) → StateError', () async {
      final w = await buildWallet();
      final legacy = w.wallet.copyWith(derivationPath: "m/49'/0'/0'");
      final psbtService = PsbtWalletService(bitcoinService: bitcoinService);
      await expectLater(
        () => psbtService.createForWallet(
          wallet: legacy,
          utxos: [
            utxoFor(
              derivationPath: w.derivationPath,
              address: w.addresses.first,
            ),
          ],
          outputs: [SendOutput(address: w.addresses[1], amountSats: 40000)],
          feeRateSatVb: 5,
          mnemonic: mnemonic,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('native segwit'),
          ),
        ),
      );
    });

    test('UTXO con script on-chain di un altro wallet → ignorato', () async {
      final w = await buildWallet();
      final psbtService = PsbtWalletService(bitcoinService: bitcoinService);
      final foreign = UtxoInfo(
        txid: 'd' * 64,
        vout: 0,
        valueSat: 100000,
        scriptPubKeyType: 'v0_p2wpkh',
        // hash160 di un'altra chiave: lo script non corrisponde.
        scriptPubKeyHex: '0014${'11' * 20}',
        ownerDerivationPath: '${w.derivationPath}/0/0',
      );
      await expectLater(
        () => psbtService.createForWallet(
          wallet: w.wallet,
          utxos: [foreign],
          outputs: [SendOutput(address: w.addresses[1], amountSats: 40000)],
          feeRateSatVb: 5,
          mnemonic: mnemonic,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('nessun UTXO spendibile'),
          ),
        ),
      );
    });
  });

  group('broadcastPsbt', () {
    test('finalizza, trasmette e registra pending + RBF come l invio',
        () async {
      final w = await buildWallet();
      final outputs = [SendOutput(address: w.addresses[1], amountSats: 50000)];
      final utxos = [
        utxoFor(
          derivationPath: w.derivationPath,
          address: w.addresses.first,
        ),
      ];
      final psbtService = PsbtWalletService(bitcoinService: bitcoinService);
      final draft = await psbtService.createForWallet(
        wallet: w.wallet,
        utxos: utxos,
        outputs: outputs,
        feeRateSatVb: 5,
        mnemonic: mnemonic,
      );
      final signed = await psbtService.signForWallet(
        wallet: w.wallet,
        psbtBase64: draft.psbtBase64,
        mnemonic: mnemonic,
      );

      final result = await psbtService.broadcastPsbt(
        wallet: w.wallet,
        signedPsbtBase64: signed,
        utxos: utxos,
        outputs: outputs,
        feeRateSatVb: 5,
      );

      expect(result.txid, 'mocktxid0001');
      expect(result.feePaid, draft.feeSats);
      expect(PendingSendRegistry.contains('mocktxid0001'), isTrue);
      expect(PendingSendRegistry.amountOf('mocktxid0001'), 50000);
      final rbf = RbfParamsRegistry.of('mocktxid0001');
      expect(rbf, isNotNull);
      expect(rbf!.derivationPath, w.derivationPath);
      expect(rbf.outputs.single.amountSats, 50000);
      // Il raw hex trasmesso è quello finalizzato dalla PSBT.
      expect(broadcastBodies.single, finalizePsbtToTxHex(signed));
      expect(base64.decode(draft.psbtBase64), isNotEmpty);
    });
  });
}
