import 'package:flutter/material.dart';

/// VidSnap brand colors — single source of truth.
/// See brand identity section in the project plan.
class VidSnapColors {
  VidSnapColors._();

  // Dark theme
  static const Color bgDark = Color(0xFF0E0F13);
  static const Color surfaceDark = Color(0xFF1A1C22);

  // Light theme
  static const Color bgLight = Color(0xFFF7F8FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);

  // Shared
  static const Color accent = Color(0xFF4D7CFE);
  static const Color success = Color(0xFF2ECC71);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);

  // Text
  static const Color textOnDark = Color(0xFFF5F6FA);
  static const Color textOnLight = Color(0xFF1A1A1A);
  static const Color muted = Color(0xFF9498A3);

  // Gradients
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4D7CFE), Color(0xFF6E5BFF)],
  );
}

 ThemeData buildDarkTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: VidSnapColors.bgDark,
    colorScheme: base.colorScheme.copyWith(
      primary: VidSnapColors.accent,
      secondary: VidSnapColors.accent,
      surface: VidSnapColors.surfaceDark,
      error: VidSnapColors.error,
      onPrimary: Colors.white,
      onSurface: VidSnapColors.textOnDark,
    ),
    cardColor: VidSnapColors.surfaceDark,
    dividerColor: Colors.white12,
    appBarTheme: const AppBarTheme(
      backgroundColor: VidSnapColors.bgDark,
      foregroundColor: VidSnapColors.textOnDark,
      elevation: 0,
      centerTitle: false,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: VidSnapColors.surfaceDark,
      modalBackgroundColor: VidSnapColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: VidSnapColors.accent,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: _inputDecoration(VidSnapColors.surfaceDark, VidSnapColors.textOnDark),
    textButtonTheme: textButtonTheme(VidSnapColors.accent),
    filledButtonTheme: filledButtonTheme(VidSnapColors.accent),
    extensions: [
      VidSnapColorsExtension(
        background: VidSnapColors.bgDark,
        surface: VidSnapColors.surfaceDark,
        text: VidSnapColors.textOnDark,
        muted: VidSnapColors.muted,
        accent: VidSnapColors.accent,
        success: VidSnapColors.success,
        error: VidSnapColors.error,
      ),
    ],
  );
}

ThemeData buildLightTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: VidSnapColors.bgLight,
    colorScheme: base.colorScheme.copyWith(
      primary: VidSnapColors.accent,
      secondary: VidSnapColors.accent,
      surface: VidSnapColors.surfaceLight,
      error: VidSnapColors.error,
      onPrimary: Colors.white,
      onSurface: VidSnapColors.textOnLight,
    ),
    cardColor: VidSnapColors.surfaceLight,
    dividerColor: Colors.black12,
    appBarTheme: const AppBarTheme(
      backgroundColor: VidSnapColors.bgLight,
      foregroundColor: VidSnapColors.textOnLight,
      elevation: 0,
      centerTitle: false,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: VidSnapColors.surfaceLight,
      modalBackgroundColor: VidSnapColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: VidSnapColors.accent,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: _inputDecoration(VidSnapColors.surfaceLight, VidSnapColors.textOnLight),
    textButtonTheme: textButtonTheme(VidSnapColors.accent),
    filledButtonTheme: filledButtonTheme(VidSnapColors.accent),
    extensions: [
      VidSnapColorsExtension(
        background: VidSnapColors.bgLight,
        surface: VidSnapColors.surfaceLight,
        text: VidSnapColors.textOnLight,
        muted: VidSnapColors.muted,
        accent: VidSnapColors.accent,
        success: VidSnapColors.success,
        error: VidSnapColors.error,
      ),
    ],
  );
}

InputDecorationTheme _inputDecoration(Color surface, Color text) => InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: VidSnapColors.accent, width: 1.5),
      ),
      labelStyle: TextStyle(color: VidSnapColors.muted),
      hintStyle: TextStyle(color: VidSnapColors.muted),
    );

TextButtonThemeData textButtonTheme(Color accent) => TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accent,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );

FilledButtonThemeData filledButtonTheme(Color accent) => FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );

/// Custom theme extension so any widget can access semantic colors
/// without depending on dark/light branching.
class VidSnapColorsExtension extends ThemeExtension<VidSnapColorsExtension> {
  const VidSnapColorsExtension({
    required this.background,
    required this.surface,
    required this.text,
    required this.muted,
    required this.accent,
    required this.success,
    required this.error,
    this.warning = const Color(0xFFF39C12),
  });

  final Color background;
  final Color surface;
  final Color text;
  final Color muted;
  final Color accent;
  final Color success;
  final Color error;
  final Color warning;

  static VidSnapColorsExtension of(BuildContext context) =>
      Theme.of(context).extension<VidSnapColorsExtension>()!;

  @override
  VidSnapColorsExtension copyWith({
    Color? background,
    Color? surface,
    Color? text,
    Color? muted,
    Color? accent,
    Color? success,
    Color? error,
    Color? warning,
  }) =>
      VidSnapColorsExtension(
        background: background ?? this.background,
        surface: surface ?? this.surface,
        text: text ?? this.text,
        muted: muted ?? this.muted,
        accent: accent ?? this.accent,
        success: success ?? this.success,
        error: error ?? this.error,
        warning: warning ?? this.warning,
      );

  @override
  VidSnapColorsExtension lerp(VidSnapColorsExtension? other, double t) {
    if (other == null) return this;
    return VidSnapColorsExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}
