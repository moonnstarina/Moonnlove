import 'package:flutter/material.dart';

class AppPalette {
  static Color background = const Color(0xFFF8F9FA);
  static Color primary = const Color(0xFF964549);
  static Color primaryContainer = const Color(0xFFFF999C);
  static Color onPrimaryContainer = const Color(0xFF792E33);
  static Color onPrimary = const Color(0xFFFFFFFF);
  static Color onSurface = const Color(0xFF191C1D);
  static Color onSurfaceVariant = const Color(0xFF544242);
  static Color onSecondaryContainer = const Color(0xFF6F6161);
  static Color surfaceLowest = const Color(0xFFFFFFFF);
  static Color surfaceContainerLowest = const Color(0xFFFFFFFF);
  static Color surfaceContainer = const Color(0xFFEDEEEF);
  static Color surfaceContainerLow = const Color(0xFFF3F4F5);
  static Color surfaceContainerHigh = const Color(0xFFE7E8E9);
  static Color surfaceContainerHighest = const Color(0xFFE1E3E4);
  static Color surfaceVariant = const Color(0xFFE1E3E4);
  static Color outlineVariant = const Color(0xFFDAC1C0);
  static Color outline = const Color(0xFF877272);
  static Color secondary = const Color(0xFF695B5B);
  static Color secondaryContainer = const Color(0xFFF1DEDE);
  static Color secondaryFixed = const Color(0xFFF1DEDE);
  static Color tertiary = const Color(0xFF6E595A);
  static Color tertiaryContainer = const Color(0xFFCAAFAF);
  static Color tertiaryFixed = const Color(0xFFF9DCDC);
  static Color onTertiaryFixed = const Color(0xFF271818);
  static Color onTertiaryFixedVariant = const Color(0xFF554242);
  static Color inverseSurface = const Color(0xFF2E3132);
  static Color inverseOnSurface = const Color(0xFFF0F1F2);
  static Color inversePrimary = const Color(0xFFFFB3B4);
  static Color primaryFixed = const Color(0xFFFFDAD9);
  static Color error = const Color(0xFFBA1A1A);
  static Color errorContainer = const Color(0xFFFFDAD6);

  static bool isDark = false;

  static Color get shadow => isDark ? const Color(0x33000000) : const Color(0x0A000000);
  static Color get cardShadow => isDark ? const Color(0x44000000) : const Color(0x0A000000);
  static Color get divider => isDark ? const Color(0x22FFFFFF) : const Color(0x11000000);
  static Color get shimmer => isDark ? const Color(0x0DFFFFFF) : const Color(0x0D000000);
  static Color get onlineGreen => const Color(0xFF4CAF50);
  static Color get offlineGrey => const Color(0xFF9E9E9E);
  static Color get gradientStart => isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFFFFFF);
  static Color get gradientEnd => isDark ? const Color(0xFF16213E) : const Color(0xFFFFF5F5);
  static Color get chipBg => isDark ? const Color(0xFF2A2040) : const Color(0xFFF1DEDE);
  static Color get inputBg => isDark ? const Color(0xFF1E1E2E) : const Color(0xFFFFFFFF);
  static Color get overlayBg => isDark ? const Color(0x88000000) : const Color(0x26000000);

  static void update(Color seed, {Brightness brightness = Brightness.light}) {
    final s = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    isDark = brightness == Brightness.dark;
    background = s.surface;
    primary = s.primary;
    primaryContainer = s.primaryContainer;
    onPrimaryContainer = s.onPrimaryContainer;
    onPrimary = s.onPrimary;
    onSurface = s.onSurface;
    onSurfaceVariant = s.onSurfaceVariant;
    onSecondaryContainer = s.onSecondaryContainer;
    surfaceLowest = s.surfaceContainerLowest;
    surfaceContainerLowest = s.surfaceContainerLowest;
    surfaceContainer = s.surfaceContainer;
    surfaceContainerLow = s.surfaceContainerLow;
    surfaceContainerHigh = s.surfaceContainerHigh;
    surfaceContainerHighest = s.surfaceContainerHighest;
    surfaceVariant = s.surfaceContainerHighest;
    outlineVariant = s.outlineVariant;
    outline = s.outline;
    secondary = s.secondary;
    secondaryContainer = s.secondaryContainer;
    secondaryFixed = s.secondaryFixed;
    tertiary = s.tertiary;
    tertiaryContainer = s.tertiaryContainer;
    tertiaryFixed = s.tertiaryFixed;
    onTertiaryFixed = s.onTertiaryFixed;
    onTertiaryFixedVariant = s.onTertiaryFixedVariant;
    inverseSurface = s.inverseSurface;
    inverseOnSurface = s.onInverseSurface;
    inversePrimary = s.inversePrimary;
    primaryFixed = s.primaryFixed;
    error = s.error;
    errorContainer = s.errorContainer;
  }
}
