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
import '../../../l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Object? _error;
  bool _retrying = false;

  /// PERCHÉ: se la decisione iniziale non arriva a termine (storage non
  /// leggibile, dato corrotto, attesa che non si chiude) l'utente resterebbe
  /// davanti a uno spinner infinito senza via d'uscita. Ogni esito anomalo
  /// diventa una schermata con "Riprova".
  static const _startupTimeout = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    if (mounted) {
      setState(() {
        _error = null;
        _retrying = true;
      });
    }
    try {
      await _routeFromStorage().timeout(_startupTimeout);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _retrying = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() => _retrying = false);
  }

  Future<void> _routeFromStorage() async {
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
    final error = _error;
    if (error != null) {
      final loc = AppLocalizations.of(context);
      final theme = Theme.of(context);
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  loc.splashStartupError,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _retrying ? null : _checkOnboarding,
                  icon: const Icon(Icons.refresh),
                  label: Text(loc.splashRetry),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
