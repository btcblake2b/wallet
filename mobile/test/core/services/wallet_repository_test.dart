import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:btc_blake2b_wallet/core/config/bitcoin_network_config.dart';
import 'package:btc_blake2b_wallet/core/models/wallet_record.dart';
import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';
import 'package:btc_blake2b_wallet/core/services/crypto_service.dart';
import 'package:btc_blake2b_wallet/core/services/device_service.dart';
import 'package:btc_blake2b_wallet/core/services/address_pool.dart';
import 'package:btc_blake2b_wallet/core/services/gap_window_policy.dart';
import 'package:btc_blake2b_wallet/core/services/restore_scanner.dart';
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
        // PERCHÉ (26/10): l'xpub si salva alla creazione → le letture
        // (saldo, indirizzi, storico) non richiederanno più la seed.
        expect(wallet.accountXpub, 'tpub_test');
        expect(wallet.hasAccountXpub, isTrue);
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

    group('setTransactionNote', () {
      test('salva la nota trimmata e la persiste sul wallet', () async {
        when(() => mockSecureSeedStorage.upsertWallet(any()))
            .thenAnswer((_) async {});
        final wallet = makeWallet('w1');

        final updated =
            await sut.setTransactionNote(wallet, 'tx1', '  colazione  ');

        expect(updated.noteFor('tx1'), 'colazione');
        // PERCHÉ: il record in ingresso non va mutato (immutabilità).
        expect(wallet.txNotes, isEmpty);
        final captured =
            verify(() => mockSecureSeedStorage.upsertWallet(captureAny()))
                .captured;
        expect((captured.single as WalletRecord).noteFor('tx1'), 'colazione');
      });

      test('nota vuota o di soli spazi rimuove la chiave', () async {
        when(() => mockSecureSeedStorage.upsertWallet(any()))
            .thenAnswer((_) async {});
        final wallet =
            makeWallet('w1').copyWith(txNotes: const {'tx1': 'vecchia'});

        final updated = await sut.setTransactionNote(wallet, 'tx1', '   ');

        expect(updated.txNotes.containsKey('tx1'), isFalse);
        expect(updated.txNotes, isEmpty);
      });

      test('non tocca le etichette UTXO', () async {
        when(() => mockSecureSeedStorage.upsertWallet(any()))
            .thenAnswer((_) async {});
        final wallet =
            makeWallet('w1').copyWith(utxoLabels: const {'txid:0': 'utxo'});

        final updated = await sut.setTransactionNote(wallet, 'tx1', 'nota');

        expect(updated.utxoLabels, {'txid:0': 'utxo'});
        expect(updated.noteFor('tx1'), 'nota');
      });

      test('txid vuoto → ArgumentError e nessuna scrittura', () async {
        final wallet = makeWallet('w1');

        await expectLater(
          sut.setTransactionNote(wallet, '', 'nota'),
          throwsArgumentError,
        );
        verifyNever(() => mockSecureSeedStorage.upsertWallet(any()));
      });
    });

    group('backfillAccountXpub (ADR 02/11-32)', () {
      late MockSecureSeedStorage storage;
      late MockCryptoService crypto;
      late WalletRepository repo;
      late List<WalletRecord> persisted;
      late String realXpub;
      late String realFirstAddress;

      setUp(() {
        storage = MockSecureSeedStorage();
        crypto = MockCryptoService();
        persisted = <WalletRecord>[];
        // xpub VERO del mnemonic di test: serve a dimostrare che gli indirizzi
        // non cambiano dopo il backfill (ADR 02/11-32 §3). `addresses.first` è
        // `/0/0`, cioè il valore che il backfill confronta con `publicAddress`
        // (ADR 02/11-33 §1).
        final saved = deriveWalletData(
          AddressDerivationData(
            'abandon abandon abandon abandon abandon abandon abandon abandon '
                'abandon abandon abandon about',
            "m/84'/0'/0'",
            1,
          ),
        );
        realXpub = saved.xpub;
        realFirstAddress = saved.addresses.first;
        when(() => storage.loadWallets()).thenAnswer((_) async => persisted);
        when(() => storage.upsertWallet(any())).thenAnswer((invocation) async {
          final record = invocation.positionalArguments.first as WalletRecord;
          persisted
            ..removeWhere((w) => w.walletId == record.walletId)
            ..add(record);
        });
        when(
          () => crypto.decryptSeed(
            encryptedSeed: any(named: 'encryptedSeed'),
            deviceId: any(named: 'deviceId'),
          ),
        ).thenAnswer(
          (_) async => 'abandon abandon abandon abandon abandon abandon '
              'abandon abandon abandon abandon abandon about',
        );
        final bitcoin = MockBitcoinService();
        when(
          () => bitcoin.deriveWalletDataFromMnemonic(
            any(),
            derivationPath: any(named: 'derivationPath'),
            addressCount: any(named: 'addressCount'),
          ),
        ).thenAnswer((invocation) async {
          return deriveWalletData(
            AddressDerivationData(
              invocation.positionalArguments.first as String,
              invocation.namedArguments[#derivationPath] as String?,
              invocation.namedArguments[#addressCount] as int,
            ),
          );
        });
        repo = WalletRepository(
          secureSeedStorage: storage,
          deviceService: MockDeviceService(),
          cryptoService: crypto,
          bitcoinService: bitcoin,
          uuid: MockUuid(),
        );
      });

      WalletRecord legacy({
        int receive = 0,
        int change = 0,
        String? publicAddress,
      }) {
        final record = WalletRecord(
          walletId: 'legacy',
          encryptedSeed: 'enc',
          publicAddress: publicAddress ?? realFirstAddress,
          deviceId: 'dev',
          createdAt: DateTime.utc(2026, 10, 20),
          derivationPath: "m/84'/0'/0'",
          nextReceiveIndex: receive,
          nextChangeIndex: change,
        );
        persisted.add(record);
        return record;
      }

      test('wallet hot senza xpub → deriva dal seed e salva', () async {
        final wallet = legacy();

        final updated = await repo.backfillAccountXpub(wallet);

        expect(updated.accountXpub, realXpub);
        // La migrazione PERSISTE: al prossimo avvio non si rifà.
        expect(persisted.single.accountXpub, realXpub);
        verify(
          () => crypto.decryptSeed(
            encryptedSeed: any(named: 'encryptedSeed'),
            deviceId: any(named: 'deviceId'),
          ),
        ).called(1);
      });

      test('wallet con xpub già presente → nessun I/O', () async {
        final wallet = legacy().copyWith(accountXpub: 'xpub_ok');
        persisted[0] = wallet;

        final updated = await repo.backfillAccountXpub(wallet);

        expect(updated.accountXpub, 'xpub_ok');
        verifyNever(
          () => crypto.decryptSeed(
            encryptedSeed: any(named: 'encryptedSeed'),
            deviceId: any(named: 'deviceId'),
          ),
        );
        verifyNever(() => storage.upsertWallet(any()));
      });

      test('watch-only → nessun backfill (la sua xpub è già la fonte)',
          () async {
        final wallet = legacy().copyWith(kind: WalletKind.watchOnly);
        persisted[0] = wallet;

        final updated = await repo.backfillAccountXpub(wallet);

        expect(updated.accountXpub, isNull);
        verifyNever(() => storage.upsertWallet(any()));
      });

      test('record STANTIO non sovrascrive un indice avanzato', () async {
        // PERCHÉ (ADR 02/11-32 §2): il chiamante può tenere in mano un record
        // vecchio. Scriverlo sovrascriverebbe l'indice avanzato nel frattempo:
        // regressione = possibile riuso di un indirizzo.
        final stale = legacy();
        persisted[0] = stale.copyWith(
          nextReceiveIndex: 7,
          nextChangeIndex: 3,
        );

        final updated = await repo.backfillAccountXpub(stale);

        expect(updated.requireNextReceiveIndex(), 7);
        expect(updated.requireNextChangeIndex(), 3);
        expect(updated.accountXpub, realXpub);
      });

      test('persist fallito → nessuno stato parziale, xpub ancora assente',
          () async {
        // PERCHÉ (ADR 02/11-32 §2): fail-closed come per gli indici. La
        // richiesta successiva ripropone `seedRequired`, non un wallet a metà.
        final wallet = legacy();
        when(() => storage.upsertWallet(any()))
            .thenThrow(Exception('disco pieno'));

        await expectLater(
          repo.backfillAccountXpub(wallet),
          throwsA(isA<Exception>()),
        );
        expect(persisted.single.accountXpub, isNull);
      });

      test('dopo il backfill la seed non viene più decifrata', () async {
        // INVARIANTE (ADR 02/11-32 §1): «una volta sola» è verificato sul
        // confine di decifratura, non dedotto dal flusso.
        final wallet = legacy();
        await repo.backfillAccountXpub(wallet);
        clearInteractions(crypto);

        final result = await repo.nextReceiveAddress(
          wallet,
          rotationEnabled: true,
        );

        expect(result.isFresh, isTrue);
        verifyNever(
          () => crypto.decryptSeed(
            encryptedSeed: any(named: 'encryptedSeed'),
            deviceId: any(named: 'deviceId'),
          ),
        );
      });

      test('seed del vault ≠ seed del wallet → lancia e NON persiste',
          () async {
        // PERCHÉ (ADR 02/11-33 §1): `publicAddress` è l'alias di `/0/0` ed è
        // una verità già mostrata all'utente. Con una seed sbagliata il backfill
        // persisterebbe per sempre un xpub che produce indirizzi diversi da
        // quelli con storia on-chain. Fail-closed: nessuna scrittura.
        final wallet = legacy(
          // Indirizzo di un ALTRO wallet (seed diversa).
          publicAddress: deriveWalletData(
            AddressDerivationData(
              'legal winner thank year wave sausage worth useful legal '
                  'winner thank yellow',
              "m/84'/0'/0'",
              1,
            ),
          ).addresses.first,
        );

        await expectLater(
          repo.backfillAccountXpub(wallet),
          throwsA(
            isA<SeedWalletMismatchException>()
                .having((e) => e.walletId, 'walletId', 'legacy')
                .having((e) => e.recordAddress, 'record', wallet.publicAddress),
          ),
        );
        // Il wallet resta com'era: recuperabile, non «valido ma sbagliato».
        expect(persisted.single.accountXpub, isNull);
        expect(persisted.single.publicAddress, wallet.publicAddress);
      });

      test('mismatch anche nel percorso di rotazione, prima di ogni scrittura',
          () async {
        // Lo stesso controllo vale per il backfill implicito dentro
        // `nextReceiveAddress`: se passasse solo lì, un xpub sbagliato
        // finirebbe nella stessa `upsert` che avanza l'indice.
        final wallet = legacy(
          publicAddress: deriveWalletData(
            AddressDerivationData(
              'legal winner thank year wave sausage worth useful legal '
                  'winner thank yellow',
              "m/84'/0'/0'",
              1,
            ),
          ).addresses.first,
        );

        await expectLater(
          repo.nextReceiveAddress(
            wallet,
            rotationEnabled: true,
            mnemonic: 'abandon abandon abandon abandon abandon abandon abandon '
                'abandon abandon abandon abandon about',
          ),
          throwsA(isA<SeedWalletMismatchException>()),
        );
        expect(persisted.single.accountXpub, isNull);
      });
    });
  });

  group('WalletRepository.nextReceiveAddress (A2)', () {
    // Mnemonic di test BIP39 (vettori pubblici): serve solo a derivare.
    const mnemonic =
        'abandon abandon abandon abandon abandon abandon abandon abandon '
        'abandon abandon abandon about';
    const accountPath = "m/84'/0'/0'";

    late MockSecureSeedStorage storage;
    late MockCryptoService crypto;
    late WalletRepository sut;
    late List<WalletRecord> persisted;

    setUpAll(() {
      // PERCHÉ: `verifyNever(() => storage.upsertWallet(any()))` richiede un
      // fallback registrato per `WalletRecord` anche in questo gruppo.
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
      storage = MockSecureSeedStorage();
      crypto = MockCryptoService();
      persisted = <WalletRecord>[];
      when(() => storage.loadWallets()).thenAnswer((_) async => persisted);
      when(() => storage.upsertWallet(any())).thenAnswer((invocation) async {
        final record = invocation.positionalArguments.first as WalletRecord;
        persisted
          ..removeWhere((w) => w.walletId == record.walletId)
          ..add(record);
      });
      final bitcoin = MockBitcoinService();
      // PERCHÉ (ADR 02/11-32 §3): il backfill dentro `nextReceiveAddress` deriva
      // l'xpub VERO dal mnemonic di test, così gli indirizzi restano identici a
      // quelli attesi (derivazione dal seed = derivazione dall'xpub). Uno stub
      // con una stringa finta farebbe fallire la derivazione dal blocco.
      when(
        () => bitcoin.deriveWalletDataFromMnemonic(
          any(),
          derivationPath: any(named: 'derivationPath'),
          addressCount: any(named: 'addressCount'),
        ),
      ).thenAnswer((invocation) async {
        return deriveWalletData(
          AddressDerivationData(
            invocation.positionalArguments.first as String,
            invocation.namedArguments[#derivationPath] as String?,
            invocation.namedArguments[#addressCount] as int,
          ),
        );
      });
      sut = WalletRepository(
        secureSeedStorage: storage,
        deviceService: MockDeviceService(),
        cryptoService: crypto,
        bitcoinService: bitcoin,
        uuid: MockUuid(),
      );
    });

    String expectedAddress(int index) => deriveAddressBlock(
          AddressBlockRequest(
            mnemonic: mnemonic,
            derivationPath: accountPath,
            start: index,
            count: 1,
          ),
        ).external.single;

    WalletRecord makeRecord({
      IndicesState state = IndicesState.valid,
      int receive = 0,
      int change = 0,
    }) {
      // PERCHÉ `expectedAddress(0)` (ADR 02/11-33 §1): `publicAddress` è l'alias
      // di `/0/0`, e il backfill lo usa come oracolo per verificare che la seed
      // del vault corrisponda al wallet. Un indirizzo finto qui farebbe lanciare
      // `SeedWalletMismatchException` a ogni test.
      if (state == IndicesState.legacyUninitialized) {
        return WalletRecord(
          walletId: 'w1',
          encryptedSeed: 'enc',
          publicAddress: expectedAddress(0),
          deviceId: 'dev',
          createdAt: DateTime.utc(2026, 10, 30),
          derivationPath: accountPath,
          indicesState: IndicesState.legacyUninitialized,
        );
      }
      return WalletRecord(
        walletId: 'w1',
        encryptedSeed: 'enc',
        publicAddress: expectedAddress(0),
        deviceId: 'dev',
        createdAt: DateTime.utc(2026, 10, 30),
        derivationPath: accountPath,
        nextReceiveIndex: receive,
        nextChangeIndex: change,
      );
    }

    /// Risultato di una scansione conclusa: solo `gapFound` è applicabile.
    RestoreScanResult concludedScan(int scannedIndex) => RestoreScanResult(
          outcome: GapWindowOutcome.gapFound,
          probed: scannedIndex + 20,
          derived: scannedIndex + 20,
          requested: scannedIndex + 20,
          unreachable: 0,
          lastPhaseBudgetEstimated: false,
          scannedIndex: scannedIndex,
        );

    test('rotazione: write-ahead persistito PRIMA dell\'indirizzo', () async {
      final record = makeRecord();
      persisted.add(record);

      final result = await sut.nextReceiveAddress(
        record,
        rotationEnabled: true,
        mnemonic: mnemonic,
      );

      expect(result.index, 0);
      expect(result.address, expectedAddress(0));
      // Path completo: /0/0 sotto l'account, non solo l'indirizzo.
      expect(result.derivationPath, "$accountPath/0/0");
      expect(result.persisted, isTrue);
      // Persistito già avanzato a 1 quando l'indirizzo è stato restituito.
      expect(persisted.single.requireNextReceiveIndex(), 1);
      expect(result.record.requireNextReceiveIndex(), 1);
    });

    test('persist fallito: nessun indirizzo restituito', () async {
      final record = makeRecord();
      persisted.add(record);
      when(() => storage.upsertWallet(any()))
          .thenAnswer((_) async => throw StateError('storage down'));

      await expectLater(
        sut.nextReceiveAddress(
          record,
          rotationEnabled: true,
          mnemonic: mnemonic,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('flag off + valid: usa /0/N senza avanzare', () async {
      final record = makeRecord(receive: 3);
      persisted.add(record);

      final result = await sut.nextReceiveAddress(
        record,
        rotationEnabled: false,
        mnemonic: mnemonic,
      );

      expect(result.index, 3);
      expect(result.address, expectedAddress(3));
      expect(result.persisted, isFalse);
      expect(persisted.single.requireNextReceiveIndex(), 3);
      verifyNever(() => storage.upsertWallet(any()));
    });

    test('flag off + legacy: publicAddress, nessuna scrittura', () async {
      final record = makeRecord(state: IndicesState.legacyUninitialized);
      persisted.add(record);

      final result = await sut.nextReceiveAddress(
        record,
        rotationEnabled: false,
        mnemonic: mnemonic,
      );

      expect(result.address, expectedAddress(0));
      expect(result.index, 0);
      expect(result.persisted, isFalse);
      verifyNever(() => storage.upsertWallet(any()));
    });

    test('flag on + legacy: adozione solo con conferma esplicita', () async {
      final record = makeRecord(state: IndicesState.legacyUninitialized);
      persisted.add(record);

      await expectLater(
        sut.nextReceiveAddress(
          record,
          rotationEnabled: true,
          mnemonic: mnemonic,
        ),
        throwsA(isA<WalletIndicesAdoptionRequiredException>()),
      );
      verifyNever(() => storage.upsertWallet(any()));

      final adopted = await sut.nextReceiveAddress(
        record,
        rotationEnabled: true,
        adoptLegacy: true,
        mnemonic: mnemonic,
      );

      expect(adopted.index, 0);
      expect(adopted.address, expectedAddress(0));
      expect(persisted.single.indicesState, IndicesState.valid);
      expect(persisted.single.requireNextReceiveIndex(), 1);
    });

    test('corrotto: fail-closed anche con flag spento', () async {
      final corrupt = WalletRecord.fromMap(<String, dynamic>{
        'wallet_id': 'w1',
        'encrypted_seed': 'enc',
        'public_address': expectedAddress(0),
        'device_id': 'dev',
        'created_at': '2026-10-30T00:00:00.000Z',
        'schema_version': 2,
        'next_receive_index': -4,
        'next_change_index': 0,
      });
      persisted.add(corrupt);

      for (final rotation in [true, false]) {
        await expectLater(
          sut.nextReceiveAddress(
            corrupt,
            rotationEnabled: rotation,
            mnemonic: mnemonic,
          ),
          throwsA(isA<CorruptWalletIndicesException>()),
        );
      }
    });

    test('anomalo: fail-closed con eccezione dedicata', () async {
      final anomalous = WalletRecord.fromMap(<String, dynamic>{
        'wallet_id': 'w1',
        'encrypted_seed': 'enc',
        'public_address': expectedAddress(0),
        'device_id': 'dev',
        'created_at': '2026-10-30T00:00:00.000Z',
        'schema_version': 2,
        'next_receive_index': WalletRecord.maxDerivationIndex + 1,
        'next_change_index': 0,
      });
      persisted.add(anomalous);

      await expectLater(
        sut.nextReceiveAddress(
          anomalous,
          rotationEnabled: true,
          mnemonic: mnemonic,
        ),
        throwsA(isA<AnomalousWalletIndexException>()),
      );
    });

    test('due richieste concorrenti: interleaving reale, indici distinti',
        () async {
      final record = makeRecord();
      persisted.add(record);
      // Persist LENTO: la seconda richiesta parte mentre la prima è ancora
      // dentro `upsertWallet`. Senza la coda del repository entrambe
      // leggerebbero l'indice 0 e una delle due tornerebbe «già assegnato»
      // (indice duplicato) — l'assert {0,1} è ciò che distingue.
      when(() => storage.upsertWallet(any())).thenAnswer((invocation) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        final record = invocation.positionalArguments.first as WalletRecord;
        persisted
          ..removeWhere((w) => w.walletId == record.walletId)
          ..add(record);
      });

      final first = sut.nextReceiveAddress(
        record,
        rotationEnabled: true,
        mnemonic: mnemonic,
      );
      final second = sut.nextReceiveAddress(
        record,
        rotationEnabled: true,
        mnemonic: mnemonic,
      );

      final results = await Future.wait([first, second]);

      expect(results.map((r) => r.index).toSet(), {0, 1});
      expect(results.map((r) => r.address).toSet(), hasLength(2));
      expect(results.every((r) => r.isFresh), isTrue);
      expect(persisted.single.requireNextReceiveIndex(), 2);
    });

    test('flag off: isFresh falso, indirizzo non presentato come nuovo',
        () async {
      // PERCHÉ: la UI deve dire «nuovo indirizzo» solo quando l'avanzamento è
      // avvenuto davvero; l'indice da solo non basta a distinguerlo.
      final record = makeRecord(receive: 2);
      persisted.add(record);

      final result = await sut.nextReceiveAddress(
        record,
        rotationEnabled: false,
        mnemonic: mnemonic,
      );

      expect(result.isFresh, isFalse);
      expect(result.persisted, isFalse);
    });

    test('derivazione fallita DOPO persist riuscito: buco dichiarato',
        () async {
      // PERCHÉ (ADR 30/10-12): write-ahead + derive fallita ⇒ il record è già
      // a N+1 e nessun indirizzo viene mostrato. Sicuro (nessun reuse), ma il
      // comportamento va fissato: il prossimo incasso parte da N+1.
      final record = makeRecord(receive: 4);
      persisted.add(record);

      await expectLater(
        sut.nextReceiveAddress(record, rotationEnabled: true),
        throwsA(isA<SeedUnavailableException>()),
      );

      expect(persisted.single.requireNextReceiveIndex(), 5);
      // Il buco è l'indice 4: nessun indirizzo è stato mostrato per quell'indice.
    });

    test('applyRestore: max(record, scan), e non scrive se invariato',
        () async {
      final record = makeRecord(receive: 4);
      persisted.add(record);

      // Scansione più indietro del record: il record NON scende, e la
      // contraddizione viene segnalata (ADR 31/10-18 §5).
      final unchanged = await sut.applyRestore('w1', concludedScan(2));
      expect(unchanged.record.requireNextReceiveIndex(), 4);
      expect(unchanged.recordAboveScan, isTrue);
      expect(unchanged.delta, 2);
      expect(unchanged.persisted, isFalse);
      verifyNever(() => storage.upsertWallet(any()));

      // Scansione più avanti: vince la scansione, e persiste. `delta` è
      // firmato: negativo quando la scansione ha trovato più uso.
      final advanced = await sut.applyRestore('w1', concludedScan(9));
      expect(advanced.record.requireNextReceiveIndex(), 9);
      expect(advanced.recordAboveScan, isFalse);
      expect(advanced.delta, -5);
      expect(advanced.persisted, isTrue);
      expect(persisted.single.requireNextReceiveIndex(), 9);
    });

    test('scan null: l\'eccezione porta anche i numeri per la parity label',
        () async {
      // PERCHÉ (ADR 01/11-25 §4): la UI che mostra «Ricezione: X/Y» ha bisogno
      // di `probed/requested`; con solo l'`outcome` non potrebbe scriverla.
      final record = makeRecord(receive: 0);
      persisted.add(record);

      await expectLater(
        sut.applyRestore(
          'w1',
          const RestoreScanResult(
            outcome: GapWindowOutcome.gapNotEstablished,
            probed: 40,
            derived: 40,
            requested: 40,
            unreachable: 0,
            lastPhaseBudgetEstimated: false,
          ),
        ),
        throwsA(
          isA<IncompleteRestoreException>()
              .having(
                (e) => e.outcome,
                'outcome',
                GapWindowOutcome.gapNotEstablished,
              )
              .having((e) => e.result.probed, 'probed', 40)
              .having((e) => e.result.requested, 'requested', 40)
              .having(
                (e) => e.result.probedFraction,
                'probedFraction',
                1.0,
              ),
        ),
      );
      verifyNever(() => storage.upsertWallet(any()));
    });

    test('applyRestore con scan non concluso: eccezione, nessuna scrittura',
        () async {
      // PERCHÉ (ADR 31/10-19 §2): il tipo `RestoreScanResult` rende la
      // chiamata illegale esplicita — un risultato non conclusivo non ha un
      // indice, e `applyRestore` lo rifiuta portando con sé l'esito.
      final record = makeRecord(receive: 0);
      persisted.add(record);

      await expectLater(
        sut.applyRestore(
          'w1',
          const RestoreScanResult(
            outcome: GapWindowOutcome.unreachable,
            probed: 20,
            derived: 20,
            requested: 20,
            unreachable: 20,
            lastPhaseBudgetEstimated: true,
          ),
        ),
        throwsA(
          isA<IncompleteRestoreException>().having(
            (e) => e.outcome,
            'outcome',
            GapWindowOutcome.unreachable,
          ),
        ),
      );
      verifyNever(() => storage.upsertWallet(any()));
      expect(persisted.single.requireNextReceiveIndex(), 0);
    });

    test('applyRestore fallito: nessuna scrittura e lock rilasciato', () async {
      // PERCHÉ (ADR 31/10-15 §3): un restore fallito non deve bloccare il
      // wallet fino al restart — dopo l'eccezione la coda deve accettare la
      // prossima operazione (qui: advanceReceiveIndex).
      final corrupt = WalletRecord.fromMap(<String, dynamic>{
        'wallet_id': 'w1',
        'encrypted_seed': 'enc',
        'public_address': expectedAddress(0),
        'device_id': 'dev',
        'created_at': '2026-10-30T00:00:00.000Z',
        'schema_version': 2,
        'next_receive_index': -7,
        'next_change_index': 0,
      });
      persisted.add(corrupt);

      await expectLater(
        sut.applyRestore('w1', concludedScan(5)),
        throwsA(isA<CorruptWalletIndicesException>()),
      );
      verifyNever(() => storage.upsertWallet(any()));

      // Il wallet torna utilizzabile: qui lo stato è corrotto, quindi un
      // advanceReceiveIndex deve fallire per lo STATO e non per il lock —
      // cioè deve rispondere subito con l'eccezione dedicata.
      final valid = makeRecord(receive: 1);
      persisted
        ..clear()
        ..add(valid);
      final advanced = await sut.advanceReceiveIndex(valid, expected: 1);
      expect(advanced.requireNextReceiveIndex(), 2);
    });

    test('advanceChangeIndex via repository: coda + CAS + write-ahead',
        () async {
      final record = makeRecord(change: 7);
      persisted.add(record);

      final advanced = await sut.advanceChangeIndex(record, expected: 7);

      expect(advanced.requireNextChangeIndex(), 8);
      expect(persisted.single.requireNextChangeIndex(), 8);

      // Riavvio del tentativo con lo stesso expected: conflitto, nessuna scrittura.
      await expectLater(
        sut.advanceChangeIndex(record, expected: 7),
        throwsA(isA<IndexConflictException>()),
      );
      expect(persisted.single.requireNextChangeIndex(), 8);
    });

    test('advanceChangeIndex su record corrotto: fail-closed', () async {
      final corrupt = WalletRecord.fromMap(<String, dynamic>{
        'wallet_id': 'w1',
        'encrypted_seed': 'enc',
        'public_address': expectedAddress(0),
        'device_id': 'dev',
        'created_at': '2026-10-30T00:00:00.000Z',
        'schema_version': 2,
        'next_receive_index': 0,
        'next_change_index': -3,
      });
      persisted.add(corrupt);

      await expectLater(
        sut.advanceChangeIndex(corrupt, expected: 0),
        throwsA(isA<CorruptWalletIndicesException>()),
      );
      verifyNever(() => storage.upsertWallet(any()));
    });

    test('advanceChangeIndex concorrente: una vince, l\'altra conflitto',
        () async {
      // PERCHÉ (ADR 30/10-13): receive e change condividono la STESSA coda per
      // walletId — il record è un'unità. Due advance concorrenti sullo stesso
      // expected non devono produrre due avanzamenti.
      final record = makeRecord(change: 3);
      persisted.add(record);
      when(() => storage.upsertWallet(any())).thenAnswer((invocation) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        final record = invocation.positionalArguments.first as WalletRecord;
        persisted
          ..removeWhere((w) => w.walletId == record.walletId)
          ..add(record);
      });

      final futures = [
        sut.advanceChangeIndex(record, expected: 3),
        sut.advanceChangeIndex(record, expected: 3),
      ];
      final settled = await Future.wait(
        futures
            .map((f) => f.then<Object?>((v) => v).catchError((Object e) => e)),
      );

      final successes = settled.whereType<WalletRecord>();
      final conflicts = settled.whereType<IndexConflictException>();
      expect(successes, hasLength(1));
      expect(conflicts, hasLength(1));
      expect(conflicts.single.expected, 3);
      expect(conflicts.single.actual, 4);
      expect(persisted.single.requireNextChangeIndex(), 4);
    });

    test('applyRestore concorrente con nextReceiveAddress: nessun riuso',
        () async {
      // PERCHÉ (ADR 31/10-16 §4): la risoluzione deve avvenire DENTRO la coda,
      // sul record fresco. Se leggesse il record prima di entrare, un
      // nextReceiveAddress concorrente avanzerebbe a N+1 e il `max` userebbe un
      // record stale.
      final record = makeRecord(receive: 2);
      persisted.add(record);
      when(() => storage.upsertWallet(any())).thenAnswer((invocation) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        final record = invocation.positionalArguments.first as WalletRecord;
        persisted
          ..removeWhere((w) => w.walletId == record.walletId)
          ..add(record);
      });

      final restore = sut.applyRestore('w1', concludedScan(5));
      final receive = sut.nextReceiveAddress(
        record,
        rotationEnabled: true,
        mnemonic: mnemonic,
      );

      final settled = await Future.wait<Object>([restore, receive]);
      final restored = (settled[0] as RestoreApplyResult).record;
      final address = settled[1] as ReceiveAddressResult;

      // L'esito dipende dall'ordine (entrambi accettabili), ma nessuno dei due
      // può restituire un indice già consumato né scendere sotto il punto di
      // partenza.
      final finalIndex = persisted.single.requireNextReceiveIndex();
      expect(finalIndex, greaterThanOrEqualTo(5));
      expect(address.index, anyOf(2, 5));
      expect(restored.requireNextReceiveIndex(), greaterThanOrEqualTo(5));
      // Il valore finale può essere più avanti del record restituito dal
      // restore (se la ricezione è passata dopo), ma mai più indietro.
      expect(
        finalIndex,
        greaterThanOrEqualTo(restored.requireNextReceiveIndex()),
      );
    });

    test('watch-only (xpub) e hot (seed) derivano gli stessi 21 indirizzi',
        () async {
      // PERCHÉ (ADR 30/10-7 §4): copre entrambi i percorsi di derivazione — non
      // solo quello di produzione. Confronta PATH COMPLETI, non solo indirizzi:
      // due path diversi con lo stesso indirizzo sarebbero un bug.
      final seed = bip39.mnemonicToSeed(mnemonic);
      final root = bip32.BIP32.fromSeed(
        seed,
        BitcoinNetworkConfig.bip32NetworkType,
      );
      final xpub = root.derivePath(accountPath).neutered().toBase58();

      final watchOnly = WalletRecord(
        walletId: 'wo',
        encryptedSeed: '',
        publicAddress: expectedAddress(0),
        deviceId: 'dev',
        createdAt: DateTime.utc(2026, 10, 30),
        derivationPath: accountPath,
        kind: WalletKind.watchOnly,
        accountXpub: xpub,
      );
      final hot = WalletRecord(
        walletId: 'hot',
        encryptedSeed: 'enc',
        publicAddress: expectedAddress(0),
        deviceId: 'dev',
        createdAt: DateTime.utc(2026, 10, 30),
        derivationPath: accountPath,
      );
      persisted.addAll([watchOnly, hot]);

      for (var i = 0; i < 21; i++) {
        final fromXpub = await sut.nextReceiveAddress(
          watchOnly,
          rotationEnabled: true,
        );
        final fromSeed = await sut.nextReceiveAddress(
          hot,
          rotationEnabled: true,
          mnemonic: mnemonic,
        );

        expect(
          fromXpub.address,
          fromSeed.address,
          reason: 'indirizzo diverso a /0/$i',
        );
        expect(
          fromXpub.derivationPath,
          fromSeed.derivationPath,
          reason: 'path diverso a /0/$i',
        );
        expect(fromXpub.derivationPath, '$accountPath/0/$i');
      }
      // Entrambi hanno avanzato di 21: nessun indice consumato due volte.
      expect(
        persisted
            .firstWhere((w) => w.walletId == 'wo')
            .requireNextReceiveIndex(),
        21,
      );
      expect(
        persisted
            .firstWhere((w) => w.walletId == 'hot')
            .requireNextReceiveIndex(),
        21,
      );
    });

    test('wallet senza xpub e senza seed: errore chiaro, nessun indirizzo',
        () async {
      final record = makeRecord(receive: 2);
      persisted.add(record);

      await expectLater(
        sut.nextReceiveAddress(record, rotationEnabled: true),
        throwsA(isA<SeedUnavailableException>()),
      );
      // Write-ahead: il floor avanza PRIMA di derivare, quindi il record è già
      // a 3 e nessun indirizzo è stato mostrato (buco dichiarato, ADR 30/10-12).
      expect(persisted.single.requireNextReceiveIndex(), 3);
    });
  });
}
