import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A widget that provides the glowing background effects, matching the website.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        // // PERCHÉ (S5): sfondo tema-aware (scuro originale / chiaro slate).
        Container(
          color: isDark ? const Color(0xFF0B0F19) : AppTheme.lightBgColor,
        ),
        // Top right orange glow
        Positioned(
          top: -200,
          right: -100,
          child: _GlowCircle(
            size: 600,
            color: scheme.primary,
            opacity: isDark ? 0.08 : 0.06,
          ),
        ),
        // Bottom left cyan glow (usa bottom: 0 per evitare MediaQuery)
        Positioned(
          bottom: 0,
          left: -200,
          child: _GlowCircle(
            size: 500,
            color: scheme.secondary,
            opacity: isDark ? 0.05 : 0.04,
          ),
        ),
        // The main content
        child,
      ],
    );
  }
}

/// Glow circle decorativo con `RepaintBoundary` per isolare il painting.
class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              Colors.transparent,
            ],
            stops: const [0.0, 0.7],
          ),
        ),
      ),
    );
  }
}
