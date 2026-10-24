import 'package:flutter/material.dart';

import '../core/chem/element.dart';

const _seed = Color(0xFF6A4CFF);

/// Bundled fallbacks for glyphs Nunito lacks (Greek, ⁺⁻, arrows …).
const fontFallback = ['NotoSansSymbols', 'NotoSansMath'];

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Nunito',
    fontFamilyFallback: fontFallback,
    brightness: brightness,
  );
  final radius = BorderRadius.circular(16);
  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      enabledBorder:
          OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 12),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surfaceContainer,
      indicatorColor: scheme.primaryContainer,
      selectedLabelTextStyle: TextStyle(
        fontFamily: 'Nunito',
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
      ),
      unselectedLabelTextStyle: TextStyle(
        fontFamily: 'Nunito',
        fontWeight: FontWeight.w600,
        color: scheme.onSurfaceVariant,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

/// Vivid accent colors used for tools and categories.
class Palette {
  static const violet = Color(0xFF7C4DFF);
  static const blue = Color(0xFF2979FF);
  static const cyan = Color(0xFF00B8D4);
  static const teal = Color(0xFF00BFA5);
  static const green = Color(0xFF43A047);
  static const lime = Color(0xFF9CCC65);
  static const amber = Color(0xFFFFB300);
  static const orange = Color(0xFFFF7043);
  static const red = Color(0xFFE53935);
  static const pink = Color(0xFFEC407A);
  static const indigo = Color(0xFF3D5AFE);
  static const brown = Color(0xFF8D6E63);
}

/// Background color for an element tile.
Color categoryColor(ElementCategory c, Brightness b) {
  final light = b == Brightness.light;
  return switch (c) {
    ElementCategory.alkaliMetal => light ? const Color(0xFFFF8A80) : const Color(0xFFB2443A),
    ElementCategory.alkalineEarthMetal => light ? const Color(0xFFFFCC80) : const Color(0xFFB0712A),
    ElementCategory.transitionMetal => light ? const Color(0xFFF8BBD0) : const Color(0xFF9C3D62),
    ElementCategory.postTransitionMetal => light ? const Color(0xFFB0BEC5) : const Color(0xFF4F6470),
    ElementCategory.metalloid => light ? const Color(0xFFC5E1A5) : const Color(0xFF5C7F35),
    ElementCategory.nonmetal => light ? const Color(0xFF80DEEA) : const Color(0xFF1F7C88),
    ElementCategory.halogen => light ? const Color(0xFFFFF59D) : const Color(0xFF8F8424),
    ElementCategory.nobleGas => light ? const Color(0xFFB39DDB) : const Color(0xFF5E45A0),
    ElementCategory.lanthanide => light ? const Color(0xFFA5D6A7) : const Color(0xFF3A7D3E),
    ElementCategory.actinide => light ? const Color(0xFF90CAF9) : const Color(0xFF2F6CA8),
    ElementCategory.unknown => light ? const Color(0xFFE0E0E0) : const Color(0xFF555555),
  };
}

Color onCategoryColor(Brightness b) =>
    b == Brightness.light ? const Color(0xFF1B1B1F) : Colors.white;

/// A pleasant two-stop gradient derived from [color].
LinearGradient accentGradient(Color color) {
  final hsl = HSLColor.fromColor(color);
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      color,
      hsl.withHue((hsl.hue + 28) % 360).withLightness((hsl.lightness * 0.85).clamp(0, 1)).toColor(),
    ],
  );
}
