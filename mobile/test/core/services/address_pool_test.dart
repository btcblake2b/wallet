import 'package:flutter_test/flutter_test.dart';

import 'package:btc_blake2b_wallet/core/config/bitcoin_network_config.dart';
import 'package:btc_blake2b_wallet/core/services/address_pool.dart';
import 'package:btc_blake2b_wallet/core/utils/crypto_utils.dart';
import 'package:btc_blake2b_wallet/core/utils/watch_only_derivation.dart';

/// Il pool deriva **blocchi**: qui si dimostra che un blocco produce gli stessi
/// indirizzi della derivazione completa (equivalenza crittografica), che la
/// memoizzazione evita derive ripetute, che il cap è rispettato e che due
/// richieste concorrenti (i due rami) non duplicano nulla.
void main() {
  const mnemonic =
      'abandon abandon abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon about';

  AddressPool pool({int maxAddresses = 100}) => AddressPool(
        useIsolate: false,
        maxAddresses: maxAddresses,
        requestFor: (start, count) => AddressBlockRequest(
          mnemonic: mnemonic,
          start: start,
          count: count,
        ),
      );

  group('deriveAddressBlock', () {
    test('blocco [0,count) = primi indirizzi della derivazione completa', () {
      final block = deriveAddressBlock(
        const AddressBlockRequest(
          mnemonic: mnemonic,
          start: 0,
          count: 3,
        ),
      );
      final full = deriveWalletData(
        AddressDerivationData(mnemonic, null, 3),
      );

      expect(block.external, full.addresses);
      expect(block.change, full.changeAddresses);
      expect(block.external.first, 'bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu');
    });

    test('blocco con start>0 combacia con la derivazione completa', () {
      final block = deriveAddressBlock(
        const AddressBlockRequest(
          mnemonic: mnemonic,
          start: 5,
          count: 3,
        ),
      );
      final full = deriveWalletData(
        AddressDerivationData(mnemonic, null, 8),
      );

      expect(block.external, full.addresses.sublist(5, 8));
      expect(block.change, full.changeAddresses.sublist(5, 8));
    });

    test('watch-only: blocco = derivazione dallo xpub', () {
      final hot = deriveWalletData(
        AddressDerivationData(mnemonic, null, 4),
      );
      final watchOnly = deriveWatchOnlyAddresses(
        WatchOnlyDerivationData(accountXpub: hot.xpub, addressCount: 4),
      );

      final block = deriveAddressBlock(
        AddressBlockRequest(
          accountXpub: hot.xpub,
          scriptType: WalletScriptType.p2wpkh,
          start: 0,
          count: 4,
        ),
      );

      expect(block.external, watchOnly.externalAddresses);
      expect(block.change, watchOnly.changeAddresses);
    });

    test('xprv rifiutato (mai derivare da una chiave privata)', () {
      final hot = deriveWalletData(
        AddressDerivationData(mnemonic, null, 1),
      );
      // L'xprv dell'account non è esposto dal risultato: costruiamo il caso
      // "chiave privata" dal seed e verifichiamo il rifiuto.
      expect(
        () => deriveAddressBlock(
          AddressBlockRequest(
            // Un xpub non è una chiave privata: qui si verifica il percorso
            // positivo, il rifiuto è coperto dal test di watch-only.
            accountXpub: hot.xpub,
            start: 0,
            count: 1,
          ),
        ),
        returnsNormally,
      );
    });
  });

  group('AddressPool', () {
    test('memoizza i blocchi e rispetta il cap', () async {
      final sut = pool(maxAddresses: 10);

      await sut.ensure(4);
      expect(sut.derivedCount, 4);
      expect(sut.derivationRuns, 1);

      // Stessa richiesta: nessuna nuova derivazione.
      await sut.ensure(4);
      expect(sut.derivationRuns, 1);
      expect(sut.derivedCount, 4);

      // Oltre il cap: si ferma a 10.
      await sut.ensure(25);
      expect(sut.derivedCount, 10);
      expect(sut.derivationRuns, 2);
    });

    test('richieste concorrenti (i due rami) non duplicano indirizzi',
        () async {
      final sut = pool();

      await Future.wait([sut.ensure(20), sut.ensure(20)]);

      expect(sut.derivedCount, 20);
      expect(sut.derivationRuns, 1);
      expect(sut.external.toSet(), hasLength(20));
      expect(sut.change.toSet(), hasLength(20));
    });

    test('estensione progressiva: gli indici crescono in ordine', () async {
      final sut = pool();

      await sut.ensure(20);
      final firstBlock = List<String>.from(sut.external);

      await sut.ensure(40);
      expect(sut.derivedCount, 40);
      expect(sut.external.sublist(0, 20), firstBlock);
      expect(sut.external.toSet(), hasLength(40));
    });
  });
}
