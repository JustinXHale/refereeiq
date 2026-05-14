// ─────────────────────────────────────────────────────────────────────────────
// RefereeIQ Design Token Reference
// See also: .design/features/theming/design-token-reference.md
//
// NEVER hard-code colours in UI widgets. Always read from Theme.of(context).colorScheme.
//
// ┌─────────────────────────────┬──────────────────────────────────────────────┐
// │ Token                       │ Use                                          │
// ├─────────────────────────────┼──────────────────────────────────────────────┤
// │ primary          #FBD823    │ AppBar bg, FilledButton bg, chip selected,   │
// │                             │ user chat bubble, active indicator           │
// │ onPrimary        #212121    │ Text/icons ON primary surfaces               │
// │ secondary        #212121    │ Secondary interactive elements               │
// │ onSecondary      #FFFFFF    │ Text/icons ON secondary surfaces             │
// │ tertiary         #0C2E55    │ Links, accents, deep-navy highlights         │
// │ onTertiary       #FFFFFF    │ Text/icons ON tertiary surfaces              │
// │ surface          #FFFFFF    │ Page / scaffold background                   │
// │ onSurface        #212121    │ Primary body text, headings, icons           │
// │ onSurfaceVariant (computed) │ Secondary/hint text, timestamps, subtitles  │
// │ surfaceContainer-           │                                              │
// │   Highest        (computed) │ Card fills, message bubbles (bot), chips     │
// │ outline          (computed) │ Input borders, dividers                      │
// │ primaryContainer (computed) │ Warm tinted card backgrounds, blockquotes    │
// │ secondaryContainer(computed)│ Sub-category chip selected fill              │
// │ error            #FF0000    │ Destructive actions, badges, error icons     │
// │ onError          #FFFFFF    │ Text/icons ON error surfaces (badge count)   │
// │ shadow           (computed) │ Box-shadow colour (use low alpha)            │
// └─────────────────────────────┴──────────────────────────────────────────────┘
//
// Button hierarchy:
//   Primary action   → FilledButton      (primary / onPrimary)
//   Secondary action → FilledButton.tonal (secondaryContainer / onSecondaryContainer)
//   Tertiary action  → OutlinedButton    (inherits outline colour)
//   Destructive      → TextButton with colorScheme.error foreground
//
// DO NOT use:
//   Colors.grey.shade*  → use onSurfaceVariant or surfaceContainerHighest
//   Colors.black / black87 → use onSurface
//   Colors.white (fills) → use surface or surfaceContainerHighest
//   Colors.red (badge)  → use error / onError
//   Hex literals for brand colours → use primary / onPrimary
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RefereeIQTheme {
  static final ColorScheme _light = ColorScheme.fromSeed(
    seedColor: const Color(0xFFFBD823),
    brightness: Brightness.light,
    primary: const Color(0xFFFBD823),
    onPrimary: const Color(0xFF212121),
    secondary: const Color(0xFF212121),
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: const Color(0xFF212121),
    error: Colors.red,
    onError: Colors.white,
    tertiary: const Color(0xFF0C2E55),
    onTertiary: Colors.white,
  );

  static final ColorScheme _dark = ColorScheme.fromSeed(
    seedColor: const Color(0xFFFBD823),
    brightness: Brightness.dark,
    primary: const Color(0xFFFBD823),
    onPrimary: const Color(0xFF212121),
    error: Colors.red,
    onError: Colors.white,
    tertiary: const Color(0xFF4A90D9),
    onTertiary: Colors.white,
  );

  static ThemeData _build(ColorScheme cs) => ThemeData(
    colorScheme: cs,
    useMaterial3: true,
    scaffoldBackgroundColor: cs.surface,
    textTheme: cs.brightness == Brightness.light
        ? GoogleFonts.interTextTheme()
        : GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: cs.onPrimary,
      unselectedLabelColor: cs.onPrimary.withValues(alpha: 0.6),
      indicatorColor: cs.onPrimary,
      dividerColor: Colors.transparent,
    ),
    chipTheme: ChipThemeData(
      selectedColor: cs.primary,
      backgroundColor: cs.surfaceContainerHighest,
      labelStyle: TextStyle(color: cs.onSurface),
      secondaryLabelStyle: TextStyle(color: cs.onPrimary),
      checkmarkColor: cs.onPrimary,
      side: BorderSide(color: cs.outline),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: cs.outline),
      ),
      labelStyle: TextStyle(color: cs.onSurfaceVariant),
      hintStyle: TextStyle(color: cs.onSurfaceVariant),
    ),
  );

  static ThemeData get lightTheme => _build(_light);
  static ThemeData get darkTheme  => _build(_dark);
}
