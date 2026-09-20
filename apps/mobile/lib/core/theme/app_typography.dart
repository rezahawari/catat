import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static const fontFamily = 'PlusJakartaSans';

  // Display & Numbers (Saldo/Total Utama)
  static TextStyle displayLarge({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: color,
      );

  static TextStyle displayMedium({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        color: color,
      );

  // Headlines
  static TextStyle headlineLarge({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle headlineMedium({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // Body
  static TextStyle bodyLarge({Color? color, FontWeight? fontWeight}) => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: fontWeight ?? FontWeight.w400,
        letterSpacing: 0.1,
        color: color,
      );

  static TextStyle bodyMedium({Color? color, FontWeight? fontWeight}) => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: fontWeight ?? FontWeight.w400,
        color: color,
      );

  static TextStyle bodySmall({Color? color, FontWeight? fontWeight}) => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: fontWeight ?? FontWeight.w400,
        color: color,
      );

  // Labels & Badges
  static TextStyle labelLarge({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: color,
      );

  static TextStyle labelSmall({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: color,
      );
}
