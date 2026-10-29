import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:btc_blake2b_wallet/features/onboarding/presentation/splash_screen.dart';
import 'package:btc_blake2b_wallet/l10n/app_localizations.dart';

/// Regressione 27/10: lo splash non deve MAI restare su uno spinner infinito.
/// Se la decisione iniziale fallisce (storage non leggibile) deve comparire una
/// schermata con "Riprova" e la navigazione deve poter essere ritentata.
void main() {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  Widget buildApp() {
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/onboarding', builder: (_, __) => const Text('ONBOARDING')),
        GoRoute(path: '/', builder: (_, __) => const Text('HOME')),
      ],
    );
    return MaterialApp.router(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('storage non decifrabile: si riparte dall\'onboarding',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'OperationError');
    });

    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Un errore di lettura non blocca l'app: si riparte dall'onboarding.
    expect(find.text('ONBOARDING'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('storage che non risponde: dopo il timeout compare Riprova',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (call) => Completer<Object?>().future, // mai completato
    );

    await tester.pumpWidget(buildApp());
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Oltre il timeout di sicurezza: niente spinner infinito.
    await tester.pump(const Duration(seconds: 21));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Unable to start the app'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    // Il retry non deve rompere nulla: riprova e torna all'errore.
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 21));
    await tester.pump();
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('storage OK: onboarding non completato → onboarding',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);

    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('ONBOARDING'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
