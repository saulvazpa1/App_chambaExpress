import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colores base de ChambaExpress (alineados al maquetado)
  static const Color primaryColor = Color(0xFF1E5CA8);
  static const Color secondaryColor = Color(0xFF0D0D0F);
  static const Color backColor = Color(0xFF1E5CA8);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color accentColor = Color(0xFFF6C619);
  static const Color successColor = Color(0xFF25B818);
  static const Color dangerColor = Color(0xFFB31237);
  static const Color mutedTextColor = Color(0xFFD6E2F0);

  static final ThemeData lightTheme = ThemeData.light().copyWith(
    scaffoldBackgroundColor: backColor,
    appBarTheme: AppBarTheme(
      color: surfaceWhite,
      foregroundColor: secondaryColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.ubuntu(
        color: secondaryColor,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(successColor),
        foregroundColor: WidgetStateProperty.all(surfaceWhite),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        textStyle: WidgetStateProperty.all(
          GoogleFonts.openSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.epilogue(
        color: surfaceWhite,
        fontSize: 26,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.epilogue(
        color: surfaceWhite,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: GoogleFonts.openSans(
        color: surfaceWhite,
        fontSize: 15,
        height: 1.35,
      ),
      bodySmall: GoogleFonts.openSans(
        color: mutedTextColor,
        fontSize: 13.5,
      ),
    ),
  );
}