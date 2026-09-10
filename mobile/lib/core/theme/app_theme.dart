import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors matching the website
  static const Color bgColor = Color(0xFF0B0F19);
  static const Color primary = Color(0xFFF7931A); // Bitcoin Orange
  static const Color primaryHover = Color(0xFFE07F0F);
  static const Color accent = Color(0xFF38BDF8); // Cyan
  static const Color textColor = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);

  // Card base color (we use opacity over this)
  static const Color cardBase = Color(0xFF1E293B);

  // ── Light theme palette (S5) ──
  // // PERCHÉ: stessi brand colors, sfondi chiari slate; il primary resta
  // l'orange Bitcoin su entrambi i temi.
  static const Color lightBgColor = Color(0xFFF8FAFC);
  static const Color lightCardBase = Color(0xFFFFFFFF);
  static const Color lightTextColor = Color(0xFF0F172A);
  static const Color lightTextMuted = Color(0xFF64748B);
  static const Color lightAccent =
      Color(0xFF0284C7); // cyan scuro per AA su chiaro

  static ThemeData get darkTheme {
    final baseTheme = ThemeData.dark();
    // PERCHÉ (P2.2): font Outfit locale (variabile, bundlato) — niente fetch
    // runtime da Google Fonts, niente FOUT/blocco render/richieste CSP.
    final outfitTextTheme = baseTheme.textTheme.apply(fontFamily: 'Outfit');

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: bgColor,
        secondary: accent,
        onSecondary: bgColor,
        surface: bgColor,
        onSurface: textColor,
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      textTheme: outfitTextTheme.copyWith(
        displayLarge: outfitTextTheme.displayLarge
            ?.copyWith(color: textColor, fontWeight: FontWeight.w800),
        displayMedium: outfitTextTheme.displayMedium
            ?.copyWith(color: textColor, fontWeight: FontWeight.bold),
        displaySmall: outfitTextTheme.displaySmall
            ?.copyWith(color: textColor, fontWeight: FontWeight.bold),
        headlineLarge: outfitTextTheme.headlineLarge
            ?.copyWith(color: textColor, fontWeight: FontWeight.bold),
        headlineMedium: outfitTextTheme.headlineMedium
            ?.copyWith(color: textColor, fontWeight: FontWeight.bold),
        headlineSmall: outfitTextTheme.headlineSmall
            ?.copyWith(color: textColor, fontWeight: FontWeight.w600),
        titleLarge: outfitTextTheme.titleLarge
            ?.copyWith(color: textColor, fontWeight: FontWeight.w600),
        titleMedium: outfitTextTheme.titleMedium?.copyWith(color: textColor),
        titleSmall: outfitTextTheme.titleSmall?.copyWith(color: textColor),
        bodyLarge: outfitTextTheme.bodyLarge?.copyWith(color: textColor),
        bodyMedium: outfitTextTheme.bodyMedium?.copyWith(color: textColor),
        bodySmall: outfitTextTheme.bodySmall?.copyWith(color: textMuted),
        labelLarge: outfitTextTheme.labelLarge
            ?.copyWith(color: textColor, fontWeight: FontWeight.bold),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primary),
        titleTextStyle: TextStyle(
          color: primary,
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: bgColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          elevation: 4,
          shadowColor: primary.withValues(alpha: 0.25),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: bgColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: const BorderSide(color: Colors.white24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBase.withValues(alpha: 0.4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF1E293B),
        contentTextStyle: TextStyle(color: textColor, fontFamily: 'Outfit'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Tema chiaro (S5): stessi brand colors su sfondo slate chiaro.
  /// // PERCHÉ: contrasti verificati per WCAG AA — testo slate-900 su
  /// sfondo slate-50, accent cyan scuro per il testo secondario.
  static ThemeData get lightTheme {
    final baseTheme = ThemeData.light();
    final outfitTextTheme = baseTheme.textTheme.apply(fontFamily: 'Outfit');

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        secondary: lightAccent,
        onSecondary: Colors.white,
        surface: lightBgColor,
        onSurface: lightTextColor,
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      textTheme: outfitTextTheme.copyWith(
        displayLarge: outfitTextTheme.displayLarge
            ?.copyWith(color: lightTextColor, fontWeight: FontWeight.w800),
        displayMedium: outfitTextTheme.displayMedium
            ?.copyWith(color: lightTextColor, fontWeight: FontWeight.bold),
        displaySmall: outfitTextTheme.displaySmall
            ?.copyWith(color: lightTextColor, fontWeight: FontWeight.bold),
        headlineLarge: outfitTextTheme.headlineLarge
            ?.copyWith(color: lightTextColor, fontWeight: FontWeight.bold),
        headlineMedium: outfitTextTheme.headlineMedium
            ?.copyWith(color: lightTextColor, fontWeight: FontWeight.bold),
        headlineSmall: outfitTextTheme.headlineSmall
            ?.copyWith(color: lightTextColor, fontWeight: FontWeight.w600),
        titleLarge: outfitTextTheme.titleLarge
            ?.copyWith(color: lightTextColor, fontWeight: FontWeight.w600),
        titleMedium:
            outfitTextTheme.titleMedium?.copyWith(color: lightTextColor),
        titleSmall: outfitTextTheme.titleSmall?.copyWith(color: lightTextColor),
        bodyLarge: outfitTextTheme.bodyLarge?.copyWith(color: lightTextColor),
        bodyMedium: outfitTextTheme.bodyMedium?.copyWith(color: lightTextColor),
        bodySmall: outfitTextTheme.bodySmall?.copyWith(color: lightTextMuted),
        labelLarge: outfitTextTheme.labelLarge
            ?.copyWith(color: lightTextColor, fontWeight: FontWeight.bold),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primary),
        titleTextStyle: TextStyle(
          color: primary,
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          elevation: 2,
          shadowColor: primary.withValues(alpha: 0.25),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightTextColor,
          side: const BorderSide(color: Colors.black26),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightAccent,
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      cardTheme: CardThemeData(
        color: lightCardBase.withValues(alpha: 0.85),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF1E293B),
        contentTextStyle: TextStyle(color: textColor, fontFamily: 'Outfit'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
