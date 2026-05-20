import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    scaffoldBackgroundColor: AppColors.darkNavy,
    brightness: Brightness.dark,
    textTheme: GoogleFonts.poppinsTextTheme(
      ThemeData.dark().textTheme,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.yellow,
      brightness: Brightness.dark,
    ),
  );
}
