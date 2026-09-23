import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:btc_blake2b_wallet/core/models/send_output.dart';
import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';
import 'package:btc_blake2b_wallet/core/services/explorer_mirrors.dart';
import 'package:btc_blake2b_wallet/core/services/pending_send_registry.dart';
import 'package:btc_blake2b_wallet/core/services/rbf_params_registry.dart';

/// Test del batch send (P3): più destinatari in UNA transazione.
///
/// // PERCHÉ: il rischio di P3 è duplice — (a) fee/change calcolati su un
/// // numero di output sbagliato (fee sottostimata = tx sotto il min-relay),
/// // (b) regressione sul percorso singolo. Qui si verifica la matematica
/// // (output count → vB), i casi limite (dust, fondi, change) e
/// // l'EQUIVALENZA tra N=1 e il percorso storico.
void main() {
  const mnemonic =
      'abandon abandon abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon about';

  setUp(() {
    ExplorerMirrors.resetForTest();
    PendingSendRegistry.resetForTest();
    RbfParamsRegistry.resetForTest();
  });

  /// Service il cui broadcast POST cattura l'hex trasmesso.
  ({BitcoinService service, List<String> sentHex}) serviceCapturingHex() {
    final sentHex = <String>[];
    final mock = MockClient((request) async {
      if (request.method == 'POST' && request.url.path.endsWith('/tx')) {
        sentHex.add(request.body);
        return http.Response('mocktxid123', 200);
      }
      return http.Response('not found', 404);
    });
    return (service: BitcoinService(client: mock), sentHex: sentHex);
  }

  /// Importi (sat) degli output della tx trasmessa, nell'ordine di costruzione
  /// (prima i destinatari, poi l'eventuale change).
  List<BigInt> amountsOf(String hex) {
    final tx = BtcTransaction.deserialize(BytesUtils.fromHexString(hex));
    return [for (final o in tx.outputs) o.amount];
  }

  Future<({String derivationPath, List<String> addresses})> fixture(
    int count,
  ) async {
    final derived = await BitcoinService().deriveWalletDataFromMnemonic(
      mnemonic,
      addressCount: count,
    );
    return (derivationPath: derived.derivationPath, addresses: derived.addresses);
  }

  UtxoInfo spendableUtxo({
    required int valueSat,
    required String ownerAddress,
    required String ownerPath,
  }) {
    return UtxoInfo(
      txid: 'a' * 64,
      vout: 0,
      valueSat: valueSat,
      scriptPubKeyType: 'v0_p2wpkh',
      ownerAddress: ownerAddress,
      ownerDerivationPath: ownerPath,
    );
  }

  group('estimateTxVbytes con N output', () {
    test('1 input p2wpkh + 3 output = 210 vB', () {
      final utxo = UtxoInfo(
        txid: 'a' * 64,
        vout: 0,
        valueSat: 100000,
        scriptPubKeyType: 'v0_p2wpkh',
      );
      // 10 base + 68 input + 3 (witness marker) + 43*3 output (caso peggiore)
      expect(estimateTxVbytes([utxo], 3), 210);
      // il caso singolo resta invariato: 10 + 68 + 3 + 43*2 = 167
      expect(estimateTxVbytes([utxo], 2), 167);
    });
  });

  group('buildSignAndSendBatch', () {
    test('2 destinatari → 3 output (2 pagamenti + change) e fee unica',
        () async {
      final f = await fixture(3);
      final utxo = spendableUtxo(
        valueSat: 200000,
        ownerAddress: f.addresses[0],
        ownerPath: '${f.derivationPath}/0/0',
      );
      final cap = serviceCapturingHex();

      final result = await cap.service.buildSignAndSendBatch(
        mnemonic: mnemonic,
        outputs: [
          SendOutput(address: f.addresses[1], amountSats: 60000),
          SendOutput(address: f.addresses[2], amountSats: 40000),
        ],
        feeRateSatVb: 1,
        utxos: [utxo],
        derivationPath: f.derivationPath,
      );

      expect(result.txid, 'mocktxid123');
      final amounts = amountsOf(cap.sentHex.single);
      // Output nell'ordine della lista: destinatario 1, destinatario 2, change.
      expect(amounts, hasLength(3)); // 2 destinatari + change
      expect(amounts[0], BigInt.from(60000));
      expect(amounts[1], BigInt.from(40000));
      // change = 200000 - 100000 - fee. Con 2 destinatari + change = 3 output
      // → 10 + 68 + 3 + 43*3 = 210 vB → fee 210 sat a 1 sat/vB.
      expect(amounts[2], BigInt.from(99790));
      expect(result.feePaid, 210);
    });

    test('un importo sotto dust viene rifiutato PRIMA della firma', () async {
      final f = await fixture(2);
      final utxo = spendableUtxo(
        valueSat: 100000,
        ownerAddress: f.addresses[0],
        ownerPath: '${f.derivationPath}/0/0',
      );
      final cap = serviceCapturingHex();

      expect(
        () => cap.service.buildSignAndSendBatch(
          mnemonic: mnemonic,
          outputs: [
            SendOutput(address: f.addresses[1], amountSats: 50000),
            SendOutput(address: f.addresses[0], amountSats: 400), // dust
          ],
          feeRateSatVb: 1,
          utxos: [utxo],
          derivationPath: f.derivationPath,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(cap.sentHex, isEmpty); // nessuna tx trasmessa
    });

    test('lista vuota rifiutata', () async {
      final f = await fixture(1);
      final cap = serviceCapturingHex();
      expect(
        () => cap.service.buildSignAndSendBatch(
          mnemonic: mnemonic,
          outputs: const [],
          feeRateSatVb: 1,
          utxos: <UtxoInfo>[],
          derivationPath: f.derivationPath,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fondi insufficienti per il totale + fee', () async {
      final f = await fixture(2);
      final utxo = spendableUtxo(
        valueSat: 100000,
        ownerAddress: f.addresses[0],
        ownerPath: '${f.derivationPath}/0/0',
      );
      final cap = serviceCapturingHex();

      expect(
        () => cap.service.buildSignAndSendBatch(
          mnemonic: mnemonic,
          outputs: [
            SendOutput(address: f.addresses[1], amountSats: 99999),
          ],
          feeRateSatVb: 10,
          utxos: [utxo],
          derivationPath: f.derivationPath,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('change sotto dust → nessun output di change (residuo in fee)',
        () async {
      final f = await fixture(2);
      final utxo = spendableUtxo(
        valueSat: 100000,
        ownerAddress: f.addresses[0],
        ownerPath: '${f.derivationPath}/0/0',
      );
      final cap = serviceCapturingHex();

      await cap.service.buildSignAndSendBatch(
        mnemonic: mnemonic,
        outputs: [
          SendOutput(address: f.addresses[1], amountSats: 99600),
        ],
        feeRateSatVb: 1,
        utxos: [utxo],
        derivationPath: f.derivationPath,
      );

      final amounts = amountsOf(cap.sentHex.single);
      expect(amounts, hasLength(1)); // nessun change
      expect(amounts.single, BigInt.from(99600));
    });

    test('registra il TOTALE nel PendingSendRegistry e i destinatari in RBF',
        () async {
      final f = await fixture(3);
      final utxo = spendableUtxo(
        valueSat: 200000,
        ownerAddress: f.addresses[0],
        ownerPath: '${f.derivationPath}/0/0',
      );
      final cap = serviceCapturingHex();

      await cap.service.buildSignAndSendBatch(
        mnemonic: mnemonic,
        outputs: [
          SendOutput(address: f.addresses[1], amountSats: 60000),
          SendOutput(address: f.addresses[2], amountSats: 40000),
        ],
        feeRateSatVb: 1,
        utxos: [utxo],
        derivationPath: f.derivationPath,
      );

      // La riga sintetica in UI mostra il totale inviato.
      expect(PendingSendRegistry.amountOf('mocktxid123'), 100000);

      // La sostitutiva RBF deve ripagare ENTRAMBI i destinatari.
      final params = RbfParamsRegistry.of('mocktxid123');
      expect(params, isNotNull);
      expect(params!.effectiveOutputs, hasLength(2));
      expect(params.effectiveOutputs.map((o) => o.amountSats), [60000, 40000]);
    });
  });

  group('equivalenza N=1 con il percorso storico', () {
    test('buildSignAndSend ≡ buildSignAndSendBatch con un solo destinatario',
        () async {
      final f = await fixture(2);
      final utxo = spendableUtxo(
        valueSat: 100000,
        ownerAddress: f.addresses[0],
        ownerPath: '${f.derivationPath}/0/0',
      );

      final single = serviceCapturingHex();
      final singleResult = await single.service.buildSignAndSend(
        mnemonic: mnemonic,
        toAddress: f.addresses[1],
        amountSats: 50000,
        feeRateSatVb: 1,
        utxos: [utxo],
        derivationPath: f.derivationPath,
      );

      final batch = serviceCapturingHex();
      final batchResult = await batch.service.buildSignAndSendBatch(
        mnemonic: mnemonic,
        outputs: [SendOutput(address: f.addresses[1], amountSats: 50000)],
        feeRateSatVb: 1,
        utxos: [utxo],
        derivationPath: f.derivationPath,
      );

      // PERCHÉ: gli output NON contengono firme → confronto deterministico
      // anche se il nonce ECDSA non fosse riproducibile.
      expect(amountsOf(batch.sentHex.single), amountsOf(single.sentHex.single));
      expect(batchResult.feePaid, singleResult.feePaid);
      // 10 + 68 + 3 + 43*2 = 167 vB
      expect(singleResult.feePaid, 167);
    });
  });
}
