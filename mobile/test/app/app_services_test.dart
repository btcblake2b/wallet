import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:btc_blake2b_wallet/app/app.dart';
import 'package:btc_blake2b_wallet/core/services/app_lock_service.dart';
import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';
import 'package:btc_blake2b_wallet/core/services/biometric_service.dart';
import 'package:btc_blake2b_wallet/core/services/consent_service.dart';
import 'package:btc_blake2b_wallet/core/services/crypto_service.dart';
import 'package:btc_blake2b_wallet/core/services/device_service.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_connection_store.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_service_mock.dart';
import 'package:btc_blake2b_wallet/core/services/wallet_repository.dart';

class MockWalletRepository extends Mock implements WalletRepository {}

class MockBiometricService extends Mock implements BiometricService {}

class MockBitcoinService extends Mock implements BitcoinService {}

class MockCryptoService extends Mock implements CryptoService {}

class MockDeviceService extends Mock implements DeviceService {}

class MockConsentService extends Mock implements ConsentService {}

void main() {
  group('AppServices', () {
    late MockWalletRepository mockWalletRepository;
    late MockBiometricService mockBiometricService;
    late MockBitcoinService mockBitcoinService;
    late MockCryptoService mockCryptoService;
    late MockDeviceService mockDeviceService;
    late MockConsentService mockConsentService;
    late AppServices sut;

    setUp(() {
      mockWalletRepository = MockWalletRepository();
      mockBiometricService = MockBiometricService();
      mockBitcoinService = MockBitcoinService();
      mockCryptoService = MockCryptoService();
      mockDeviceService = MockDeviceService();
      mockConsentService = MockConsentService();
      sut = AppServices(
        walletRepository: mockWalletRepository,
        biometricService: mockBiometricService,
        bitcoinService: mockBitcoinService,
        cryptoService: mockCryptoService,
        deviceService: mockDeviceService,
        consentService: mockConsentService,
        appLockService: AppLockService.test(),
        lightningService: LightningServiceMock(),
        lightningConnectionStore: LightningConnectionStore(),
      );
    });

    test('should instantiate', () {
      expect(sut, isNotNull);
    });

    // TODO: Implementa test per i metodi pubblici
  });
}
