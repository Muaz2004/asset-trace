import 'package:flutter/material.dart';

/// Application theme definitions using the strict two-color institutional identity:
/// Primary Background: Deep Trust Navy (#0A192F)
/// Primary Accent: AAU Gold (#FFC107)
class AppTheme {
  AppTheme._();

  // Primary Brand Colors
  static const Color deepTrustNavy = Color(0xFF0A192F);
  static const Color aauGold = Color(0xFFFFC107);
  static const Color aauGoldDark = Color(0xFFFFA000);
  static const Color aauGoldLight = Color(0xFFFFD54F);

  // Navy Surface Hierarchy (Tonal Elevations)
  static const Color surfaceLowest = Color(0xFF060F1E);
  static const Color surface = Color(0xFF0A192F);
  static const Color surfaceLow = Color(0xFF0E1F38);
  static const Color surfaceMedium = Color(0xFF112240);
  static const Color surfaceHigh = Color(0xFF172A45);
  static const Color surfaceHighest = Color(0xFF233554);

  // High-Contrast Institutional Typography Colors
  static const Color textPrimary = Color(0xFFE6F1FF);
  static const Color textSecondary = Color(0xFF8892B0);
  static const Color textMuted = Color(0xFF64748B);

  // Borders & Accents
  static const Color borderNavy = Color(0xFF233554);
  static const Color borderVariant = Color(0xFF1D3557);
  static const Color borderGold = Color(0xFFFFC107);

  // Status & Security Flags (Restrained, high-contrast)
  static const Color statusWarning = Color(0xFFFF5252);
  static const Color statusWarningSurface = Color(0xFF2A1520);

  /// Central color scheme based on Deep Trust Navy & AAU Gold.
  static ColorScheme get colorScheme {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: aauGold,
      onPrimary: deepTrustNavy,
      primaryContainer: surfaceHigh,
      onPrimaryContainer: aauGold,
      secondary: aauGold,
      onSecondary: deepTrustNavy,
      secondaryContainer: surfaceMedium,
      onSecondaryContainer: textPrimary,
      tertiary: textSecondary,
      onTertiary: deepTrustNavy,
      error: statusWarning,
      onError: deepTrustNavy,
      surface: deepTrustNavy,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      surfaceContainerLowest: surfaceLowest,
      surfaceContainerLow: surfaceLow,
      surfaceContainer: surfaceMedium,
      surfaceContainerHigh: surfaceHigh,
      surfaceContainerHighest: surfaceHighest,
      outline: borderNavy,
      outlineVariant: borderVariant,
    );
  }

  /// Theme definition for the university application.
  static ThemeData get theme {
    final scheme = colorScheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: deepTrustNavy,
      canvasColor: surfaceMedium,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: deepTrustNavy,
        foregroundColor: textPrimary,
        iconTheme: IconThemeData(color: aauGold),
        actionsIconTheme: IconThemeData(color: aauGold),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceMedium,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderNavy, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: aauGold,
          foregroundColor: deepTrustNavy,
          disabledBackgroundColor: surfaceHighest,
          disabledForegroundColor: textMuted,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: aauGold,
          foregroundColor: deepTrustNavy,
          disabledBackgroundColor: surfaceHighest,
          disabledForegroundColor: textMuted,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: aauGold,
          side: const BorderSide(color: aauGold, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: aauGold,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: const TextStyle(color: textSecondary),
        floatingLabelStyle: const TextStyle(color: aauGold),
        hintStyle: const TextStyle(color: textMuted),
        prefixIconColor: aauGold,
        suffixIconColor: aauGold,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderNavy),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderNavy),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: aauGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: statusWarning),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: statusWarning, width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceMedium,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderNavy, width: 1),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: textSecondary,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceMedium,
        modalBackgroundColor: surfaceMedium,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          side: BorderSide(color: borderNavy, width: 1),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceMedium,
        contentTextStyle: const TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: aauGold, width: 1),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: aauGold,
        linearTrackColor: surfaceHighest,
        circularTrackColor: surfaceHighest,
      ),
      dividerTheme: const DividerThemeData(
        color: borderNavy,
        thickness: 1,
        space: 20,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLow,
        selectedColor: aauGold,
        secondarySelectedColor: aauGold,
        labelStyle: const TextStyle(color: textPrimary, fontSize: 13),
        secondaryLabelStyle: const TextStyle(color: deepTrustNavy, fontWeight: FontWeight.bold),
        checkmarkColor: deepTrustNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: borderNavy),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
    );
  }

  /// Compatibility alias for light theme.
  static ThemeData get lightTheme => theme;

  /// Compatibility alias for dark theme.
  static ThemeData get darkTheme => theme;
}
