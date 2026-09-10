import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/services/biometric_service.dart';
import '../core/services/bitcoin_service.dart';
import '../core/services/consent_service.dart';
import '../core/services/crypto_service.dart';
import '../core/services/device_service.dart';
import '../core/services/locale_provider.dart';
import '../core/services/secure_seed_storage.dart';
import '../core/services/theme_provider.dart';
import '../core/services/wallet_repository.dart';
import '../core/theme/app_theme.dart';
import '../features/donate/presentation/donate_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/onboarding/presentation/splash_screen.dart';
import '../features/settings/presentation/about_screen.dart';
import '../features/wallet/presentation/home_screen.dart';
import '../l10n/app_localizations.dart';

/// Servizi condivisi dell'app (dependency injection semplice, senza backend).
class AppServices {
  AppServices({
    required this.walletRepository,
    required this.biometricService,
    required this.bitcoinService,
    required this.cryptoService,
    required this.deviceService,
    required this.consentService,
  });

  final WalletRepository walletRepository;
  final BiometricService biometricService;
  final BitcoinService bitcoinService;
  final CryptoService cryptoService;
  final DeviceService deviceService;
  final ConsentService consentService;
}

class BtcBlake2bWalletApp extends StatelessWidget {
  BtcBlake2bWalletApp({
    super.key,
    required this.services,
    required this.localeProvider,
    required this.themeProvider,
  });

  final AppServices services;
  final LocaleProvider localeProvider;
  final ThemeProvider themeProvider;

  static Future<AppServices> bootstrap() async {
    // PERCHÉ: wallet 100% locale senza backend Firebase → nessuna init cloud.
    final secureSeedStorage = SecureSeedStorage();
    final deviceService = DeviceService();
    final cryptoService = CryptoService();
    final bitcoinService = BitcoinService();
    final biometricService = BiometricService();
    final consentService = ConsentService();

    final walletRepository = WalletRepository(
      secureSeedStorage: secureSeedStorage,
      deviceService: deviceService,
      cryptoService: cryptoService,
      bitcoinService: bitcoinService,
    );

    return AppServices(
      walletRepository: walletRepository,
      biometricService: biometricService,
      bitcoinService: bitcoinService,
      cryptoService: cryptoService,
      deviceService: deviceService,
      consentService: consentService,
    );
  }

  /// Inizializza i provider UI (locale + tema) con la preferenza persistita.
  static Future<void> initProviders({
    required LocaleProvider localeProvider,
    required ThemeProvider themeProvider,
  }) async {
    await Future.wait([localeProvider.init(), themeProvider.init()]);
  }

  @override
  Widget build(BuildContext context) {
    // GoRouter is cached via a late-final backing field so it is only
    // created once, even when the parent rebuilds. The router itself
    // does not depend on the locale — only the pages it renders do.
    final router = _router;

    return ListenableBuilder(
      listenable: Listenable.merge([localeProvider, themeProvider]),
      builder: (context, _) {
        // Using ValueKey(locale) forces a full widget subtree rebuild when
        // the locale changes, ensuring all AppLocalizations.of(context)
        // calls return the new translations without a page reload.
        return MaterialApp.router(
          key: ValueKey(localeProvider.locale),
          title: 'Btc Blake2b Wallet',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: router,
          locale: localeProvider.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        );
      },
    );
  }

  late final GoRouter _router = GoRouter(
    // PERCHÉ (C003): inizialmente va allo splash che decide se mostrare
    // onboarding o home. Il redirect blocca l'accesso a / se onboarding
    // non completato.
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (_, __) => HomeScreen(
          walletRepository: services.walletRepository,
          biometricService: services.biometricService,
          bitcoinService: services.bitcoinService,
          cryptoService: services.cryptoService,
          deviceService: services.deviceService,
          localeProvider: localeProvider,
          themeProvider: themeProvider,
        ),
      ),
      GoRoute(
        path: '/donate',
        name: 'donate',
        builder: (_, __) => const DonateScreen(),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (_, __) => const AboutScreen(),
      ),
    ],
  );
}
