import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData loginTheme = ThemeData(
  colorScheme: ColorScheme.light(
    primary: const Color.fromARGB(255, 197, 193, 193),
  ),
  primaryColor: const Color(0xFF4B39EF), // Primary color
  scaffoldBackgroundColor: const Color.fromARGB(
    255,
    232,
    229,
    230,
  ), // Primary background
  textTheme: TextTheme(
    displaySmall: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF14181B), // Primary text
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      color: const Color(0xFF57636C), // Secondary text
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      color: const Color(0xFF57636C), // Secondary text
    ),
  ),
);
