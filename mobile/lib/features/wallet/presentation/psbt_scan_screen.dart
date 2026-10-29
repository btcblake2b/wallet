import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/services/psbt/psbt_qr.dart';
import '../../../core/widgets/app_background.dart';
import '../../../l10n/app_localizations.dart';

/// Scansione di una PSBT che arriva come **QR animato** (più frame).
///
/// // PERCHÉ una schermata dedicata (P4, 26/10): `ScanQrScreen` chiude al primo
/// // QR valido, mentre qui bisogna restare in scansione finché tutti i frame
/// // dell'insieme sono stati letti. Toccare la stessa schermata avrebbe
/// // significato riscrivere la logica di un flusso già collaudato.
class PsbtScanScreen extends StatefulWidget {
  const PsbtScanScreen({super.key});

  @override
  State<PsbtScanScreen> createState() => _PsbtScanScreenState();
}

class _PsbtScanScreenState extends State<PsbtScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  final PsbtFrameAssembler _assembler = PsbtFrameAssembler();
  String? _lastFrame;
  bool _done = false;
  Timer? _hintDebounce;

  @override
  void dispose() {
    _hintDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw == null || raw.isEmpty) continue;
      if (raw == _lastFrame) continue;
      _lastFrame = raw;

      // PERCHÉ il fallback: una PSBT abbastanza piccola entra in un QR singolo
      // (o arriva incollata): riconoscerla evita di obbligare l'utente a
      // usare il formato a frame quando non serve.
      if (!isPsbtFrame(raw) && raw.startsWith('cHNidP')) {
        _finish(raw);
        return;
      }

      final complete = _assembler.add(raw);
      if (!mounted) return;
      setState(() {});
      if (complete != null) {
        _finish(complete);
        return;
      }
      if (!isPsbtFrame(raw)) {
        _showHint();
      }
    }
  }

  void _finish(String psbtBase64) {
    _done = true;
    debugPrint('[LoopEngineer] PSBT letta: ${psbtBase64.length} caratteri');
    Navigator.of(context).pop(psbtBase64);
  }

  void _showHint() {
    _hintDebounce?.cancel();
    _hintDebounce = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.psbtNoFrames)),
      );
    });
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
    } catch (e) {
      debugPrint('[PsbtScanScreen] torcia non disponibile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final total = _assembler.total;
    return AppBackground(
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.psbtScan),
          actions: [
            ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, state, _) => IconButton(
                tooltip: loc.scanQrTorch,
                icon: Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                ),
                onPressed: _toggleTorch,
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) => Center(
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
              ),
            ),
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
            // PERCHÉ il contatore: con i frame animati l'utente deve sapere se
            // la scansione sta avanzando invece di restare ferma.
            if (total != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      loc.psbtScanProgress(
                        '${_assembler.received}',
                        '$total',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
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
