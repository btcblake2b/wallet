import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/core/config/bitcoin_network_config.dart';

void main() {
  group('WalletScriptType', () {
    test('fromDerivationPath mappa i purpose corretti', () {
      expect(
        WalletScriptType.fromDerivationPath("m/84'/0'/0'"),
        WalletScriptType.p2wpkh,
      );
      expect(
        WalletScriptType.fromDerivationPath("m/49'/0'/0'"),
        WalletScriptType.p2shP2wpkh,
      );
      expect(
        WalletScriptType.fromDerivationPath("m/44'/0'/0'"),
        WalletScriptType.p2pkh,
      );
      // Fallback: null e path non standard → native (comportamento storico).
      expect(
        WalletScriptType.fromDerivationPath(null),
        WalletScriptType.p2wpkh,
      );
      expect(
        WalletScriptType.fromDerivationPath("m/0'/0'"),
        WalletScriptType.p2wpkh,
      );
    });

    test('accountPath usa il coinType della rete corrente (mainnet 0)', () {
      // PERCHÉ: la rete corrente è mainnet → coin_type 0'.
      expect(WalletScriptType.p2wpkh.accountPath(), "m/84'/0'/0'");
      expect(WalletScriptType.p2shP2wpkh.accountPath(), "m/49'/0'/0'");
      expect(WalletScriptType.p2pkh.accountPath(), "m/44'/0'/0'");
      expect(
        WalletScriptType.p2pkh.accountPath(coinType: 1),
        "m/44'/1'/0'",
      );
      expect(
        WalletScriptType.p2shP2wpkh.accountPath(coinType: 1),
        "m/49'/1'/0'",
      );
    });

    test('isNested/isLegacy corretti', () {
      expect(WalletScriptType.p2shP2wpkh.isNested, isTrue);
      expect(WalletScriptType.p2wpkh.isNested, isFalse);
      expect(WalletScriptType.p2pkh.isLegacy, isTrue);
      expect(WalletScriptType.p2shP2wpkh.isLegacy, isFalse);
    });
  });
}
