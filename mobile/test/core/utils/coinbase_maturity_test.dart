import 'package:btc_blake2b_wallet/core/config/bitcoin_network_config.dart';
import 'package:btc_blake2b_wallet/core/config/coinbase_maturity_rules.dart';
import 'package:btc_blake2b_wallet/core/models/utxo_info.dart';
import 'package:btc_blake2b_wallet/core/utils/coinbase_maturity.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regole verificate (fonte: Knots `v29.4.3` release notes + PR
/// `bitcoinknots/bitcoin#419`, consenso `knots#468`): dal blocco 979.919 la
/// mainnet blake2b applica DUE regole — sblocco comune a 979.919 per le
/// coinbase dell'epoca 973.440-979.918, 25.920 blocchi (~180 giorni) per
/// quelle minate da 979.919 in poi.
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
    UtxoInfo utxo({
      required bool isCoinbase,
      required int? confirmations,
      int? blockHeight,
    }) {
      return UtxoInfo(
        txid:
            '85e9064be6d7623853fe60fc75dbefdfe4478ce35683549e59e8ad6cda25cd40',
        vout: 1,
        valueSat: 13973,
        confirmations: confirmations,
        blockHeight: blockHeight,
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

    test('default = regola della rete corrente (mainnet 25.920)', () {
      expect(BitcoinNetworkConfig.coinbaseRelayMaturityBlocks, 25920);
      expect(
        isUtxoRelayable(utxo(isCoinbase: true, confirmations: 25919)),
        isFalse,
      );
      expect(
        isUtxoRelayable(utxo(isCoinbase: true, confirmations: 25920)),
        isTrue,
      );
    });

    test('altezza ignota → regola più restrittiva (mai più permissiva)', () {
      // Con la sola regola dei 6.480 blocchi queste conferme bastavano: oggi
      // senza altezza non possiamo dimostrare l'epoca, quindi non si sblocca.
      expect(
        isUtxoRelayable(utxo(isCoinbase: true, confirmations: 6480)),
        isFalse,
      );
    });

    test('coinbase dell epoca 973.440-979.918: sblocco comune a 979.919', () {
      expect(
        isUtxoRelayable(
          utxo(isCoinbase: true, confirmations: 6480, blockHeight: 973440),
        ),
        isTrue,
      );
      // 979.919 − 979.818 + 1 = 102 conferme: con 100 non è ancora matura.
      expect(
        isUtxoRelayable(
          utxo(isCoinbase: true, confirmations: 100, blockHeight: 979818),
        ),
        isFalse,
      );
      expect(
        isUtxoRelayable(
          utxo(isCoinbase: true, confirmations: 102, blockHeight: 979818),
        ),
        isTrue,
      );
    });

    test('coinbase dal 979.919: 25.920 blocchi, non 6.480', () {
      expect(
        isUtxoRelayable(
          utxo(isCoinbase: true, confirmations: 6480, blockHeight: 979919),
        ),
        isFalse,
      );
      expect(
        isUtxoRelayable(
          utxo(isCoinbase: true, confirmations: 25920, blockHeight: 979919),
        ),
        isTrue,
      );
    });
  });

  group('CoinbaseMaturityRules', () {
    final rules = BitcoinNetworkConfig.coinbaseMaturityRules;

    test('pre-epoca → maturity ordinaria di consenso (100)', () {
      expect(rules.requiredDepth(973439), 100);
      expect(rules.unlockHeight(973439), 973539);
    });

    test('epoca → sblocco comune a 979.919 (+1 conferma del blocco)', () {
      // 6.480 = profondità dichiarata da Knots per l epoca 973.440-979.918.
      expect(rules.requiredDepth(973440), 6480);
      expect(rules.unlockHeight(973440), 979920);
      // Minata a fine finestra: restano dovute le 100 conferme ordinarie.
      expect(rules.requiredDepth(979918), 100);
      expect(rules.unlockHeight(979918), 980018);
    });

    test('dal 979.919 → 25.920 blocchi (~180 giorni)', () {
      expect(rules.requiredDepth(979919), 25920);
      expect(rules.unlockHeight(979919), 1005839);
      expect(rules.requiredDepth(1200000), 25920);
    });

    test('rete senza epoche (testnet) → profondità fissa', () {
      const flat = CoinbaseMaturityRules(longMaturityBlocks: 6705);
      expect(flat.requiredDepth(1), 6705);
      expect(flat.requiredDepth(500000), 6705);
      expect(flat.unlockHeight(1), 6706);
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

    test('con altezza nota: countdown dalla regola dell epoca', () {
      UtxoInfo coinbaseAt(int blockHeight, int confirmations) => UtxoInfo(
            txid:
                '85e9064be6d7623853fe60fc75dbefdfe4478ce35683549e59e8ad6cda25cd40',
            vout: 1,
            valueSat: 13973,
            confirmations: confirmations,
            blockHeight: blockHeight,
            isCoinbase: true,
          );

      // Dal 979.919 la regola lunga: 25.920 − 600 = 25.320.
      expect(remainingRelayBlocks(coinbaseAt(979919, 600)), 25320);
      // Fine epoca (979.818): 102 conferme dovute − 100 = 2 blocchi.
      expect(remainingRelayBlocks(coinbaseAt(979818, 100)), 2);
      // Pre-epoca (regola ordinaria): 100 − 40 = 60.
      expect(remainingRelayBlocks(coinbaseAt(900000, 40)), 60);
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
      final mature =
          utxo(valueSat: 3000, isCoinbase: true, confirmations: 6480);

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
