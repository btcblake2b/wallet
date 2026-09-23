import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/core/models/wallet_address.dart';

/// Test del modello [WalletAddress]: la regola di stato è DERIVATA da
/// `txCount` + `balanceSats` — il caso critico è "usato e poi speso", che senza
/// il conteggio transazioni verrebbe mostrato come "mai usato" (dato falso).
void main() {
  WalletAddress address({int balance = 0, int txCount = 0}) => WalletAddress(
        address: 'bc1qexampleaddress0000000000000000000000',
        branch: WalletAddressBranch.external,
        index: 3,
        derivationPath: "m/84'/0'/0'/0/3",
        balanceSats: balance,
        txCount: txCount,
      );

  group('WalletAddress.status', () {
    test('txCount 0 → mai usato', () {
      expect(address().status, WalletAddressStatus.unused);
      expect(address().hasActivity, isFalse);
    });

    test('txCount > 0 e saldo 0 → usato e speso (NON mai usato)', () {
      final a = address(balance: 0, txCount: 4);
      expect(a.status, WalletAddressStatus.usedEmpty);
      expect(a.hasActivity, isTrue);
    });

    test('saldo > 0 → con saldo', () {
      expect(
        address(balance: 2121, txCount: 1).status,
        WalletAddressStatus.hasFunds,
      );
    });
  });

  group('WalletAddress.copyWith', () {
    test('aggiorna solo i campi passati e conserva identità/derivazione', () {
      final original = address(balance: 1000, txCount: 1);
      final updated = original.copyWith(balanceSats: 0, txCount: 2);

      expect(updated.balanceSats, 0);
      expect(updated.txCount, 2);
      expect(updated.address, original.address);
      expect(updated.branch, original.branch);
      expect(updated.index, original.index);
      expect(updated.derivationPath, original.derivationPath);
      // Il cambio di saldo può cambiare lo stato: ora è "usato e speso".
      expect(updated.status, WalletAddressStatus.usedEmpty);
    });
  });
}
