import 'dart:async';

import 'package:flutter/material.dart';

import 'safe_qr_image.dart';

/// Mostra una sequenza di frame QR a rotazione (PSBT in più pezzi).
///
/// // PERCHÉ (P4, 26/10): una PSBT non entra in un QR singolo leggibile. Il
/// // widget cicla i frame sul posto — chi firma inquadra e aspetta, senza
/// // dover toccare nulla; il contatore dice a che punto è la scansione.
///
/// // PERCHÉ `SafeQrImage`: `qr_flutter` ha un bug di layout noto su alcuni
/// // dispositivi (Xiaomi/Poco) e questo progetto lo evita già ovunque.
class AnimatedQr extends StatefulWidget {
  const AnimatedQr({
    super.key,
    required this.frames,
    this.size = 260,
    this.interval = const Duration(milliseconds: 320),
    this.showCounter = true,
  });

  /// Frame da mostrare in sequenza (vedi `psbt_qr.dart`). Se è uno solo, il
  /// widget resta statico.
  final List<String> frames;

  final double size;
  final Duration interval;

  /// Mostra "2/5" sotto il QR (utile quando i frame sono più di uno).
  final bool showCounter;

  @override
  State<AnimatedQr> createState() => _AnimatedQrState();
}

class _AnimatedQrState extends State<AnimatedQr> {
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant AnimatedQr oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frames.length != widget.frames.length ||
        oldWidget.interval != widget.interval) {
      _index = 0;
      _syncTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _syncTimer() {
    _timer?.cancel();
    if (widget.frames.length <= 1) return;
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % widget.frames.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final frames = widget.frames;
    if (frames.isEmpty) return const SizedBox.shrink();
    final frame = frames[_index.clamp(0, frames.length - 1)];
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SafeQrImage(data: frame, size: widget.size),
        if (widget.showCounter && frames.length > 1) ...[
          const SizedBox(height: 6),
          Text(
            '${_index + 1} / ${frames.length}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
