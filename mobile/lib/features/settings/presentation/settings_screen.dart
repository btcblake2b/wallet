import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_lock_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/explorer_mirrors.dart';
import '../../../core/services/fiat_currency.dart';
import '../../../core/services/fiat_price.dart';
import '../../../core/services/fx_rates.dart';
import '../../../core/services/info_hints.dart';
import '../../../core/services/locale_provider.dart';
import '../../../core/services/theme_provider.dart';
import '../../../core/services/wallet_repository.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/web_vault_notice.dart';
import '../../../l10n/app_localizations.dart';
import '../../explorer/presentation/explorer_screen.dart';
import '../../guide/presentation/guide_screen.dart';
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
    this.hideExplorerMirrors = kIsWeb,
  });

  final ThemeProvider? themeProvider;
  final LocaleProvider localeProvider;
  final AppLockService appLockService;
  final BiometricService biometricService;
  final WalletRepository walletRepository;

  /// True = l'interruttore dei mirror Esplora non viene mostrato.
  /// PERCHÉ (web): dal browser il primario `mempool.guide` è CORS-bloccato,
  /// quindi i mirror sono l'unica via di rete (vedi
  /// `ExplorerMirrors.webMirrorsRequired`) e una preferenza OFF non avrebbe
  /// senso: mostrarla permetterebbe di lasciare l'app senza rete e senza
  /// rimedio dalla UI. Parametro iniettabile perché nei test `kIsWeb` è false.
  final bool hideExplorerMirrors;

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

  /// Riga informativa sul cambio in uso (es. `1 USDT = 0.89619 EUR`).
  String _fxRateLabel() {
    final currency = FiatPrice.instance.currency;
    final rate = FxRates.instance.microRateFor(currency);
    if (rate == null) return '—';
    return '1 USDT = ${formatFxRate(rate)} ${currency.code}';
  }

  /// Prezzo di 1 XBT nella valuta scelta, già formattato.
  ///
  /// // PERCHÉ il fallback in USD: se il cambio della valuta non è ancora
  /// // arrivato (prima apertura offline) si mostra il prezzo base USDT, non un
  /// // importo convertito con un cambio inventato.
  String _pricePerXbtLabel() {
    final cents = FiatPrice.instance.centsFor(FiatPrice.satsPerXbt);
    if (cents != null) {
      return formatMoney(cents, FiatPrice.instance.currency);
    }
    return formatMoney(
      FiatPrice.instance.usdCentsPerXbt!,
      FiatCurrency.usd,
    );
  }

  /// Sceglie la valuta del controvalore (USD, EUR, GBP, CHF, JPY, CAD).
  ///
  /// // PERCHÉ il refresh del cambio qui: senza un cambio USDT→valuta non
  /// // esiste un controvalore corretto; se Coinbase non risponde e non c'è un
  /// // cambio salvato, la scelta non viene applicata e l'utente lo vede.
  Future<void> _pickCurrency() async {
    final loc = AppLocalizations.of(context);
    final current = FiatPrice.instance.currency;
    final picked = await showModalBottomSheet<FiatCurrency>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    color: Theme.of(ctx).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    loc.fiatPriceCurrency,
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
                children: FiatCurrency.values.map((currency) {
                  final selected = currency == current;
                  return ListTile(
                    leading: Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: selected
                          ? Theme.of(ctx).colorScheme.primary
                          : Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
                    title: Text(currency.code),
                    trailing: Text(
                      currency.symbol,
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                    onTap: () => Navigator.of(ctx).pop(currency),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null || picked == current || !mounted) return;

    // PERCHÉ si scarica il cambio PRIMA di applicare la scelta: mostrare un
    // controvalore in euro senza il cambio USDT/EUR vorrebbe dire inventarlo.
    if (picked != FiatCurrency.usd) {
      final ok = await FxRates.instance.refresh();
      if (!mounted) return;
      if (!ok && !FxRates.instance.hasRate(picked)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.fiatPriceFxFailed)),
        );
        return;
      }
    }
    await FiatPrice.instance.setCurrency(picked);
  }

  /// Mostra/nasconde il controvalore (leva 5).
  Future<void> _toggleFiatPrice(bool value) async {
    await FiatPrice.instance.setEnabled(value);
  }

  /// Attiva/disattiva la lettura automatica del prezzo da NeoXEX.
  ///
  /// // PERCHÉ: all'accensione si fa subito un fetch on-demand — se riesce,
  /// // il prezzo compare senza che l'utente debba aprirlo a mano; se
  /// // Coinbase/NeoXEX non rispondono (offline, piazza giù) il toggle resta
  /// // attivo e il prossimo refresh riproverà.
  Future<void> _toggleFiatPriceAuto(bool value) async {
    await FiatPrice.instance.setAuto(value);
    if (!value) return;
    final ok = await FiatPrice.instance.refreshFromNeoxex();
    // PERCHÉ anche il cambio: con una valuta diversa da USD il controvalore
    // resta assente finché non c'è il cambio USDT→valuta.
    if (FiatPrice.instance.currency != FiatCurrency.usd) {
      await FxRates.instance.refresh();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? AppLocalizations.of(context).fiatPriceAutoUpdated
              : AppLocalizations.of(context).fiatPriceAutoFailed,
        ),
      ),
    );
  }

  /// Chiede il prezzo in dollari per 1 XBT e lo salva in CENTESIMI interi.
  ///
  /// // PERCHÉ dialog dedicato e non inline: il TextEditingController deve
  /// // essere smaltito SOLO quando il dialog è stato smontato (dispose() dello
  /// // State), non subito dopo `await showDialog` — altrimenti il TextField
  /// // ancora montato durante l'animazione di chiusura scatena l'assert
  /// // "_dependents.isEmpty" (lezione 2026-09-06, vedi _RenameUtxoDialog).
  Future<void> _editFiatPrice() async {
    final loc = AppLocalizations.of(context);
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => _FiatPriceDialog(loc: loc),
    );
    if (value == null || !mounted) return;
    // PERCHÉ parsing a mano in centesimi: `(v * 100).round()` su double sbaglia
    // di un centesimo per certi valori (es. 1.15). Si separano interi e
    // decimali dalla stringa.
    final cents = parseUsdToCents(value);
    await FiatPrice.instance.setUsdCentsPerXbt(cents);
    if (!mounted) return;
    if (cents == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.fiatPriceInvalid)),
      );
    }
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
        appBar: AppBar(
          title: Text(loc.settingsTitle),
          // PERCHÉ (26/10): la guida per principianti deve essere raggiungibile
          // anche senza scorrere fino a "Informazioni" — l'icona non sposta il
          // contenuto della lista (i test contano sull'ordine dei primi tile).
          actions: [
            IconButton(
              tooltip: loc.guideTitle,
              icon: const Icon(Icons.help_outline),
              onPressed: () => _push(const GuideScreen()),
            ),
          ],
        ),
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
            // PERCHÉ (leva 5): il prezzo cambia da un dialog → la riga di
            // stato e lo switch devono aggiornarsi senza riaprire la pagina.
            FiatPrice.instance,
            // PERCHÉ (29/10): la valuta del controvalore e il cambio USDT
            // cambiano lo switch e la riga informativa senza riaprire la pagina.
            FxRates.instance,
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
                // PERCHÉ (26/10): avviso sulla superficie web — prima di
                // mettere fondi veri l'utente deve sapere che sul browser le
                // chiavi vivono in localStorage e che un XSS mentre il vault è
                // sbloccato le legge. Fuori dal web il widget è invisibile.
                const WebVaultNotice(),
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
                  // PERCHÉ (leva 5, 27/10): il controvalore si basa su un
                  // prezzo che imposta l'utente. Nessuna chiamata a terzi:
                  // la voce è qui perché è una preferenza di VISUALIZZAZIONE.
                  SwitchListTile(
                    secondary: const Icon(Icons.attach_money),
                    title: Text(loc.fiatPriceShow),
                    subtitle: Text(
                      FiatPrice.instance.usdCentsPerXbt == null
                          ? loc.fiatPriceNotSet
                          : loc.fiatPriceCurrent(_pricePerXbtLabel()),
                    ),
                    value: FiatPrice.instance.enabled,
                    onChanged: FiatPrice.instance.usdCentsPerXbt == null
                        ? null
                        : _toggleFiatPrice,
                  ),
                  // PERCHÉ (29/10): NeoXEX è l'unica piazza XBT con API
                  // pubblica (verificata: neoxa.exchange). L'auto è un toggle
                  // separato: legge il prezzo on-demand, non accende da sola
                  // il controvalore e non fa polling.
                  SwitchListTile(
                    secondary: const Icon(Icons.sync_outlined),
                    title: Text(loc.fiatPriceAuto),
                    subtitle: Text(loc.fiatPriceAutoDesc),
                    value: FiatPrice.instance.auto,
                    onChanged: _toggleFiatPriceAuto,
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(loc.fiatPriceSet),
                    subtitle: Text(loc.fiatPriceSetDesc),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _editFiatPrice,
                  ),
                  // PERCHÉ (29/10): il prezzo è quotato in USDT; la valuta
                  // scelta converte il controvalore col cambio reale USDT→EUR
                  // (& co.). Compare sempre: è la valuta delle cifre mostrate.
                  ListTile(
                    leading: const Icon(Icons.payments_outlined),
                    title: Text(loc.fiatPriceCurrency),
                    subtitle: Text(
                      FiatPrice.instance.currency == FiatCurrency.usd
                          ? loc.fiatPriceCurrencyDesc
                          : '${loc.fiatPriceCurrencyDesc} · '
                              '${_fxRateLabel()}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${FiatPrice.instance.currency.code} '
                          '${FiatPrice.instance.currency.symbol}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: _pickCurrency,
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
                  // PERCHÉ: su web l'interruttore è nascosto — la voce resta
                  // solo dove la scelta è realmente applicabile (mobile).
                  if (!widget.hideExplorerMirrors)
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
                    leading: const Icon(Icons.school_outlined),
                    title: Text(loc.guideTitle),
                    subtitle: Text(loc.guideEntryDesc),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _push(const GuideScreen()),
                  ),
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

/// Dialog di impostazione del prezzo XBT con ciclo di vita del controller
/// corretto.
///
/// // PERCHÉ (29/10): il vecchio dialog inline faceva `dispose()` del
/// // TextEditingController subito dopo `await showDialog` — ma il dialog si
/// // smonta in modo asincrono e il TextField ancora montato durante
/// // l'animazione di chiusura scatenava "used after being disposed" +
/// // "_dependents.isEmpty" (stessa lezione di _RenameUtxoDialog, 2026-09-06).
/// // Qui il controller vive nello State e viene smaltito in `dispose()`.
/// // Inoltre il contenuto è in uno scroll view: su schermi piccoli il testo
/// // + il campo superavano di ~0.2px lo spazio del dialog (RenderFlex
/// // overflow, 29/10).
class _FiatPriceDialog extends StatefulWidget {
  const _FiatPriceDialog({required this.loc});

  final AppLocalizations loc;

  @override
  State<_FiatPriceDialog> createState() => _FiatPriceDialogState();
}

class _FiatPriceDialogState extends State<_FiatPriceDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final current = FiatPrice.instance.usdCentsPerXbt;
    _controller = TextEditingController(
      text: current == null ? '' : (current / 100).toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;
    return AlertDialog(
      title: Text(loc.fiatPriceSet),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.fiatPriceDialogBody,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: loc.fiatPriceFieldLabel,
                suffixText: 'USD',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.passwordDialogCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(loc.fiatPriceSave),
        ),
      ],
    );
  }
}
