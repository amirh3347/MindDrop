import 'package:flutter/material.dart';

import '../models/task.dart';

/// Accent colors the user can pick from. Index 0 is the brand violet.
const List<Color> kAccents = [
  Color(0xFF7C5CFF), // violet
  Color(0xFF22D3EE), // cyan
  Color(0xFFF472B6), // pink
  Color(0xFF34D399), // green
  Color(0xFFFB923C), // orange
  Color(0xFF60A5FA), // blue
  Color(0xFFF87171), // coral
  Color(0xFFFBBF24), // amber
];

Color accentAt(int index) => kAccents[index.clamp(0, kAccents.length - 1)];

/// The brand gradient used by the logo and a few highlights.
const LinearGradient kBrandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFC084FC), Color(0xFF7C5CFF), Color(0xFF22D3EE)],
);

Color priorityColor(TaskPriority p, ColorScheme scheme) => switch (p) {
      TaskPriority.high => const Color(0xFFF87171),
      TaskPriority.medium => const Color(0xFFFBBF24),
      TaskPriority.low => const Color(0xFF60A5FA),
      TaskPriority.none => scheme.outline,
    };

const Color kSuccess = Color(0xFF34D399);
const Color kDanger = Color(0xFFF87171);

ThemeData buildTheme(Brightness brightness, Color accent, {bool amoled = false}) {
  final dark = brightness == Brightness.dark;
  var scheme = ColorScheme.fromSeed(
    seedColor: accent,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  );

  if (dark && amoled) {
    scheme = scheme.copyWith(
      surface: const Color(0xFF000000),
      surfaceContainerLowest: const Color(0xFF000000),
      surfaceContainerLow: const Color(0xFF0A0A0F),
      surfaceContainer: const Color(0xFF111117),
      surfaceContainerHigh: const Color(0xFF18181F),
      surfaceContainerHighest: const Color(0xFF202029),
    );
  } else if (dark) {
    // Deep ink-blue surfaces that match the logo.
    scheme = scheme.copyWith(
      surface: const Color(0xFF0E0D1A),
      surfaceContainerLowest: const Color(0xFF0A0914),
      surfaceContainerLow: const Color(0xFF141324),
      surfaceContainer: const Color(0xFF1A192C),
      surfaceContainerHigh: const Color(0xFF222136),
      surfaceContainerHighest: const Color(0xFF2B2A41),
    );
  } else {
    scheme = scheme.copyWith(
      surface: const Color(0xFFF6F5FB),
      surfaceContainerLowest: const Color(0xFFFFFFFF),
      surfaceContainerLow: const Color(0xFFFFFFFF),
      surfaceContainer: const Color(0xFFFFFFFF),
      surfaceContainerHigh: const Color(0xFFEEEDF6),
      surfaceContainerHighest: const Color(0xFFE6E4F0),
    );
  }

  final radius = BorderRadius.circular(18);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Vazirmatn',
    scaffoldBackgroundColor: scheme.surface,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Vazirmatn',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainer,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: radius),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.primary, width: 1.4),
      ),
      hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      indicatorColor: scheme.primary.withValues(alpha: dark ? 0.22 : 0.16),
      surfaceTintColor: Colors.transparent,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      labelStyle: const TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.w500),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? scheme.surfaceContainerHighest : const Color(0xFF1F1D2E),
      contentTextStyle: TextStyle(
        fontFamily: 'Vazirmatn',
        color: dark ? scheme.onSurface : Colors.white,
      ),
      actionTextColor: scheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.35),
      space: 1,
      thickness: 1,
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      iconColor: scheme.onSurfaceVariant,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.w600),
        ),
        side: WidgetStatePropertyAll(
          BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
    ),
  );
}
