import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/models/wallet_record.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/bitcoin_service.dart';
import '../../../core/services/psbt/psbt_service.dart';
import '../../../core/services/psbt/psbt_wallet_service.dart';
import '../../../core/services/wallet_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/password_dialog.dart';
import '../../../l10n/app_localizations.dart';
import 'psbt_qr_screen.dart';
import 'psbt_scan_screen.dart';

/// Firma una PSBT arrivata da un altro dispositivo (P4/I3, 26/10).
///
/// // PERCHÉ: è il lato "che ha il seed". Mostra SEMPRE il riepilogo
/// // (input, destinatari, fee) prima della firma: firmare una PSBT senza
/// // vedere cosa paga sarebbe una firma alla cieca.
class PsbtSignScreen extends StatefulWidget {
  const PsbtSignScreen({
    super.key,
    required this.wallet,
    required this.walletRepository,
    required this.biometricService,
    required this.bitcoinService,
    this.psbtService,
  });

  final WalletRecord wallet;
  final WalletRepository walletRepository;
  final BiometricService biometricService;
  final BitcoinService bitcoinService;
  final PsbtWalletService? psbtService;

  @override
  State<PsbtSignScreen> createState() => _PsbtSignScreenState();
}

class _PsbtSignScreenState extends State<PsbtSignScreen> {
  final _ctrl = TextEditingController();

  late final PsbtWalletService _psbtService = widget.psbtService ??
      PsbtWalletService(bitcoinService: widget.bitcoinService);

  PsbtSummary? _summary;
  String? _error;
  bool _signing = false;

  bool get _isWatchOnly => widget.wallet.kind == WalletKind.watchOnly;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Rilegge la PSBT incollata e ne calcola il riepilogo.
  void _parse() {
    final raw = _ctrl.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _summary = null;
        _error = null;
      });
      return;
    }
    final loc = AppLocalizations.of(context);
    try {
      final summary = summarizePsbt(raw);
      setState(() {
        _summary = summary;
        _error = null;
      });
      debugPrint(
        '[LoopEngineer] PSBT riepilogo: input=${summary.totalInputs} '
        'output=${summary.outputs.length} fee=${summary.feeSats}',
      );
    } catch (e) {
      // // PERCHÉ: qualunque PSBT malformata deve dire "non valida" invece di
      // // far esplodere la schermata: il testo può arrivare da un incolla.
      setState(() {
        _summary = null;
        _error = loc.psbtInvalid;
      });
    }
  }

  Future<void> _scan() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const PsbtScanScreen()),
    );
    if (result == null || !mounted) return;
    _ctrl.text = result;
    _parse();
  }

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

  Future<void> _sign() async {
    final loc = AppLocalizations.of(context);
    final summary = _summary;
    if (summary == null) return;
    if (_isWatchOnly) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.psbtNeedsSeed)),
      );
      return;
    }
    if (!await _authorize()) return;
    if (!mounted) return;

    setState(() => _signing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final mnemonic = await widget.walletRepository.decryptSeed(
        widget.wallet,
      );
      if (!mounted) return;
      final signed = await _psbtService.signForWallet(
        wallet: widget.wallet,
        psbtBase64: _ctrl.text.trim(),
        mnemonic: mnemonic,
      );
      if (!mounted) return;
      setState(() => _signing = false);
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PsbtQrScreen(
            psbtBase64: signed,
            title: loc.psbtSignedTitle,
            footer: loc.psbtReviewFee('${summary.feeSats}'),
            // // PERCHÉ si trasmette da qui: è l'unico dispositivo che ha
            // // firmato; i registri pending/RBF restano vuoti perché la
            // // suddivisione destinatari/resto è del wallet che l'ha creata.
            onBroadcast: () async {
              final result = await _psbtService.broadcastSignedOnly(
                signedPsbtBase64: signed,
              );
              return result.txid;
            },
          ),
        ),
      );
    } on StateError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _signing = false);
      // PERCHÉ (R1): la firma è fatta; le chiavi non devono restare in RAM
      // mentre l'utente mostra/trasmette la PSBT.
      await widget.walletRepository.forgetWebKeysNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final summary = _summary;
    return AppBackground(
      accent: AppTheme.lightningAccent,
      child: Scaffold(
        appBar: AppBar(title: Text(loc.psbtSignTitle)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassContainer(
              padding: const EdgeInsets.all(14),
              child: Text(loc.psbtSignIntro, style: theme.textTheme.bodySmall),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              minLines: 3,
              maxLines: 6,
              onChanged: (_) => _parse(),
              decoration: InputDecoration(
                labelText: loc.psbtPasteLabel,
                suffixIcon: IconButton(
                  tooltip: loc.psbtScan,
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _scan,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ],
            if (summary != null) ...[
              const SizedBox(height: 16),
              GlassContainer(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.psbtReviewTitle,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    for (final output in summary.outputs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${output.address ?? "—"} · '
                          '${(output.amount.toInt() / 100000000).toStringAsFixed(8)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      loc.psbtReviewInputs('${summary.totalInputs}'),
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      loc.psbtReviewOutputs('${summary.outputs.length}'),
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      loc.psbtReviewFee('${summary.feeSats}'),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _signing ? null : _sign,
                icon: const Icon(Icons.draw, size: 18),
                label: Text(_signing ? loc.psbtSigning : loc.psbtSign),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
