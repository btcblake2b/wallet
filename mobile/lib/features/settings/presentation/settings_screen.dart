import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_lock_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/explorer_mirrors.dart';
import '../../../core/services/info_hints.dart';
import '../../../core/services/locale_provider.dart';
import '../../../core/services/theme_provider.dart';
import '../../../core/services/wallet_repository.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../l10n/app_localizations.dart';
import '../../explorer/presentation/explorer_screen.dart';
import '../../lock/app_lock_flow.dart';
import '../../wallet/presentation/legal_info_screen.dart';
import 'about_screen.dart';

/// Pagina Impostazioni: raccoglie le voci prima nel menu overflow della home
/// (lingua, tema, legali, explorer, about) + il nuovo blocco app.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.themeProvider,
    required this.localeProvider,
    required this.appLockService,
    required this.biometricService,
    required this.walletRepository,
  });

  final ThemeProvider? themeProvider;
  final LocaleProvider localeProvider;
  final AppLockService appLockService;
  final BiometricService biometricService;
  final WalletRepository walletRepository;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// null = verifica in corso; false → blocco app non attivabile.
  bool? _biometricAvailable;
  bool _lockBusy = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    if (kIsWeb) {
      if (mounted) setState(() => _biometricAvailable = false);
      return;
    }
    final available = await widget.biometricService.hasEnrolledBiometrics();
    if (!mounted) return;
    setState(() => _biometricAvailable = available);
  }

  void _push(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  Future<void> _toggleAppLock(bool value) async {
    final loc = AppLocalizations.of(context);
    if (!value) {
      await widget.appLockService.setEnabled(value: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.settingsAppLockDisabled)),
      );
      return;
    }
    setState(() => _lockBusy = true);
    final ok = await AppLockFlow.enable(
      biometricService: widget.biometricService,
      appLockService: widget.appLockService,
      loc: loc,
    );
    if (!mounted) return;
    setState(() => _lockBusy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? loc.settingsAppLockEnabled : loc.settingsAppLockEnableFailed,
        ),
      ),
    );
  }

  /// Hardening 2.4: blocco manuale del vault web (voce spostata dalla home).
  Future<void> _lockWebVault() async {
    await widget.walletRepository.lockWebStorage();
    widget.biometricService.lockCache();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).homeVaultLocked)),
    );
    Navigator.of(context).pop();
  }

  /// Selettore lingua (bottom sheet con spunta sulla lingua attiva).
  void _showLanguagePicker() {
    final loc = AppLocalizations.of(context);
    final current = widget.localeProvider.languageCode;

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final autoMode = widget.localeProvider.isAutoMode;
        final entries = <String, String>{
          'auto': loc.languageSelectorAuto,
          'it': loc.languageSelectorIt,
          'en': loc.languageSelectorEn,
          'de': loc.languageSelectorDe,
          'fi': loc.languageSelectorFi,
          'es': loc.languageSelectorEs,
          'zh': loc.languageSelectorZhCN,
          'fr': loc.languageSelectorFrCA,
        };
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.language,
                      color: Theme.of(ctx).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      loc.languageSelector,
                      style: Theme.of(ctx)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: entries.entries.map((entry) {
                    final selected = entry.key == 'auto'
                        ? autoMode
                        : !autoMode && current == entry.key;
                    return ListTile(
                      leading: Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: selected
                            ? Theme.of(ctx).colorScheme.primary
                            : Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                      title: Text(entry.value),
                      onTap: () {
                        if (entry.key == 'auto') {
                          widget.localeProvider.useSystemLocale();
                        } else {
                          widget.localeProvider.setLocale(Locale(entry.key));
                        }
                        Navigator.of(ctx).pop();
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  /// Attiva/disattiva il fallback sui mirror Esplora comunitari.
  /// PERCHÉ: OFF = una sola fonte (mempool.guide) per letture e broadcast —
  /// nessun dato dell'utente inviato ai mirror.
  Future<void> _toggleExplorerMirrors(bool value) async {
    await ExplorerMirrors.instance.setEnabled(value);
  }

  /// Mostra/nasconde i pallini "info" in tutta l'app.
  /// PERCHÉ: preferenza di processo → il merge di Listenable in build
  /// ricostruisce la pagina, e ogni InfoDot ascolta la stessa istanza.
  Future<void> _toggleInfoHints(bool value) async {
    await InfoHints.instance.setEnabled(value);
  }

  Widget _sectionCard(List<Widget> tiles) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 4),
      // PERCHÉ: Material trasparente tra la card (DecoratedBox con background)
      // e i ListTile — senza, Flutter avverte che gli ink splash non sono
      // visibili (e i test widget trattano l'avviso come errore).
      child: Material(
        type: MaterialType.transparency,
        child: Column(children: tiles),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AppBackground(
      child: Scaffold(
        appBar: AppBar(title: Text(loc.settingsTitle)),
        body: ListenableBuilder(
          listenable: Listenable.merge([
            widget.appLockService,
            widget.localeProvider,
            widget.themeProvider,
            // PERCHÉ: lo switch dei mirror vive in un registro di processo:
            // l'UI si aggiorna notificando l'istanza.
            ExplorerMirrors.instance,
            // PERCHÉ (pallini info): il toggle è un ChangeNotifier di processo;
            // ListenableBuilder ricostruisce la pagina e ogni InfoDot ascolta
            // la stessa istanza → nasconde i pallini anche nelle schermate
            // GIÀ montate.
            InfoHints.instance,
          ]),
          builder: (context, _) {
            final themeProvider = widget.themeProvider;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Sicurezza ──
                _sectionTitle(loc.settingsSectionSecurity),
                _sectionCard([
                  if (!kIsWeb)
                    SwitchListTile(
                      secondary: const Icon(Icons.lock_outline),
                      title: Text(loc.settingsAppLock),
                      subtitle: Text(
                        _biometricAvailable == false
                            ? loc.settingsAppLockUnavailable
                            : loc.settingsAppLockDesc,
                      ),
                      value: widget.appLockService.isEnabled,
                      onChanged: (_biometricAvailable == true && !_lockBusy)
                          ? _toggleAppLock
                          : null,
                    ),
                  if (kIsWeb)
                    ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: Text(loc.homeLockVault),
                      onTap: _lockWebVault,
                    ),
                ]),
                // ── Aspetto ──
                _sectionTitle(loc.settingsSectionAppearance),
                _sectionCard([
                  if (themeProvider != null)
                    SwitchListTile(
                      secondary: const Icon(Icons.dark_mode_outlined),
                      title: Text(loc.settingsTheme),
                      value: themeProvider.isDark,
                      onChanged: (_) => themeProvider.toggle(),
                    ),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(loc.languageSelector),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showLanguagePicker,
                  ),
                ]),
                // ── Interfaccia ──
                _sectionTitle(loc.settingsSectionInterface),
                _sectionCard([
                  SwitchListTile(
                    secondary: const Icon(Icons.info_outline),
                    title: Text(loc.settingsInfoDots),
                    subtitle: Text(loc.settingsInfoDotsDesc),
                    value: InfoHints.instance.enabled,
                    onChanged: _toggleInfoHints,
                  ),
                ]),
                // ── Strumenti ──
                _sectionTitle(loc.settingsSectionTools),
                _sectionCard([
                  ListTile(
                    leading: const Icon(Icons.travel_explore),
                    title: Text(loc.explorerTitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _push(const ExplorerScreen()),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.hub_outlined),
                    title: Text(loc.settingsExplorerMirrors),
                    subtitle: Text(loc.settingsExplorerMirrorsDesc),
                    value: ExplorerMirrors.instance.enabled,
                    onChanged: _toggleExplorerMirrors,
                  ),
                ]),
                // ── Informazioni ──
                _sectionTitle(loc.settingsSectionInfo),
                _sectionCard([
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(loc.legalInfoTitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _push(const LegalInfoScreen()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: Text(loc.aboutTitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _push(const AboutScreen()),
                  ),
                ]),
              ],
            );
          },
        ),
      ),
    );
  }
}
