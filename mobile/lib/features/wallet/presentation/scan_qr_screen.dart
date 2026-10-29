// FLOW: Invio BTC — scansione indirizzo QR destinatario
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/config/bitcoin_network_config.dart';
import '../../../core/utils/lightning_invoice_utils.dart';
import '../../../core/utils/mnemonic_utils.dart';
import '../../../core/widgets/app_background.dart';
import '../../../l10n/app_localizations.dart';

/// Cosa si cerca nel QR: decide la validazione e il messaggio d'errore.
enum ScanQrMode {
  /// Indirizzo Bitcoin on-chain (`bc1…`, `1…`, `3…`).
  bitcoinAddress,

  /// Invoice Lightning BOLT11 (`lnbc…`).
  lightningInvoice,

  /// Frase mnemonica BIP39 (12/15/18/21/24 parole) — usata dall'import wallet
  /// per leggere il QR di backup della seed di un altro wallet.
  mnemonic,
}

/// Schermata di scansione QR per il campo destinatario (SendScreen), per
/// l'invoice Lightning (LightningSendScreen) o per la seed phrase (import
/// wallet).
/// PERCHÉ: prima il pulsante "scanner" incollava dagli appunti — ingannevole.
/// Ora apre la fotocamera reale (mobile_scanner) e ritorna il contenuto.
class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key, this.mode = ScanQrMode.bitcoinAddress});

  /// Modalità di scansione. Default indirizzo BTC: retrocompatibile con
  /// l'invio on-chain che non passa nulla.
  final ScanQrMode mode;

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
      final value = _validatedValue(raw);
      if (value != null) {
        _handled = true;
        _invalidDebounce?.cancel();
        Navigator.of(context).pop(value);
        return;
      }
      invalid = raw;
    }

    // PERCHÉ: il QR scansionato non è valido per la modalità corrente:
    // avvisa ma resta in scansione (debounce per non mostrare snackbar a
    // raffica).
    if (invalid != null) {
      _invalidDebounce?.cancel();
      _invalidDebounce = Timer(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_invalidMessage(loc))),
        );
      });
    }
  }

  /// Valore da consegnare a chi ha aperto lo scanner, già normalizzato.
  /// `null` = il QR non è valido per [ScanQrScreen.mode].
  String? _validatedValue(String raw) {
    switch (widget.mode) {
      case ScanQrMode.bitcoinAddress:
        return BitcoinNetworkConfig.isValidAddress(raw) ? raw : null;
      case ScanQrMode.lightningInvoice:
        // PERCHÉ: in modalità invoice ripulisco l'URI `lightning:` così il
        // campo riceve la stringa BOLT11 pura da pagare.
        return isValidLightningInvoice(raw)
            ? normalizeLightningInvoice(raw)
            : null;
      case ScanQrMode.mnemonic:
        // PERCHÉ: la seed letta dal QR va normalizzata (spazi/a-capo) prima
        // del checksum BIP39; il campo di import riceve la frase pulita.
        return isValidMnemonic(raw) ? normalizeMnemonic(raw) : null;
    }
  }

  String _invalidMessage(AppLocalizations loc) {
    switch (widget.mode) {
      case ScanQrMode.bitcoinAddress:
        return loc.scanQrInvalid;
      case ScanQrMode.lightningInvoice:
        return loc.scanQrInvalidInvoice;
      case ScanQrMode.mnemonic:
        return loc.scanQrInvalidMnemonic;
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
