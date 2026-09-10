import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/models/wallet_record.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/security_service.dart';
import '../../../core/services/wallet_repository.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/password_dialog.dart';
import '../../../l10n/app_localizations.dart';
import 'widgets/seed_phrase_verifier.dart';

enum _BackupStep { intro, seed, verify, done }

/// Wizard di backup proattivo della seed phrase.
///
/// // PERCHÉ (S3): dopo la creazione/import il backup va guidato SUBITO,
/// non lasciato "a richiesta" nel dettaglio wallet. Flusso:
/// intro → autenticazione (biometria/password) → mostra seed → verifica 3
/// parole → confirmSeedBackup. Skip consentito ma con warning esplicito.
class BackupSeedScreen extends StatefulWidget {
  const BackupSeedScreen({
    super.key,
    required this.wallet,
    required this.walletRepository,
    required this.biometricService,
    this.random,
  });

  final WalletRecord wallet;
  final WalletRepository walletRepository;
  final BiometricService biometricService;

  /// Random iniettabile per test deterministici della verifica.
  final Random? random;

  @override
  State<BackupSeedScreen> createState() => _BackupSeedScreenState();
}

class _BackupSeedScreenState extends State<BackupSeedScreen> {
  _BackupStep _step = _BackupStep.intro;
  String? _seed;
  bool _checkingAuth = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    SecurityService().protectScreen(true);
  }

  @override
  void dispose() {
    SecurityService().protectScreen(false);
    super.dispose();
  }

  /// Autenticazione per vedere la seed (pattern identico a wallet_detail):
  /// biometria su nativo, password su web.
  Future<bool> _authenticate() async {
    final loc = AppLocalizations.of(context);
    if (kIsWeb) {
      final has = await widget.biometricService.canAuthenticate();
      if (!mounted) return false;
      if (!has) {
        final pw = await PasswordDialog.showCreatePasswordDialog(context);
        if (pw == null) return false;
        await widget.biometricService.setPassword(pw);
        await widget.walletRepository.enablePasswordProtection(pw);
      }
      if (!mounted) return false;
      final entered = await PasswordDialog.showEnterPasswordDialog(
        context,
        reason: loc.walletDetailPasswordSeedReason,
      );
      if (!mounted || entered == null) return false;
      final ok = await widget.biometricService.verifyPassword(entered);
      if (ok) {
        await widget.walletRepository.unlockWebStorage(entered);
        await widget.walletRepository.enablePasswordProtection(entered);
      }
      return ok;
    }
    return widget.biometricService.authenticateForSensitiveAction(
      reason: loc.walletDetailBiometricSeedReason,
    );
  }

  Future<void> _startBackup() async {
    setState(() => _checkingAuth = true);
    final ok = await _authenticate();
    if (!mounted) return;
    if (!ok) {
      setState(() => _checkingAuth = false);
      return;
    }
    final seed = await widget.walletRepository.decryptSeed(widget.wallet);
    if (!mounted) return;
    setState(() {
      _seed = seed;
      _checkingAuth = false;
      _step = _BackupStep.seed;
    });
  }

  void _goToVerify() {
    setState(() => _step = _BackupStep.verify);
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    await widget.walletRepository.confirmSeedBackup(widget.wallet);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AppBackground(
      child: Scaffold(
        appBar: AppBar(title: Text(loc.backupSeedTitle)),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: switch (_step) {
              _BackupStep.intro => _buildIntro(context, loc),
              _BackupStep.seed => _buildSeed(context, loc),
              _BackupStep.verify => _buildVerify(context, loc),
              _BackupStep.done => _buildDone(context, loc),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildIntro(BuildContext context, AppLocalizations loc) {
    final theme = Theme.of(context);
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 56,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            loc.backupSeedIntro,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
            ),
            child: Text(
              loc.backupSeedSkipWarning,
              style: const TextStyle(fontSize: 12, color: Colors.orange),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _checkingAuth ? null : _startBackup,
            icon: _checkingAuth
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.lock_open),
            label: Text(loc.backupSeedStart),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.backupSeedLater),
          ),
        ],
      ),
    );
  }

  Widget _buildSeed(BuildContext context, AppLocalizations loc) {
    final theme = Theme.of(context);
    final words = (_seed ?? '').trim().split(RegExp(r'\s+'));
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.visibility, size: 40, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          // Griglia di 12 chip numerati per facilitare la lettura.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < words.length; i++)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${i + 1}. ${words[i]}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _goToVerify,
            icon: const Icon(Icons.check),
            label: Text(loc.backupSeedSavedContinue),
          ),
        ],
      ),
    );
  }

  Widget _buildVerify(BuildContext context, AppLocalizations loc) {
    final theme = Theme.of(context);
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            loc.backupSeedVerifyTitle,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            loc.backupSeedVerifyHint,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // PERCHÉ: verifica 3 parole estratta in SeedPhraseVerifier — stessa
          // UX, chiavi e algoritmo (compatibilità test/E2E esistenti).
          SeedPhraseVerifier(
            seed: _seed!,
            onVerified: () => setState(() => _step = _BackupStep.done),
            random: widget.random,
          ),
        ],
      ),
    );
  }

  Widget _buildDone(BuildContext context, AppLocalizations loc) {
    final theme = Theme.of(context);
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.check_circle, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            loc.backupSeedDone,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            loc.backupSeedDoneDesc,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _finish,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.done_all),
            label: Text(loc.backupSeedFinish),
          ),
        ],
      ),
    );
  }
}
