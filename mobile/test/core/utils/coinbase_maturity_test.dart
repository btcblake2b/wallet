import 'package:btc_blake2b_wallet/core/config/bitcoin_network_config.dart';
import 'package:btc_blake2b_wallet/core/models/utxo_info.dart';
import 'package:btc_blake2b_wallet/core/utils/coinbase_maturity.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regole verificate (fonte: PR `privkeyio/lightning#11`, release CLN
/// `v26.06.8-blake2b.5`): un output coinbase non è propagabile prima della
/// maturity di relay della rete (6.480 blocchi sulla mainnet blake2b).
void main() {
  group('isCoinbaseRelayable', () {
    const maturity = 6480;

    test('una tx normale è sempre propagabile (anche senza conferme)', () {
      expect(
        isCoinbaseRelayable(
          isCoinbase: false,
          confirmations: null,
          maturityBlocks: maturity,
        ),
        isTrue,
      );
      expect(
        isCoinbaseRelayable(
          isCoinbase: false,
          confirmations: 0,
          maturityBlocks: maturity,
        ),
        isTrue,
      );
    });

    test('coinbase appena minata → non propagabile', () {
      expect(
        isCoinbaseRelayable(
          isCoinbase: true,
          confirmations: 1,
          maturityBlocks: maturity,
        ),
        isFalse,
      );
    });

    test('edge: un blocco sotto la soglia → non propagabile', () {
      expect(
        isCoinbaseRelayable(
          isCoinbase: true,
          confirmations: maturity - 1,
          maturityBlocks: maturity,
        ),
        isFalse,
      );
    });

    test('edge: esattamente alla soglia → propagabile', () {
      expect(
        isCoinbaseRelayable(
          isCoinbase: true,
          confirmations: maturity,
          maturityBlocks: maturity,
        ),
        isTrue,
      );
    });

    test('coinbase con conferme ignote (API fallita) → prudente: no', () {
      expect(
        isCoinbaseRelayable(
          isCoinbase: true,
          confirmations: null,
          maturityBlocks: maturity,
        ),
        isFalse,
      );
    });

    test('rete senza regola (maturity 0) → propagabile sempre', () {
      expect(
        isCoinbaseRelayable(
          isCoinbase: true,
          confirmations: 1,
          maturityBlocks: 0,
        ),
        isTrue,
      );
    });
  });

  group('isUtxoRelayable', () {
    UtxoInfo utxo({required bool isCoinbase, required int? confirmations}) {
      return UtxoInfo(
        txid:
            '85e9064be6d7623853fe60fc75dbefdfe4478ce35683549e59e8ad6cda25cd40',
        vout: 1,
        valueSat: 13973,
        confirmations: confirmations,
        isCoinbase: isCoinbase,
      );
    }

    test('UTXO normale → spendibile', () {
      expect(
        isUtxoRelayable(utxo(isCoinbase: false, confirmations: 1)),
        isTrue,
      );
    });

    test('payout di mining non maturo → escluso dal coin selection', () {
      expect(
        isUtxoRelayable(
          utxo(isCoinbase: true, confirmations: 600),
          maturityBlocks: 6480,
        ),
        isFalse,
      );
    });

    test('payout di mining maturo → spendibile', () {
      expect(
        isUtxoRelayable(
          utxo(isCoinbase: true, confirmations: 6480),
          maturityBlocks: 6480,
        ),
        isTrue,
      );
    });

    test('default = maturity della rete corrente (mainnet 6.480)', () {
      expect(BitcoinNetworkConfig.coinbaseRelayMaturityBlocks, 6480);
      expect(
        isUtxoRelayable(utxo(isCoinbase: true, confirmations: 6479)),
        isFalse,
      );
      expect(
        isUtxoRelayable(utxo(isCoinbase: true, confirmations: 6480)),
        isTrue,
      );
    });
  });

  group('remainingRelayBlocks', () {
    UtxoInfo utxo({
      required bool isCoinbase,
      required int? confirmations,
      int valueSat = 13973,
    }) {
      return UtxoInfo(
        txid:
            '85e9064be6d7623853fe60fc75dbefdfe4478ce35683549e59e8ad6cda25cd40',
        vout: 1,
        valueSat: valueSat,
        confirmations: confirmations,
        isCoinbase: isCoinbase,
      );
    }

    test('tx normale → gia spendibile (0 blocchi)', () {
      expect(
        remainingRelayBlocks(
          utxo(isCoinbase: false, confirmations: null),
          maturityBlocks: 6480,
        ),
        0,
      );
    });

    test('coinbase non matura → blocchi mancanti (countdown)', () {
      expect(
        remainingRelayBlocks(
          utxo(isCoinbase: true, confirmations: 600),
          maturityBlocks: 6480,
        ),
        5880,
      );
    });

    test('coinbase matura → 0', () {
      expect(
        remainingRelayBlocks(
          utxo(isCoinbase: true, confirmations: 6480),
          maturityBlocks: 6480,
        ),
        0,
      );
    });

    test('coinbase con conferme ignote → null: nessun countdown inventato', () {
      expect(
        remainingRelayBlocks(
          utxo(isCoinbase: true, confirmations: null),
          maturityBlocks: 6480,
        ),
        isNull,
      );
    });

    test('rete senza regola (maturity 0) → 0', () {
      expect(
        remainingRelayBlocks(
          utxo(isCoinbase: true, confirmations: 1),
          maturityBlocks: 0,
        ),
        0,
      );
    });
  });

  group('minRemainingRelayBlocks', () {
    UtxoInfo utxo({required int? confirmations, bool isCoinbase = true}) {
      return UtxoInfo(
        txid:
            '85e9064be6d7623853fe60fc75dbefdfe4478ce35683549e59e8ad6cda25cd40',
        vout: 1,
        valueSat: 1000,
        confirmations: confirmations,
        isCoinbase: isCoinbase,
      );
    }

    test('primo sblocco = minimo fra i bloccati', () {
      expect(
        minRemainingRelayBlocks(
          [utxo(confirmations: 600), utxo(confirmations: 1000)],
          maturityBlocks: 6480,
        ),
        5480,
      );
    });

    test('salta le conferme ignote (stima, mai una data inventata)', () {
      expect(
        minRemainingRelayBlocks(
          [utxo(confirmations: null), utxo(confirmations: 1000)],
          maturityBlocks: 6480,
        ),
        5480,
      );
    });

    test('nessun bloccato (o lista vuota) → null', () {
      expect(minRemainingRelayBlocks(const []), isNull);
      expect(
        minRemainingRelayBlocks(
          [utxo(confirmations: 6480)],
          maturityBlocks: 6480,
        ),
        isNull,
      );
    });
  });

  group('splitRelayableUtxos', () {
    UtxoInfo utxo({
      required int valueSat,
      required bool isCoinbase,
      required int? confirmations,
    }) {
      return UtxoInfo(
        txid:
            '85e9064be6d7623853fe60fc75dbefdfe4478ce35683549e59e8ad6cda25cd40',
        vout: 1,
        valueSat: valueSat,
        confirmations: confirmations,
        isCoinbase: isCoinbase,
      );
    }

    test('separa spendibili e bloccati preservando l ordine', () {
      final normal = utxo(
        valueSat: 1000,
        isCoinbase: false,
        confirmations: 1,
      );
      final immature = utxo(
        valueSat: 2000,
        isCoinbase: true,
        confirmations: 10,
      );
      final mature = utxo(valueSat: 3000, isCoinbase: true, confirmations: 6480);

      final split = splitRelayableUtxos(
        [normal, immature, mature],
        maturityBlocks: 6480,
      );

      expect(split.spendable, [normal, mature]);
      expect(split.blocked, [immature]);
      expect(sumUtxoSats(split.spendable), 4000);
      expect(sumUtxoSats(split.blocked), 2000);
    });

    test('lista vuota → entrambe vuote', () {
      final split = splitRelayableUtxos(const []);
      expect(split.spendable, isEmpty);
      expect(split.blocked, isEmpty);
      expect(sumUtxoSats(split.blocked), 0);
    });
  });
}
