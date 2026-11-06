import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:btc_blake2b_wallet/core/config/feature_flags.dart';
import 'package:btc_blake2b_wallet/core/models/wallet_record.dart';
import 'package:btc_blake2b_wallet/core/services/receive_address_presenter.dart';
import 'package:btc_blake2b_wallet/core/services/receive_address_service.dart';
import 'package:btc_blake2b_wallet/core/services/wallet_repository.dart';

class MockWalletRepository extends Mock implements WalletRepository {}

void main() {
  group('ReceiveAddressService (ADR 31/10-23)', () {
    late MockWalletRepository repository;

    WalletRecord wallet({IndicesState state = IndicesState.valid}) {
      return WalletRecord(
        walletId: 'w1',
        encryptedSeed: 'enc',
        publicAddress: 'bc1qlegacy',
        deviceId: 'dev',
        createdAt: DateTime.utc(2026, 11, 1),
        indicesState: state,
      );
    }

    setUp(() {
      repository = MockWalletRepository();
      registerFallbackValue(
        WalletRecord(
          walletId: 'fallback',
          encryptedSeed: '',
          publicAddress: '',
          deviceId: '',
          createdAt: DateTime(2024),
        ),
      );
    });

    test('nuovo indirizzo: vista fresh con indirizzo e path', () async {
      when(
        () => repository.nextReceiveAddress(
          any(),
          rotationEnabled: any(named: 'rotationEnabled'),
          adoptLegacy: any(named: 'adoptLegacy'),
          mnemonic: any(named: 'mnemonic'),
        ),
      ).thenAnswer(
        (_) async => ReceiveAddressResult(
          address: 'bc1qnew',
          index: 7,
          record: wallet(),
          persisted: true,
          isFresh: true,
        ),
      );

      final service = ReceiveAddressService(
        repository: repository,
        flags: const FeatureFlags(walletIndexRotation: true),
      );
      final sut = await service.next(wallet());

      expect(sut.view, ReceiveAddressView.fresh);
      expect(sut.address, 'bc1qnew');
      expect(sut.index, 7);
      expect(sut.derivationPath, contains('/0/7'));
      expect(sut.hasAddress, isTrue);
    });

    test('doppio tap: vista alreadyAssigned, non fresh', () async {
      when(
        () => repository.nextReceiveAddress(
          any(),
          rotationEnabled: any(named: 'rotationEnabled'),
          adoptLegacy: any(named: 'adoptLegacy'),
          mnemonic: any(named: 'mnemonic'),
        ),
      ).thenAnswer(
        (_) async => ReceiveAddressResult(
          address: 'bc1qassigned',
          index: 3,
          record: wallet(),
          persisted: false,
          isFresh: false,
        ),
      );

      final service = ReceiveAddressService(
        repository: repository,
        flags: const FeatureFlags(walletIndexRotation: true),
      );
      final sut = await service.next(wallet());

      expect(sut.view, ReceiveAddressView.alreadyAssigned);
      expect(sut.address, 'bc1qassigned');
    });

    test('adozione richiesta: nessun indirizzo mostrato', () async {
      when(
        () => repository.nextReceiveAddress(
          any(),
          rotationEnabled: any(named: 'rotationEnabled'),
          adoptLegacy: any(named: 'adoptLegacy'),
          mnemonic: any(named: 'mnemonic'),
        ),
      ).thenThrow(const WalletIndicesAdoptionRequiredException('w1'));

      final service = ReceiveAddressService(
        repository: repository,
        flags: const FeatureFlags(walletIndexRotation: true),
      );
      final sut = await service.next(
        wallet(state: IndicesState.legacyUninitialized),
      );

      expect(sut.view, ReceiveAddressView.adoptionRequired);
      expect(sut.hasAddress, isFalse);
    });

    test('corrotto/anomalo: fail-closed anche con flag spento', () async {
      final service = ReceiveAddressService(
        repository: repository,
        flags: const FeatureFlags(walletIndexRotation: false),
      );

      final corrupt = await service.next(wallet(state: IndicesState.corrupt));
      final anomalous = await service.next(
        wallet(state: IndicesState.anomalous),
      );

      expect(corrupt.view, ReceiveAddressView.corruptBlocked);
      expect(anomalous.view, ReceiveAddressView.anomalousBlocked);
      expect(corrupt.hasAddress, isFalse);
      expect(anomalous.hasAddress, isFalse);
      // Nessuna chiamata al repository: la decisione è già presa sul record.
      verifyNever(
        () => repository.nextReceiveAddress(
          any(),
          rotationEnabled: any(named: 'rotationEnabled'),
          adoptLegacy: any(named: 'adoptLegacy'),
          mnemonic: any(named: 'mnemonic'),
        ),
      );
    });

    test('seed mancante: vista seedRequired, non uno StateError', () async {
      // PERCHÉ (ADR 02/11-28 §1): un wallet creato prima del 26/10 non ha
      // `accountXpub`. Prima il caso esplodeva come StateError («Errore
      // imprevisto»); ora è una vista con l'azione giusta.
      when(
        () => repository.nextReceiveAddress(
          any(),
          rotationEnabled: any(named: 'rotationEnabled'),
          adoptLegacy: any(named: 'adoptLegacy'),
          mnemonic: any(named: 'mnemonic'),
        ),
      ).thenThrow(const SeedUnavailableException('w1'));

      final service = ReceiveAddressService(
        repository: repository,
        flags: const FeatureFlags(walletIndexRotation: true),
      );
      final sut = await service.next(wallet());

      expect(sut.view, ReceiveAddressView.seedRequired);
      expect(sut.hasAddress, isFalse);
      expect(
        ReceiveAddressPresenter.canReceive(sut.view),
        isFalse,
        reason: 'senza seed non si può derivare: la ricezione è bloccata',
      );
    });

    test('seed sbagliata: vista seedMismatch, non seedRequired', () async {
      // PERCHÉ (ADR 02/11-33 §1): «sblocca» sarebbe una promessa falsa — la
      // seed è presente e non corrisponde al wallet. La vista deve essere
      // distinta, con uscite diverse (backup/supporto).
      when(
        () => repository.nextReceiveAddress(
          any(),
          rotationEnabled: any(named: 'rotationEnabled'),
          adoptLegacy: any(named: 'adoptLegacy'),
          mnemonic: any(named: 'mnemonic'),
        ),
      ).thenThrow(
        const SeedWalletMismatchException(
          walletId: 'w1',
          recordAddress: 'bc1qrecord',
          derivedAddress: 'bc1qderived',
        ),
      );

      final service = ReceiveAddressService(
        repository: repository,
        flags: const FeatureFlags(walletIndexRotation: true),
      );
      final sut = await service.next(wallet());

      expect(sut.view, ReceiveAddressView.seedMismatch);
      expect(sut.hasAddress, isFalse);
      expect(
        ReceiveAddressPresenter.blocksSpending(sut.view),
        isTrue,
        reason: 'con seed sbagliata nessun PSBT è affidabile',
      );
    });

    test('eccezioni dal repository tradotte in viste', () async {
      // Stato in memoria «valid» (quindi si passa dal repository), ma il record
      // su disco è corrotto: la vista deve diventare blocked, non un crash.
      when(
        () => repository.nextReceiveAddress(
          any(),
          rotationEnabled: any(named: 'rotationEnabled'),
          adoptLegacy: any(named: 'adoptLegacy'),
          mnemonic: any(named: 'mnemonic'),
        ),
      ).thenThrow(const CorruptWalletIndicesException('w1'));

      final service = ReceiveAddressService(
        repository: repository,
        flags: const FeatureFlags(walletIndexRotation: true),
      );
      final sut = await service.next(wallet());

      expect(sut.view, ReceiveAddressView.corruptBlocked);
      expect(sut.hasAddress, isFalse);
    });
  });
}
