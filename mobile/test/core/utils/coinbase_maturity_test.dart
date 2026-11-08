import 'package:btc_blake2b_wallet/core/config/bitcoin_network_config.dart';
import 'package:btc_blake2b_wallet/core/config/coinbase_maturity_rules.dart';
import 'package:btc_blake2b_wallet/core/models/utxo_info.dart';
import 'package:btc_blake2b_wallet/core/utils/coinbase_maturity.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regole verificate (fonte primaria: Knots `v29.4.3`,
/// `src/consensus/tx_verify.cpp` + `src/consensus/params.h`): la maturity
/// dipende dall'ALTEZZA DELLA COINBASE, quindi ogni payout ha il proprio
/// conto alla rovescia — 100 blocchi prima di 973.440, 6.480 nell'epoca
/// 973.440-979.918, 25.920 da 979.919. Confermato l'08/11/2026 con
/// `testmempoolaccept` sul nodo reale (`bad-txns-premature-spend-of-coinbase`).
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

    test('coinbase dell epoca 973.440-979.918: 6.480 dal PROPRIO blocco', () {
      // Verificato sul nodo reale: h=973.440 sblocca a 979.920 (h + 6.480).
      expect(
        isUtxoRelayable(
          utxo(isCoinbase: true, confirmations: 6480, blockHeight: 973440),
        ),
        isTrue,
      );
      expect(
        isUtxoRelayable(
          utxo(isCoinbase: true, confirmations: 6479, blockHeight: 973440),
        ),
        isFalse,
      );
      // Minata a fine finestra: NON si sblocca a 979.919, ma a h + 6.480.
      expect(
        isUtxoRelayable(
          utxo(isCoinbase: true, confirmations: 100, blockHeight: 979818),
        ),
        isFalse,
      );
      expect(
        isUtxoRelayable(
          utxo(isCoinbase: true, confirmations: 6480, blockHeight: 979818),
        ),
        isTrue,
      );
    });

    test('caso reale 08/11/2026: h=979877 con 1.270 conferme → rifiutata', () {
      // `testmempoolaccept` sul nodo: bad-txns-premature-spend-of-coinbase,
      // "tried to spend coinbase at depth 1270".
      expect(
        isUtxoRelayable(
          utxo(isCoinbase: true, confirmations: 1270, blockHeight: 979877),
        ),
        isFalse,
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

    test('epoca → 6.480 blocchi per OGNI coinbase, non uno sblocco comune', () {
      // `CoinbaseMaturityBeforeRolling() = release − start` = 979.920 − 973.440.
      expect(rules.requiredDepth(973440), 6480);
      expect(rules.unlockHeight(973440), 979920);
      expect(rules.requiredDepth(975000), 6480);
      expect(rules.unlockHeight(975000), 981480);
      // Ultima coinbase dell'epoca: sblocca a 986.398, ~14 mesi dopo il 979.919
      // sepolto. È il numero che le release note citano come 986.399.
      expect(rules.requiredDepth(979918), 6480);
      expect(rules.unlockHeight(979918), 986398);
    });

    test('dal 979.919 → 25.920 blocchi (~180 giorni)', () {
      expect(rules.requiredDepth(979919), 25920);
      expect(rules.unlockHeight(979919), 1005839);
      expect(rules.requiredDepth(1200000), 25920);
    });

    test('dati reali del nodo (tip 981.146, 08/11/2026)', () {
      const tip = 981146;
      // La più vecchia coinbase ancora immatura: 6.406 conferme, 74 al giro.
      expect(rules.requiredDepth(974741), 6480);
      expect(rules.unlockHeight(974741), 981221);
      expect(rules.requiredDepth(974741) - (tip - 974741 + 1), 74);
      // La più recente dell'epoca ancora immatura.
      expect(rules.requiredDepth(979877), 6480);
      expect(rules.unlockHeight(979877), 986357);
    });

    test('rete senza epoche (testnet) → profondità fissa', () {
      const flat = CoinbaseMaturityRules(
        defaultMaturityBlocks: 6705,
        epochs: [],
      );
      expect(flat.requiredDepth(1), 6705);
      expect(flat.requiredDepth(500000), 6705);
      expect(flat.unlockHeight(1), 6706);
      expect(flat.strictestMaturityBlocks, 6705);
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
      // Fine epoca (979.818): 6.480 − 100 = 6.380 (sblocco a 986.298).
      expect(remainingRelayBlocks(coinbaseAt(979818, 100)), 6380);
      // Pre-epoca (regola ordinaria): 100 − 40 = 60.
      expect(remainingRelayBlocks(coinbaseAt(900000, 40)), 60);
      // Caso reale: h=974.741 con 6.406 conferme → 74 blocchi.
      expect(remainingRelayBlocks(coinbaseAt(974741, 6406)), 74);
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
