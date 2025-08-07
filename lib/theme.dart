import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RefereeIQTheme {
  static final ColorScheme _colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFFFADC44),
    brightness: Brightness.light,
    primary: const Color(0xFFFADC44),
    onPrimary: const Color(0xFF212121),
    secondary: const Color(0xFF212121),
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: const Color(0xFF212121),
    background: Colors.white,
    onBackground: const Color(0xFF212121),
    error: Colors.red,
    onError: Colors.white,
  );

  static ThemeData get lightTheme => ThemeData(
    colorScheme: _colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: _colorScheme.background,
    textTheme: GoogleFonts.interTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: _colorScheme.primary,
      foregroundColor: _colorScheme.onPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
    ),
  );
}
