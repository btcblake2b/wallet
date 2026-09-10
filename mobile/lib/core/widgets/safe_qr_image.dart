import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

/// Widget per visualizzare un QR code che **non usa `CustomPaint`**,
/// evitando il bug di layout `semantics.parentDataDirty` / `hasSize`
/// che affligge `qr_flutter` su dispositivi Xiaomi/Poco.
///
/// Genera il QR code come immagine PNG raster via `PictureRecorder` e
/// lo mostra con `Image.memory`, bypassando completamente `CustomPaint`.
class SafeQrImage extends StatefulWidget {
  const SafeQrImage({
    super.key,
    required this.data,
    this.size = 200.0,
    this.backgroundColor = Colors.white,
    this.borderRadius = BorderRadius.zero,
    this.padding = const EdgeInsets.all(8),
  });

  final String data;
  final double size;
  final Color backgroundColor;
  final BorderRadius borderRadius;
  final EdgeInsets padding;

  @override
  State<SafeQrImage> createState() => _SafeQrImageState();
}

class _SafeQrImageState extends State<SafeQrImage> {
  Uint8List? _pngBytes;
  String? _lastData;
  double? _lastSize;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  void didUpdateWidget(covariant SafeQrImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data || oldWidget.size != widget.size) {
      _generate();
    }
  }

  void _generate() {
    if (_lastData == widget.data && _lastSize == widget.size) return;
    _lastData = widget.data;
    _lastSize = widget.size;
    _generateAsync();
  }

  Future<void> _generateAsync() async {
    try {
      final bytes = await _renderQrToPng(
        widget.data,
        widget.size.toInt(),
      );
      if (!mounted) return;
      setState(() => _pngBytes = bytes);
    } catch (e) {
      debugPrint('SafeQrImage: errore generazione QR: $e');
    }
  }

  /// Renderizza un QR code in un buffer PNG disegnando i moduli
  /// direttamente su un [Canvas] tramite [PictureRecorder].
  /// NON usa `CustomPaint`, evitando il bug di layout Xiaomi.
  Future<Uint8List> _renderQrToPng(String data, int sizePx) async {
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.L,
    );
    final qrImage = QrImage(qrCode);

    final moduleCount = qrImage.moduleCount;
    const quietZone = 4; // moduli bianchi attorno al QR (standard)
    final totalModules = moduleCount + quietZone * 2;
    final moduleSize = sizePx / totalModules;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Sfondo bianco
    canvas.drawRect(
      Rect.fromLTWH(0, 0, sizePx.toDouble(), sizePx.toDouble()),
      Paint()..color = const Color(0xFFFFFFFF),
    );

    // Disegna i moduli neri del QR
    final blackPaint = Paint()..color = const Color(0xFF000000);
    for (var row = 0; row < moduleCount; row++) {
      for (var col = 0; col < moduleCount; col++) {
        if (qrImage.isDark(row, col)) {
          final x = (quietZone + col) * moduleSize;
          final y = (quietZone + row) * moduleSize;
          canvas.drawRect(
            Rect.fromLTWH(x, y, moduleSize, moduleSize),
            blackPaint,
          );
        }
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(sizePx, sizePx);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: widget.borderRadius,
      ),
      child: _pngBytes != null
          ? Image.memory(
              _pngBytes!,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
              gaplessPlayback: true,
            )
          : SizedBox(
              width: widget.size,
              height: widget.size,
              child: const Center(child: CircularProgressIndicator()),
            ),
    );
  }
}
