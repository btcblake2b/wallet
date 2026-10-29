import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/config/bitcoin_network_config.dart';
import '../../../core/models/send_output.dart';
import '../../../core/models/wallet_record.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/bitcoin_service.dart';
import '../../../core/services/psbt/psbt_wallet_service.dart';
import '../../../core/services/wallet_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/password_dialog.dart';
import '../../../l10n/app_localizations.dart';
import 'psbt_qr_screen.dart';
import 'scan_qr_screen.dart';

const int _kDustLimitSats = SendOutput.dustLimitSats;

/// Crea una PSBT da firmare su un altro dispositivo (P4/I2, 26/10).
///
/// // PERCHÉ esiste: un wallet **watch-only** non ha chiavi, quindi oggi può
/// // solo guardare. Qui costruisce la spesa (stessa economia di SendScreen,
/// // via [PsbtWalletService]) e la esporta in QR animato: si firma sul
/// // telefono che possiede il seed — anche un'altra istanza di questa app.
///
/// // PERCHÉ non è una modalità di `SendScreen`: quel file gestisce auth,
/// // conferma, RBF e coin control del percorso che trasmette davvero. Una
/// // seconda modalità lì dentro avrebbe due significati per gli stessi
/// // pulsanti; qui il flusso è esplicito e isolato.
class PsbtSpendScreen extends StatefulWidget {
  const PsbtSpendScreen({
    super.key,
    required this.wallet,
    required this.utxos,
    required this.bitcoinService,
    required this.walletRepository,
    required this.biometricService,
    this.psbtService,
  });

  final WalletRecord wallet;

  /// UTXO spendibili già letti dallo snapshot del wallet detail.
  final List<UtxoInfo> utxos;

  final BitcoinService bitcoinService;
  final WalletRepository walletRepository;
  final BiometricService biometricService;

  /// Iniettabile nei test; default costruito sul servizio Bitcoin.
  final PsbtWalletService? psbtService;

  @override
  State<PsbtSpendScreen> createState() => _PsbtSpendScreenState();
}

