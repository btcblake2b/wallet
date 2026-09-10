import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:btc_blake2b_wallet/core/config/bitcoin_network_config.dart';
import 'package:btc_blake2b_wallet/core/models/wallet_record.dart';
import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';
import 'package:btc_blake2b_wallet/core/services/crypto_service.dart';
import 'package:btc_blake2b_wallet/core/services/device_service.dart';
import 'package:btc_blake2b_wallet/core/services/secure_seed_storage.dart';
import 'package:btc_blake2b_wallet/core/services/wallet_repository.dart';
import 'package:btc_blake2b_wallet/core/utils/crypto_utils.dart';
import 'package:btc_blake2b_wallet/core/utils/watch_only_derivation.dart';
import 'package:uuid/uuid.dart';

class MockSecureSeedStorage extends Mock implements SecureSeedStorage {}

class MockDeviceService extends Mock implements DeviceService {}

class MockCryptoService extends Mock implements CryptoService {}

class MockBitcoinService extends Mock implements BitcoinService {}

class MockUuid extends Mock implements Uuid {}

void main() {
  group('WalletRepository', () {
    late MockSecureSeedStorage mockSecureSeedStorage;
    late MockDeviceService mockDeviceService;
    late MockCryptoService mockCryptoService;
    late MockBitcoinService mockBitcoinService;
    late MockUuid mockUuid;
    late WalletRepository sut;

    setUpAll(() {
      // PERCHÉ: mocktail richiede un fallback per gli argomenti di tipo
      // WalletRecord usati con any()/captureAny() nei verify/when.
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

    setUp(() {
      mockSecureSeedStorage = MockSecureSeedStorage();
      mockDeviceService = MockDeviceService();
      mockCryptoService = MockCryptoService();
      mockBitcoinService = MockBitcoinService();
      mockUuid = MockUuid();
      sut = WalletRepository(
        secureSeedStorage: mockSecureSeedStorage,
        deviceService: mockDeviceService,
        cryptoService: mockCryptoService,
        bitcoinService: mockBitcoinService,
        uuid: mockUuid,
      );
    });

    test('should instantiate', () {
      expect(sut, isNotNull);
    });

    WalletRecord makeWallet(String id) => WalletRecord(
          walletId: id,
          encryptedSeed: 'enc-seed-$id',
          publicAddress: 'tb1qxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
          deviceId: 'dev-$id',
          createdAt: DateTime.utc(2026, 8, 7),
        );

    group('createWallet', () {
      test('creates and persists a wallet locally without backend', () async {
        when(() => mockDeviceService.getOrCreateDeviceId())
            .thenAnswer((_) async => 'device-1');
        when(() => mockUuid.v4()).thenReturn('wallet-1');
        when(() => mockBitcoinService.generateMnemonic())
            .thenReturn('abandon abandon abandon abandon abandon abandon '
                'abandon abandon abandon abandon abandon about');
        when(
          () => mockCryptoService.encryptSeed(
            seedPhrase: any(named: 'seedPhrase'),
            deviceId: any(named: 'deviceId'),
          ),
        ).thenAnswer((_) async => 'encrypted-seed');
        when(
          () => mockBitcoinService.deriveWalletDataFromMnemonic(
            any(),
            addressCount: any(named: 'addressCount'),
          ),
        ).thenAnswer(
          (_) async => WalletDerivationResult(
            publicAddress: 'tb1qtest',
            masterFingerprint: 'fp',
            derivationPath: "m/84'/1'/0'",
            xpub: 'tpub_test',
            addresses: const ['tb1qtest'],
            changeAddresses: const [],
          ),
        );
        when(() => mockSecureSeedStorage.upsertWallet(any()))
            .thenAnswer((_) async {});

        final wallet = await sut.createWallet();

        expect(wallet.walletId, 'wallet-1');
        expect(wallet.publicAddress, 'tb1qtest');
        // PERCHÉ: nessuna registrazione cloud — solo persistenza locale.
        // captureAny: il WalletRecord è creato DENTRO createWallet, quindi
        // non è la stessa istanza del test → verifichiamo l'avvenuta chiamata.
        final captured = verify(
          () => mockSecureSeedStorage.upsertWallet(captureAny()),
        ).captured;
        expect(captured, hasLength(1));
        verifyNever(() => mockSecureSeedStorage.deleteWallet(any()));
      });

      test('createWallet con derivationPath deriva sul path del tipo scelto',
          () async {
        when(() => mockDeviceService.getOrCreateDeviceId())
            .thenAnswer((_) async => 'device-1');
        when(() => mockUuid.v4()).thenReturn('wallet-49b');
        when(() => mockBitcoinService.generateMnemonic())
            .thenReturn('abandon abandon abandon abandon abandon abandon '
                'abandon abandon abandon abandon abandon about');
        when(
          () => mockCryptoService.encryptSeed(
            seedPhrase: any(named: 'seedPhrase'),
            deviceId: any(named: 'deviceId'),
          ),
        ).thenAnswer((_) async => 'encrypted-seed');
        when(
          () => mockBitcoinService.deriveWalletDataFromMnemonic(
            any(),
            derivationPath: any(named: 'derivationPath'),
            addressCount: any(named: 'addressCount'),
          ),
        ).thenAnswer(
          (_) async => WalletDerivationResult(
            publicAddress: '3test',
            masterFingerprint: 'fp',
            derivationPath: "m/49'/0'/0'",
            xpub: 'xpub_test',
            addresses: const ['3test'],
            changeAddresses: const [],
          ),
        );
        when(() => mockSecureSeedStorage.upsertWallet(any()))
            .thenAnswer((_) async {});

        final wallet = await sut.createWallet(derivationPath: "m/49'/0'/0'");

        verify(
          () => mockBitcoinService.deriveWalletDataFromMnemonic(
            any(),
            derivationPath: "m/49'/0'/0'",
            addressCount: any(named: 'addressCount'),
          ),
        ).called(1);
        expect(wallet.derivationPath, "m/49'/0'/0'");
        expect(wallet.publicAddress, '3test');
      });
    });

    group('importWallet', () {
      test('propaga il derivationPath BIP49 fino a derivazione e persistenza',
          () async {
        when(() => mockDeviceService.getOrCreateDeviceId())
            .thenAnswer((_) async => 'device-1');
        when(() => mockUuid.v4()).thenReturn('wallet-49');
        when(
          () => mockCryptoService.encryptSeed(
            seedPhrase: any(named: 'seedPhrase'),
            deviceId: any(named: 'deviceId'),
          ),
        ).thenAnswer((_) async => 'encrypted-seed');
        when(
          () => mockBitcoinService.deriveWalletDataFromMnemonic(
            any(),
            derivationPath: any(named: 'derivationPath'),
          ),
        ).thenAnswer(
          (_) async => WalletDerivationResult(
            publicAddress: '3test',
            masterFingerprint: 'fp',
            derivationPath: "m/49'/0'/0'",
            xpub: 'xpub_test',
            addresses: const ['3test'],
            changeAddresses: const [],
          ),
        );
        when(() => mockSecureSeedStorage.upsertWallet(any()))
            .thenAnswer((_) async {});

        const mnemonic = 'abandon abandon abandon abandon abandon abandon '
            'abandon abandon abandon abandon abandon about';
        final wallet = await sut.importWallet(
          mnemonic: mnemonic,
          derivationPath: "m/49'/0'/0'",
        );

        // Il tipo scelto nell'import deve arrivare alla derivazione.
        verify(
          () => mockBitcoinService.deriveWalletDataFromMnemonic(
            any(),
            derivationPath: "m/49'/0'/0'",
          ),
        ).called(1);
        expect(wallet.derivationPath, "m/49'/0'/0'");
        final captured = verify(
          () => mockSecureSeedStorage.upsertWallet(captureAny()),
        ).captured;
        expect(
          (captured.single as WalletRecord).derivationPath,
          "m/49'/0'/0'",
        );
      });
    });

    group('loadWallets', () {
      test('delegates to secure storage', () async {
        final wallets = [makeWallet('w1')];
        when(() => mockSecureSeedStorage.loadWallets())
            .thenAnswer((_) async => wallets);

        final result = await sut.loadWallets();

        expect(result, wallets);
      });
    });

    group('deleteWallet', () {
      test('deletes from secure storage', () async {
        when(() => mockSecureSeedStorage.deleteWallet('w1'))
            .thenAnswer((_) async {});

        await sut.deleteWallet('w1');

        verify(() => mockSecureSeedStorage.deleteWallet('w1')).called(1);
      });
    });

    group('confirmSeedBackup', () {
      test('marks seedBackupConfirmed and persists', () async {
        final wallet = makeWallet('w1');
        when(() => mockSecureSeedStorage.upsertWallet(any()))
            .thenAnswer((_) async {});

        final updated = await sut.confirmSeedBackup(wallet);

        expect(updated.seedBackupConfirmed, isTrue);
        final captured = verify(
          () => mockSecureSeedStorage.upsertWallet(captureAny()),
        ).captured;
        expect(captured.single, isA<WalletRecord>());
        expect(
          (captured.single as WalletRecord).seedBackupConfirmed,
          isTrue,
        );
      });
    });

    group('decryptSeed', () {
      test('delegates to crypto service with device id', () async {
        final wallet = makeWallet('w1');
        when(
          () => mockCryptoService.decryptSeed(
            encryptedSeed: wallet.encryptedSeed,
            deviceId: wallet.deviceId,
          ),
        ).thenAnswer((_) async => 'seed phrase');

        final seed = await sut.decryptSeed(wallet);

        expect(seed, 'seed phrase');
      });

      test('throws per un wallet watch-only (nessun seed)', () async {
        final wallet = makeWallet('w1').copyWith(
          kind: WalletKind.watchOnly,
          accountXpub: 'xpub_test',
        );

        await expectLater(
          sut.decryptSeed(wallet),
          throwsStateError,
        );
      });
    });

    group('importWatchOnly', () {
      const accountXpub =
          'xpub6CUGRUonZSQ4TWtTMmzXdrXDtypWKiKrhko4egpiMZbpiaQL2jkwSB1icqYh2cfDfVxdx4df189oLKnC5fSwqPfgyP3hooxujYzAu3fDVmz';

      test('crea un wallet watchOnly senza cifrare alcun seed', () async {
        when(() => mockDeviceService.getOrCreateDeviceId())
            .thenAnswer((_) async => 'device-1');
        when(() => mockUuid.v4()).thenReturn('wallet-wo');
        when(
          () => mockBitcoinService.deriveWatchOnlyData(
            accountXpub: accountXpub,
            scriptType: WalletScriptType.p2wpkh,
            addressCount: 1,
          ),
        ).thenAnswer(
          (_) async => const WatchOnlyDerivationResult(
            publicAddress: 'bc1qwatchfirst',
            fingerprint: 'ABCDEF12',
            accountXpub: accountXpub,
            externalAddresses: ['bc1qwatchfirst'],
            changeAddresses: [],
          ),
        );
        when(() => mockSecureSeedStorage.upsertWallet(any()))
            .thenAnswer((_) async {});

        final wallet = await sut.importWatchOnly(
          accountXpub: accountXpub,
          scriptType: WalletScriptType.p2wpkh,
        );

        expect(wallet.kind, WalletKind.watchOnly);
        expect(wallet.accountXpub, accountXpub);
        // PERCHÉ: nessuna chiave privata da proteggere → encryptedSeed vuoto.
        expect(wallet.encryptedSeed, '');
        expect(wallet.publicAddress, 'bc1qwatchfirst');
        expect(wallet.masterFingerprint, 'ABCDEF12');
        expect(wallet.derivationPath, "m/84'/0'/0'");

        final captured = verify(
          () => mockSecureSeedStorage.upsertWallet(captureAny()),
        ).captured;
        expect(captured.single, isA<WalletRecord>());
        expect((captured.single as WalletRecord).kind, WalletKind.watchOnly);
        // PERCHÉ: non deve MAI chiamare encryptSeed (nessun segreto).
        verifyNever(
          () => mockCryptoService.encryptSeed(
            seedPhrase: any(named: 'seedPhrase'),
            deviceId: any(named: 'deviceId'),
          ),
        );
      });
    });
  });
}
