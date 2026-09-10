import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 20.0,
    this.borderColor,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    // Su Web, il BackdropFilter con CanvasKit è estremamente costoso.
    // Usiamo uno sfondo semi-trasparente più opaco per simulare l'effetto
    // glass senza il costo del blur in tempo reale.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseCard = isDark ? AppTheme.cardBase : AppTheme.lightCardBase;
    final effectiveBg =
        backgroundColor ?? baseCard.withValues(alpha: kIsWeb ? 0.75 : 0.4);

    final container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBg,
        border: Border.all(
          color: borderColor ??
              (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05)),
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: child,
    );

    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: kIsWeb
            ? container
            : BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: container,
              ),
      ),
    );
  }
}
