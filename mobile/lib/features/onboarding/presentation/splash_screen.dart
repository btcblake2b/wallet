// PERCHÉ (C003+C008): Schermata splash che decide il routing iniziale.
// GoRouter.redirect non può usare contesto asincrono (flutter_secure_storage),
// quindi usiamo uno SplashScreen come "decision point" che legge lo storage
// e reindirizza a OnboardingScreen o HomeScreen.
//
// Pattern suggerito dal feedback sulla Fase 2: evita di chiamare
// flutter_secure_storage dentro GoRouter.redirect.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/bitcoin_network_config.dart';
import '../../../core/services/network_migration_service.dart';
import '../../../core/services/onboarding_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    // PERCHÉ (mainnet 2026-08-31): al primo avvio su una rete diversa da quella
    // con cui sono stati creati i dati locali, si resetta tutto e si riparte
    // dall'onboarding. La derivazione cambia (m/84'/1'/0' testnet → m/84'/0'/0'
    // mainnet), quindi i wallet testnet (tb1...) sarebbero inutilizzabili.
    final migration = NetworkMigrationService();
    if (await migration.isMigrationNeeded()) {
      await migration.resetAllData();
      await migration.setStoredNetwork(BitcoinNetworkConfig.current.name);
    }

    final onboardingService = OnboardingService();
    final completed = await onboardingService.isCompleted();

    if (!mounted) return;

    // PERCHÉ: usiamo GoRouter.go() per una navigazione pulita
    // che sostituisce lo splash nello stack. Se onboarding completato → home,
    // altrimenti → onboarding screen.
    if (completed) {
      context.go('/');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    // PERCHÉ: mostriamo il logo/loader mentre verifichiamo lo stato
    // onboarding. Lo splash è minimale e non richiede stringhe localizzate
    // perché viene mostrato per meno di 1 secondo.
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
