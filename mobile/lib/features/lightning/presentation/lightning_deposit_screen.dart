import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/lightning_node_address.dart';
import '../../../core/services/lightning/lightning_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/safe_qr_image.dart';
import '../../../l10n/app_localizations.dart';

/// Deposito on-chain sul nodo Lightning: indirizzo + QR + copia.
///
/// // FLOW: Gestione nodo Lightning — deposito on-chain
/// STEP 1: make_new_address → indirizzo fresco dal nodo
/// STEP 2: l'utente invia fondi on-chain blake2b a quell'indirizzo
class LightningDepositScreen extends StatefulWidget {
  const LightningDepositScreen({super.key, required this.lightningService});

  final LightningService lightningService;

  @override
  State<LightningDepositScreen> createState() => _LightningDepositScreenState();
}

class _LightningDepositScreenState extends State<LightningDepositScreen> {
  LightningNodeAddress? _address;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // PERCHÉ: la chiamata di rete parte dopo il primo frame (convenzione
    // del progetto: niente lavoro async che tocca setState in initState).
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // FLOW: STEP 1
      final address = await widget.lightningService.makeNewAddress();
      if (!mounted) return;
      setState(() => _address = address);
      debugPrint('[LoopEngineer] deposit: nuovo indirizzo del nodo pronto');
    } on LightningException catch (e) {
      if (!mounted) return;
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.isPermissionDenied
                ? loc.lightningErrorRestricted
                : loc.lightningErrorGeneric(e.message),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copy() async {
    final address = _address;
    if (address == null) return;
    await Clipboard.setData(ClipboardData(text: address.address));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).lightningCopied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final address = _address;
    return AppBackground(
      accent: AppTheme.lightningAccent,
      child: Scaffold(
        appBar: AppBar(title: Text(loc.lightningDepositTitle)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(loc.lightningDepositHint),
                  const SizedBox(height: 16),
                  if (_loading && address == null)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    )
                  else if (address != null) ...[
                    // PERCHÉ: SafeQrImage evita il bug di layout di
                    // CustomPaint su alcuni device (vedi doc del widget).
                    SafeQrImage(data: address.address, size: 220),
                    const SizedBox(height: 16),
                    SelectableText(
                      address.address,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _copy,
                      icon: const Icon(Icons.copy, size: 18),
                      label: Text(loc.lightningCopied),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _loading ? null : _load,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(loc.lightningDepositNewAddress),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              loc.lightningDepositWarning,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.orangeAccent),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
