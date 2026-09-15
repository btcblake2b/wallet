import 'package:btc_blake2b_wallet/core/services/app_lock_service.dart';
import 'package:btc_blake2b_wallet/core/services/balance_cache.dart';
import 'package:btc_blake2b_wallet/core/services/biometric_service.dart';
import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';
import 'package:btc_blake2b_wallet/core/services/crypto_service.dart';
import 'package:btc_blake2b_wallet/core/services/device_service.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_connection_store.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_service_mock.dart';
import 'package:btc_blake2b_wallet/core/services/locale_provider.dart';
import 'package:btc_blake2b_wallet/core/services/wallet_repository.dart';
import 'package:btc_blake2b_wallet/features/wallet/presentation/home_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWalletRepository extends Mock implements WalletRepository {}

class MockBiometricService extends Mock implements BiometricService {}

class MockBitcoinService extends Mock implements BitcoinService {}

class MockCryptoService extends Mock implements CryptoService {}

class MockDeviceService extends Mock implements DeviceService {}

void main() {
  setUp(() {
    // PERCHÉ: la cache saldi è statica — va resettata tra i test.
    BalanceCache.resetForTest();
  });

  Widget buildHome({LightningServiceMock? lightningService}) {
    final walletRepository = MockWalletRepository();
    when(() => walletRepository.loadWallets()).thenAnswer((_) async => []);
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: HomeScreen(
        walletRepository: walletRepository,
        biometricService: MockBiometricService(),
        bitcoinService: MockBitcoinService(),
        cryptoService: MockCryptoService(),
        deviceService: MockDeviceService(),
        localeProvider: LocaleProvider(),
        appLockService: AppLockService.test(),
        lightningService: lightningService,
        lightningConnectionStore:
            lightningService == null ? null : LightningConnectionStore(),
      ),
    );
  }

  testWidgets('toggle On-chain/Lightning: cambia la vista', (tester) async {
    await tester
        .pumpWidget(buildHome(lightningService: LightningServiceMock()));
    await tester.pumpAndSettle();

    // Toggle presente con entrambi i segmenti.
    expect(find.text('On-chain'), findsOneWidget);
    expect(find.text('Lightning'), findsOneWidget);
    // Vista on-chain attiva (nessuna CTA Lightning).
    expect(find.text('No Lightning node connected'), findsNothing);

    // Seleziona Lightning → compare la vista Lightning.
    await tester.tap(find.text('Lightning'));
    await tester.pumpAndSettle();
    expect(find.text('No Lightning node connected'), findsOneWidget);

    // Torna a On-chain → la vista Lightning sparisce.
    await tester.tap(find.text('On-chain'));
    await tester.pumpAndSettle();
    expect(find.text('No Lightning node connected'), findsNothing);
  });

  testWidgets('senza servizio Lightning il toggle non appare', (tester) async {
    await tester.pumpWidget(buildHome());
    await tester.pumpAndSettle();

    expect(find.text('Lightning'), findsNothing);
    expect(find.text('On-chain'), findsNothing);
  });
}