class _PsbtSpendScreenState extends State<PsbtSpendScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  late final PsbtWalletService _psbtService = widget.psbtService ??
      PsbtWalletService(bitcoinService: widget.bitcoinService);

  FeeEstimates? _feeEstimates;
  int _tier = 1; // 0 = low, 1 = normal, 2 = high
  bool _creating = false;

  bool get _isWatchOnly => widget.wallet.kind == WalletKind.watchOnly;

  int get _availableSats =>
      widget.utxos.fold<int>(0, (sum, u) => sum + u.valueSat);

  int get _feeRateSatVb {
    final fees = _feeEstimates;
    if (fees == null) return BitcoinNetworkConfig.fallbackFeeEstimates.normal;
    switch (_tier) {
      case 0:
        return fees.lowSatVb;
      case 2:
        return fees.highSatVb;
      default:
        return fees.normalSatVb;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFees());
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFees() async {
    try {
      final fees = await widget.bitcoinService.fetchFeeEstimates();
      if (!mounted) return;
      setState(() => _feeEstimates = fees);
    } catch (e) {
      // // PERCHÉ: senza stime si usa il fallback di rete — la PSBT resta
      // // costruibile, l'utente non resta bloccato da un'API lenta.
      debugPrint('[LoopEngineer] fee estimates non lette: $e');
    }
  }

  String _formatBtc(int sats) =>
      '${(sats / 100000000).toStringAsFixed(8)} ${BitcoinNetworkConfig.ticker}';

  int? _parseSats(String text) {
    final normalized = text.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    final btc = double.tryParse(normalized);
    if (btc == null || btc <= 0) return null;
    return (btc * 100000000).round();
  }

  String? _validateAddress(String? value) {
    final loc = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) {
      return loc.sendScreenValidateAddress;
    }
    final address = value.trim();
    if (!BitcoinNetworkConfig.isValidAddress(address)) {
      return loc.sendScreenValidateInvalidAddress(
        BitcoinNetworkConfig.networkName,
        BitcoinNetworkConfig.addressPrefixDescription,
      );
    }
    if (address == widget.wallet.publicAddress) {
      return loc.sendScreenValidateSelf;
    }
    return null;
  }

  String? _validateAmount(String? value) {
    final loc = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) {
      return loc.sendScreenValidateAmount;
    }
    final sats = _parseSats(value);
    if (sats == null) return loc.sendScreenValidateInvalidAmount;
    if (sats < _kDustLimitSats) {
      return loc.sendScreenValidateDust(
        _kDustLimitSats,
        _formatBtc(_kDustLimitSats),
      );
    }
    if (sats >= _availableSats) {
      return loc.sendScreenValidateInsufficient(
        _formatBtc(_availableSats),
        0,
      );
    }
    return null;
  }

  Future<void> _scanAddress() async {
    final loc = AppLocalizations.of(context);
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanQrScreen()),
    );
    if (result == null || !mounted) return;
    final candidate = result.trim();
    if (BitcoinNetworkConfig.isValidAddress(candidate)) {
      _addressCtrl.text = candidate;
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.scanQrInvalid)),
      );
    }
  }

  /// Autenticazione per un'azione che tocca il denaro (stessa regola di
  /// `SendScreen._authorizeSpending`).
  Future<bool> _authorize() async {
    final loc = AppLocalizations.of(context);
    if (kIsWeb) {
      final entered = await PasswordDialog.showEnterPasswordDialog(
        context,
        reason: loc.sendScreenPasswordReason,
      );
      if (!mounted || entered == null || entered.isEmpty) return false;
      final ok = await widget.biometricService.verifyPassword(entered);
      if (ok) await widget.walletRepository.unlockWebStorage(entered);
      return ok;
    }
    final available = await widget.biometricService.canAuthenticate();
    if (!mounted) return false;
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.sendScreenBiometricRequired)),
      );
      return false;
    }
    return widget.biometricService.authenticateForSensitiveAction(
      reason: loc.sendScreenBiometricReason,
    );
  }

  Future<void> _create() async {
    final loc = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final sats = _parseSats(_amountCtrl.text);
    if (sats == null) return;

    setState(() => _creating = true);
    try {
      // // PERCHÉ il seed solo per l'hot: il watch-only deriva dallo xpub e non
      // // deve autenticare nulla per creare una PSBT che non può firmare.
      String? mnemonic;
      if (!_isWatchOnly) {
        if (!await _authorize()) return;
        if (!mounted) return;
        mnemonic = await widget.walletRepository.decryptSeed(widget.wallet);
      }
      if (!mounted) return;

      final draft = await _psbtService.createForWallet(
        wallet: widget.wallet,
        utxos: widget.utxos,
        outputs: <SendOutput>[
          SendOutput(address: _addressCtrl.text.trim(), amountSats: sats),
        ],
        feeRateSatVb: _feeRateSatVb,
        mnemonic: mnemonic,
      );
      if (!mounted) return;
      setState(() => _creating = false);

      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            loc.psbtDraftReady('${draft.feeSats}', '${draft.changeSats}'),
          ),
        ),
      );
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PsbtQrScreen(
            psbtBase64: draft.psbtBase64,
            footer: loc.psbtDraftReady(
              '${draft.feeSats}',
              '${draft.changeSats}',
            ),
          ),
        ),
      );
    } on StateError catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('$e');
    } finally {
      if (mounted) setState(() => _creating = false);
      // PERCHÉ (R1): la PSBT è costruita (o l'errore già mostrato): le chiavi
      // non servono più a questa schermata.
      await widget.walletRepository.forgetWebKeysNow();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _creating = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AppBackground(
      accent: AppTheme.lightningAccent,
      child: Scaffold(
        appBar: AppBar(title: Text(loc.psbtSpendTitle)),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(14),
                child: Text(
                  loc.psbtSpendIntro,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressCtrl,
                decoration: InputDecoration(
                  labelText: loc.sendScreenAddressLabel,
                  suffixIcon: IconButton(
                    tooltip: loc.psbtScan,
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: _scanAddress,
                  ),
                ),
                validator: _validateAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: loc.sendScreenAmountLabel,
                  helperText: loc.sendScreenBalance(
                    _formatBtc(_availableSats),
                    BitcoinNetworkConfig.ticker,
                  ),
                ),
                validator: _validateAmount,
              ),
              const SizedBox(height: 20),
              Text(loc.sendScreenFeeLabel, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: [
                  ButtonSegment(value: 0, label: Text(loc.sendScreenFeeLow)),
                  ButtonSegment(value: 1, label: Text(loc.sendScreenFeeNormal)),
                  ButtonSegment(value: 2, label: Text(loc.sendScreenFeeHigh)),
                ],
                selected: {_tier},
                onSelectionChanged: (selection) =>
                    setState(() => _tier = selection.first),
              ),
              const SizedBox(height: 8),
              Text(
                '$_feeRateSatVb sat/vB',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _creating ? null : _create,
                icon: const Icon(Icons.qr_code_2, size: 18),
                label: Text(_creating ? loc.psbtCreating : loc.psbtCreate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
