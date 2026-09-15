import 'package:flutter/material.dart';
import 'package:bip39/bip39.dart' as bip39;
import '../../../core/config/bitcoin_network_config.dart';
import '../../../core/models/wallet_record.dart';
import '../../../core/services/security_service.dart';
import '../../../core/utils/connectivity.dart';
import '../../../core/services/wallet_repository.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../l10n/app_localizations.dart';

/// Lunghezze mnemoniche valide BIP39 (entropia 128-256 bit): 12/15/18/21/24
/// parole. PERCHÉ: il package bip39 1.0.6 accetta queste lunghezze (entropia
/// 16-32 byte) — il validator di import non deve restringere a 12.
const _kBip39WordCounts = <int>[12, 15, 18, 21, 24];

/// Modalità di import dello schermo.
/// PERCHÉ (P1 watch-only): seed phrase (wallet con chiavi) oppure xpub
/// (wallet di sola lettura, nessuna chiave privata).
enum _ImportMode { seed, watchOnly }

class ImportWalletScreen extends StatefulWidget {
  const ImportWalletScreen({
    super.key,
    required this.walletRepository,
  });

  final WalletRepository walletRepository;

  @override
  State<ImportWalletScreen> createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState extends State<ImportWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mnemonicController = TextEditingController();
  // PERCHÉ (P1 watch-only): il wallet watch-only si importa da xpub (chiave
  // pubblica estesa di account) — nessuna frase mnemonica.
  final _xpubController = TextEditingController();
  // PERCHÉ (BIP49): l'import può recuperare seed usati altrove su account
  // diversi (native BIP84 di default, nested BIP49 opzionale). La creazione
  // resta sempre BIP84 (non passa da qui).
  WalletScriptType _selectedType = WalletScriptType.p2wpkh;
  bool _importing = false;
  String? _errorMessage;
  // PERCHÉ (P1 watch-only): due modalità nello stesso schermo di import.
  _ImportMode _mode = _ImportMode.seed;

  @override
  void initState() {
    super.initState();
    // PERCHÉ (audit A7): la seed/xpub digitati a schermo non devono essere
    // catturabili da screenshot/screencast (no-op su web/debug).
    SecurityService().protectScreen(true);
  }

  @override
  void dispose() {
    SecurityService().protectScreen(false);
    _mnemonicController.dispose();
    _xpubController.dispose();
    super.dispose();
  }

  // Uses platform-specific implementation from `core/utils/connectivity.dart`.
  Future<bool> _hasInternet() async => hasInternet();

  Future<void> _importWallet() async {
    if (!_formKey.currentState!.validate()) return;

    if (!await _hasInternet()) {
      if (!mounted) return;
      final loc = AppLocalizations.of(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(loc.homeNoConnectionTitle),
          content: Text(loc.homeNoConnectionImport),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc.homeOk),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _importing = true;
      _errorMessage = null;
    });

    try {
      WalletRecord wallet;
      if (_mode == _ImportMode.watchOnly) {
        // PERCHÉ (P1): l'import watch-only non tocca MAI un seed — solo la
        // chiave pubblica estesa; la validazione profonda (rete, xprv) avviene
        // nel repository/servizio e i suoi errori finiscono in _errorMessage.
        wallet = await widget.walletRepository.importWatchOnly(
          accountXpub: _xpubController.text.trim(),
          scriptType: _selectedType,
        );
      } else {
        final mnemonic = _mnemonicController.text
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'\s+'), ' ');
        wallet = await widget.walletRepository.importWallet(
          mnemonic: mnemonic,
          derivationPath: _selectedType.accountPath(),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(wallet);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _importing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AppBackground(
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.importScreenTitle),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                _mode == _ImportMode.seed
                    ? loc.importScreenHeading
                    : loc.importModeWatchOnly,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _mode == _ImportMode.seed
                    ? loc.importScreenSubtitle
                    : loc.importWatchOnlySubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              // ── Modalità di import (P1 watch-only) ─────────────────
              SegmentedButton<_ImportMode>(
                segments: [
                  ButtonSegment(
                    value: _ImportMode.seed,
                    label: Text(loc.importModeSeed),
                  ),
                  ButtonSegment(
                    value: _ImportMode.watchOnly,
                    label: Text(loc.importModeWatchOnly),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) => setState(() {
                  _mode = selection.first;
                  _errorMessage = null;
                }),
              ),
              const SizedBox(height: 20),
              // ── Tipo di account (BIP49) ─────────────────────────────
              Text(
                loc.importScriptTypeLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<WalletScriptType>(
                segments: [
                  ButtonSegment(
                    value: WalletScriptType.p2wpkh,
                    label: Text(loc.importScriptTypeNativeSegwit),
                  ),
                  ButtonSegment(
                    value: WalletScriptType.p2shP2wpkh,
                    label: Text(loc.importScriptTypeNestedSegwit),
                  ),
                  ButtonSegment(
                    value: WalletScriptType.p2pkh,
                    label: Text(loc.importScriptTypeLegacy),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (selection) => setState(() {
                  _selectedType = selection.first;
                }),
              ),
              const SizedBox(height: 8),
              // PERCHÉ: guida sul prefisso atteso in base alla rete corrente.
              Text(
                loc.importScriptTypeHint(_selectedType.addressPrefix),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
              if (_mode == _ImportMode.seed) ...[
                TextFormField(
                  controller: _mnemonicController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: loc.importScreenHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerLow,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return loc.importScreenValidateEmpty;
                    }
                    final clean = value
                        .trim()
                        .toLowerCase()
                        .replaceAll(RegExp(r'\s+'), ' ');
                    final words = clean.split(' ');
                    // PERCHÉ: BIP39 standard ammette 12/15/18/21/24 parole;
                    // il vincolo "!= 12" scartava le seed da 15/18/21/24.
                    if (!_kBip39WordCounts.contains(words.length)) {
                      return loc.importScreenValidateCount(words.length);
                    }
                    if (!bip39.validateMnemonic(clean)) {
                      return loc.importScreenValidateInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  loc.importScreenHintText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ] else ...[
                TextFormField(
                  controller: _xpubController,
                  decoration: InputDecoration(
                    labelText: loc.importWatchOnlyXpubLabel,
                    hintText: loc.importWatchOnlyXpubHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerLow,
                  ),
                  // PERCHÉ (P1): check leggero sul prefisso in UI; la
                  // validazione profonda (parsing BIP32, rete, rifiuto xprv)
                  // avviene in importWatchOnly e l'errore compare sotto.
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return loc.importWatchOnlyValidateEmpty;
                    }
                    if (!value.trim().startsWith('xpub')) {
                      return loc.importWatchOnlyValidatePrefix;
                    }
                    return null;
                  },
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                GlassContainer(
                  backgroundColor:
                      theme.colorScheme.errorContainer.withValues(alpha: 0.8),
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _importing ? null : _importWallet,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _importing
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(loc.importScreenImport),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
