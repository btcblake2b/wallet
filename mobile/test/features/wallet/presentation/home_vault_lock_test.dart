import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:btc_blake2b_wallet/core/config/bitcoin_network_config.dart';
import 'package:btc_blake2b_wallet/core/models/wallet_record.dart';
import 'package:btc_blake2b_wallet/core/services/app_lock_service.dart';
import 'package:btc_blake2b_wallet/core/services/biometric_service.dart';
import 'package:btc_blake2b_wallet/core/services/bitcoin_service.dart';
import 'package:btc_blake2b_wallet/core/services/crypto_service.dart';
import 'package:btc_blake2b_wallet/core/services/device_service.dart';
import 'package:btc_blake2b_wallet/core/services/locale_provider.dart';
import 'package:btc_blake2b_wallet/core/services/storage_lock_exception.dart';
import 'package:btc_blake2b_wallet/core/services/wallet_repository.dart';
import 'package:btc_blake2b_wallet/features/wallet/presentation/home_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

class MockWalletRepository extends Mock implements WalletRepository {}

class MockBiometricService extends Mock implements BiometricService {}

class MockBitcoinService extends Mock implements BitcoinService {}

class MockCryptoService extends Mock implements CryptoService {}

class MockDeviceService extends Mock implements DeviceService {}

/// Regressione auto-lock web (27/10): allo scadere del timer le chiavi vengono
/// rimosse dalla RAM e leggere lo storage solleva [StorageLockedException].
/// Quello stato NON è un errore: i wallet non devono sparire dalla home e non
/// deve comparire "impossibile leggere il wallet".
void main() {
  setUpAll(() {
    registerFallbackValue(WalletScriptType.p2wpkh);
  });

  Widget buildHome(WalletRepository repository) => MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScreen(
          walletRepository: repository,
          biometricService: MockBiometricService(),
          bitcoinService: MockBitcoinService(),
          cryptoService: MockCryptoService(),
          deviceService: MockDeviceService(),
          localeProvider: LocaleProvider(),
          appLockService: AppLockService.test(),
        ),
      );

  testWidgets('vault bloccato: banner di sblocco, mai errore di lettura',
      (tester) async {
    final repository = MockWalletRepository();
    when(() => repository.loadWallets()).thenThrow(
      StorageLockedException('Storage cifrato con password'),
    );

    await tester.pumpWidget(buildHome(repository));
    await tester.pumpAndSettle();

    expect(find.text('Vault locked'), findsOneWidget);
    expect(find.text('Unlock'), findsOneWidget);
    // Niente errore generico di lettura e niente falso primo avvio.
    expect(find.textContaining('Error loading wallet'), findsNothing);
    expect(find.textContaining('StorageLockedException'), findsNothing);
    expect(
      find.text(
        'No wallets yet',
      ),
      findsNothing,
    );
  });

  testWidgets('lista già caricata: il reload a vault bloccato non la cancella',
      (tester) async {
    // Viewport alto: la card del wallet deve essere costruita (ListView lazy).
    tester.view.physicalSize = const Size(500, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = MockWalletRepository();
    final wallet = WalletRecord(
      walletId: 'w-lock',
      encryptedSeed: '',
      publicAddress: 'bc1qlocktest',
      deviceId: 'dev',
      createdAt: DateTime(2024, 1, 1),
      name: 'Risparmio',
      kind: WalletKind.watchOnly,
    );
    var locked = false;
    when(() => repository.loadWallets()).thenAnswer((_) async {
      if (locked) {
        throw StorageLockedException('Storage cifrato con password');
      }
      return [wallet];
    });

    await tester.pumpWidget(buildHome(repository));
    await tester.pumpAndSettle();

    expect(find.text('Risparmio'), findsOneWidget);
    expect(find.text('Vault locked'), findsNothing);

    // Il timer scatta: da qui in poi lo storage è illeggibile.
    locked = true;

    // Pull-to-refresh = percorso che prima mostrava l'errore svuotando la lista.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ListView).first),
    );
    for (var i = 0; i < 8; i++) {
      await gesture.moveBy(const Offset(0, 100));
      await tester.pump();
    }
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Risparmio'), findsOneWidget);
    expect(find.text('Vault locked'), findsOneWidget);
    expect(find.textContaining('Error loading wallet'), findsNothing);
  });
}
