// FLOW: Invio BTC — scansione indirizzo QR destinatario
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/config/bitcoin_network_config.dart';
import '../../../core/widgets/app_background.dart';
import '../../../l10n/app_localizations.dart';

/// Schermata di scansione QR per il campo destinatario (SendScreen).
/// PERCHÉ: prima il pulsante "scanner" incollava dagli appunti — ingannevole.
/// Ora apre la fotocamera reale (mobile_scanner) e ritorna l'indirizzo.
class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final MobileScannerController _controller = MobileScannerController(
    // PERCHÉ: interessa solo QR; evita di processare barcode 1D non rilevanti.
    formats: const [BarcodeFormat.qrCode],
  );
  bool _handled = false;
  Timer? _invalidDebounce;

  @override
  void dispose() {
    _invalidDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;

    String? invalid;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw == null || raw.isEmpty) continue;
      if (BitcoinNetworkConfig.isValidAddress(raw)) {
        _handled = true;
        _invalidDebounce?.cancel();
        Navigator.of(context).pop(raw);
        return;
      }
      invalid = raw;
    }

    // PERCHÉ: il QR scansionato non è un indirizzo BTC valido: avvisa ma
    // resta in scansione (debounce per non mostrare snackbar a raffica).
    if (invalid != null) {
      _invalidDebounce?.cancel();
      _invalidDebounce = Timer(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.scanQrInvalid)),
        );
      });
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
    } catch (e) {
      // PERCHÉ: su dispositivi senza torcia (o web) il toggle fallisce
      // silenziosamente — non deve bloccare la scansione.
      debugPrint('[ScanQrScreen] Torch toggle failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return AppBackground(
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.scanQrTitle),
          actions: [
            // PERCHÉ: il controller è un ValueNotifier<MobileScannerState> in
            // mobile_scanner 7.x; lo stato torcia vive in value.torchState.
            ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, state, _) {
                return IconButton(
                  tooltip: loc.scanQrTorch,
                  icon: Icon(
                    state.torchState == TorchState.on
                        ? Icons.flash_on
                        : Icons.flash_off,
                  ),
                  onPressed: _toggleTorch,
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) {
                // PERCHÉ: permesso negato o camera non disponibile → messaggio
                // chiaro con pulsante di chiusura.
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.no_photography_outlined,
                          size: 48,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loc.scanQrError,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          label: Text(loc.passwordDialogCancel),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Overlay guida: cornice centrata (non intercetta il touch).
            IgnorePointer(
              child: Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.9),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
