import 'package:flutter/material.dart';

/// Premium Calm — dekat dengan app perbankan / kesihatan moden, identiti Islam
/// yang halus. BUKAN klise app Islamik (SPEC 3.7).
abstract final class WarisColors {
  static const bgLight = Color(0xFFFAF9F6); // off-white suam
  static const bgDark = Color(0xFF12130F); // hampir hitam
  static const primary = Color(0xFF0F5132); // emerald pekat
  static const secondary = Color(0xFF8FA68E); // sage lembut
  static const highlight = Color(0xFFD4B896); // pasir suam
  static const danger = Color(0xFFA94442); // merah tenang
  static const success = Color(0xFF5A8A6B); // hijau lembut

  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF1C1E19);
}

abstract final class WarisRadius {
  static const card = 24.0; // 20–28px
  static const sheet = 28.0;
  static const chip = 16.0;
}

/// Tempoh animasi 200–300ms — memudahkan kefahaman, bukan hiasan (SPEC 3.7).
abstract final class WarisMotion {
  static const fast = Duration(milliseconds: 200);
  static const normal = Duration(milliseconds: 280);
}

ThemeData _base(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: WarisColors.primary,
    brightness: brightness,
  ).copyWith(
    primary: WarisColors.primary,
    secondary: WarisColors.secondary,
    tertiary: WarisColors.highlight,
    error: WarisColors.danger,
    surface: isDark ? WarisColors.surfaceDark : WarisColors.surfaceLight,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor:
        isDark ? WarisColors.bgDark : WarisColors.bgLight,
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WarisRadius.card),
      ),
      color: scheme.surface,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(WarisRadius.sheet),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52), // sasaran sentuh besar
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WarisRadius.chip),
        ),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
  );
}

ThemeData warisLightTheme() => _base(Brightness.light);

/// Mod gelap dari hari pertama — app dibuka dalam keadaan emosi berat, lewat
/// malam (SPEC 3.7).
ThemeData warisDarkTheme() => _base(Brightness.dark);
