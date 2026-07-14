import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// KOR theme — dark only, Bricolage Grotesque, flat surfaces, hairline borders.
///
/// Type scale, radii and paddings come from the KOR design handoff README.
/// Cards are "glass": translucent white fill + 1px white-9% border, radius 20.
class AppTheme {
  AppTheme._();

  /// Monospace style for invite codes and countdowns (letter-spaced per spec).
  static TextStyle mono({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.textPrimary,
    double letterSpacing = 3,
  }) {
    return GoogleFonts.ibmPlexMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle _brico(double size, FontWeight weight,
      {Color color = AppColors.textPrimary, double? spacing, double? height}) {
    return GoogleFonts.bricolageGrotesque(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
      height: height,
    );
  }

  static ThemeData get darkTheme {
    final textTheme = TextTheme(
      // Wordmark-adjacent / large display
      displayLarge: _brico(44, FontWeight.w800, spacing: -1.4),
      displayMedium: _brico(26, FontWeight.w800, spacing: -0.5),
      displaySmall: _brico(24, FontWeight.w800, spacing: -0.4),
      // Hero challenge text: 20-22 / 800 / line-height 1.3
      headlineLarge: _brico(22, FontWeight.w800, height: 1.3),
      headlineMedium: _brico(21, FontWeight.w800, height: 1.3),
      headlineSmall: _brico(20, FontWeight.w800, height: 1.3),
      // Screen titles: 19 / 800 / -0.3
      titleLarge: _brico(19, FontWeight.w800, spacing: -0.3),
      // Card titles: 16-17 / 700
      titleMedium: _brico(16.5, FontWeight.w700),
      titleSmall: _brico(14, FontWeight.w600),
      // Body: 13-14
      bodyLarge: _brico(14.5, FontWeight.w400),
      bodyMedium: _brico(13.5, FontWeight.w400),
      bodySmall: _brico(12, FontWeight.w400, color: AppColors.textTertiary),
      // Labels; labelMedium = section labels (12 / 700 / +1.6, uppercase at call site)
      labelLarge: _brico(14, FontWeight.w600),
      labelMedium:
          _brico(12, FontWeight.w700, color: AppColors.textTertiary, spacing: 1.6),
      labelSmall: _brico(11, FontWeight.w500, color: AppColors.textTertiary),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      // Card taps get a subtle scale, never a ripple splash.
      splashFactory: NoSplash.splashFactory,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.accent,
        onSecondary: AppColors.onPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: AppColors.textPrimary,
        outline: AppColors.glassBorder,
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: textTheme.titleLarge,
      ),

      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: AppColors.glassBorder, width: 1),
        ),
        color: AppColors.surfaceGlass,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          )),
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.pressed)
                  ? AppColors.primaryPressed
                  : AppColors.primary),
          foregroundColor: const WidgetStatePropertyAll(AppColors.onPrimary),
          textStyle: WidgetStatePropertyAll(_brico(15, FontWeight.w700)),
        ),
      ),

      // Ghost buttons: 1px white-12% border, dimmed text.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: const BorderSide(color: Color(0x1FFFFFFF)),
          foregroundColor: AppColors.textSecondary,
          textStyle: _brico(14, FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryText,
          textStyle: _brico(14, FontWeight.w700),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceGlass,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: _brico(14, FontWeight.w400, color: AppColors.textFaint),
        labelStyle: _brico(13, FontWeight.w500, color: AppColors.textTertiary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.coralBorder),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),

      // Rectangular coral FAB; the only elevation shadow in the app.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        extendedTextStyle: _brico(14.5, FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: _brico(13.5, FontWeight.w500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
    );
  }

  /// The app is dark-only; light requests get the KOR theme too.
  static ThemeData get lightTheme => darkTheme;
}
