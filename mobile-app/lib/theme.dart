import 'package:flutter/material.dart'
    show Brightness, Color, ColorScheme, ThemeData;
import 'package:google_fonts/google_fonts.dart' as google_fonts;

ThemeData get appTheme => ThemeData(
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF212121), // Dark grey (WCAG AAA compliant)
    onPrimary: Color(0xFFFFFFFF), // White
    secondary: Color(0xFF616161), // Medium grey (WCAG AA compliant)
    onSecondary: Color(0xFFFFFFFF), // White
    error: Color(0xFF212121), // Dark grey for errors
    onError: Color(0xFFFFFFFF), // White
    surface: Color(0xFFFFFFFF), // White
    onSurface: Color(0xFF212121), // Dark grey
  ),
  textTheme: google_fonts.GoogleFonts.workSansTextTheme(),
);
