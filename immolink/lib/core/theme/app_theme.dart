import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_colors_dark.dart';
import 'app_typography.dart';
import 'app_spacing.dart';
import 'app_motion.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      // Color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryAccent,
        brightness: Brightness.light,
        primary: AppColors.primaryAccent,
        surface: AppColors.surfaceCards,
        error: AppColors.error,
        onPrimary: AppColors.textOnAccent,
        onSurface: AppColors.textPrimary,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.primaryBackground,

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        toolbarHeight: AppSizes.topAppBarHeight,
        titleTextStyle: AppTypography.subhead,
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: AppSizes.iconMedium,
        ),
      ),

      // Card Theme (slight elevation feel via surface tint)
      cardTheme: CardThemeData(
        color: AppColors.surfaceCards,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.cardsButtons),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAccent,
          foregroundColor: AppColors.textOnAccent,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonHeight / 2),
          ),
          minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
          textStyle: AppTypography.buttonText,
          animationDuration: AppMotion.medium,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith(
            (s) => AppColors.primaryAccent.withValues(
                alpha: s.contains(WidgetState.pressed) ? 0.15 : 0.08),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentLight,
          foregroundColor: AppColors.primaryAccent,
          textStyle:
              AppTypography.buttonText.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonHeight / 2),
          ),
          animationDuration: AppMotion.medium,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryAccent,
          side: BorderSide(
              color: AppColors.primaryAccent.withValues(alpha: 0.55),
              width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonHeight / 2),
          ),
          textStyle:
              AppTypography.buttonText.copyWith(fontWeight: FontWeight.w600),
          minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith(
              (s) => AppColors.primaryAccent.withValues(alpha: 0.08)),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryAccent,
          textStyle: AppTypography.body.copyWith(
            color: AppColors.primaryAccent,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceCards,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.searchBar),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.searchBar),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.searchBar),
          borderSide:
              const BorderSide(color: AppColors.primaryAccent, width: 1),
        ),
        hintStyle: AppTypography.body.copyWith(
          color: AppColors.textPlaceholder,
        ),
        // Fix text color visibility
        labelStyle: AppTypography.body.copyWith(
          color: AppColors.textPrimary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.searchBarPadding,
          vertical: AppSpacing.md,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.primaryBackground,
        selectedItemColor: AppColors.primaryAccent,
        unselectedItemColor: AppColors.textPlaceholder,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerSeparator,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: AppSizes.iconMedium,
      ),
      // Text Theme
      textTheme: TextTheme(
        displayLarge:
            AppTypography.heading1.copyWith(color: AppColors.textPrimary),
        displayMedium:
            AppTypography.heading2.copyWith(color: AppColors.textPrimary),
        headlineMedium:
            AppTypography.subhead.copyWith(color: AppColors.textPrimary),
        bodyLarge: AppTypography.body.copyWith(color: AppColors.textPrimary),
        bodyMedium: AppTypography.bodySecondary
            .copyWith(color: AppColors.textSecondary),
        bodySmall:
            AppTypography.caption.copyWith(color: AppColors.textTertiary),
        labelLarge:
            AppTypography.buttonText.copyWith(color: AppColors.textOnAccent),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle:
            AppTypography.body.copyWith(color: AppColors.textOnAccent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.cardsButtons),
        ),
      ),

      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.accentLight,
        selectedColor: AppColors.primaryAccent.withValues(alpha: 0.12),
        labelStyle:
            AppTypography.caption.copyWith(color: AppColors.textSecondary),
        selectedShadowColor: Colors.transparent,
        disabledColor: AppColors.dividerSeparator,
        side: const BorderSide(color: AppColors.borderLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceCards,
        elevation: 8,
        shadowColor: AppColors.shadowColorStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.modalsOverlays),
        ),
        titleTextStyle:
            AppTypography.heading2.copyWith(color: AppColors.textPrimary),
        contentTextStyle:
            AppTypography.body.copyWith(color: AppColors.textSecondary),
      ),

      // Visual density
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      // Color scheme for dark mode
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColorsDark.primaryAccent,
        brightness: Brightness.dark,
        primary: AppColorsDark.primaryAccent,
        surface: AppColorsDark.surfaceCards,
        error: AppColorsDark.error,
        onPrimary: AppColorsDark.textOnAccent,
        onSurface: AppColorsDark.textPrimary,
        onError: AppColorsDark.textOnAccent,
        outline: AppColorsDark.borderLight,
        shadow: AppColorsDark.shadowColor,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColorsDark.primaryBackground,

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorsDark.appBarBackground,
        foregroundColor: AppColorsDark.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        toolbarHeight: AppSizes.topAppBarHeight,
        titleTextStyle: AppTypography.subhead.copyWith(
          color: AppColorsDark.textPrimary,
        ),
        iconTheme: const IconThemeData(
          color: AppColorsDark.textPrimary,
          size: AppSizes.iconMedium,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColorsDark.surfaceCards,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.cardsButtons),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsDark.primaryAccent,
          foregroundColor: AppColorsDark.textOnAccent,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonHeight / 2),
          ),
          minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
          textStyle: AppTypography.buttonText
              .copyWith(color: AppColorsDark.textOnAccent),
          animationDuration: AppMotion.medium,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith(
            (s) => AppColorsDark.primaryAccent.withValues(
                alpha: s.contains(WidgetState.pressed) ? 0.3 : 0.18),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColorsDark.accentLight,
          foregroundColor: AppColorsDark.textPrimary,
          textStyle: AppTypography.buttonText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonHeight / 2),
          ),
          animationDuration: AppMotion.medium,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsDark.primaryAccent,
          side: BorderSide(
              color: AppColorsDark.primaryAccent.withValues(alpha: 0.55),
              width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonHeight / 2),
          ),
          textStyle: AppTypography.buttonText,
          minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith(
              (s) => AppColorsDark.primaryAccent.withValues(alpha: 0.22)),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsDark.primaryAccent,
          textStyle: AppTypography.body.copyWith(
            color: AppColorsDark.primaryAccent,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsDark.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.searchBar),
          borderSide: const BorderSide(color: AppColorsDark.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.searchBar),
          borderSide: const BorderSide(color: AppColorsDark.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.searchBar),
          borderSide: const BorderSide(
              color: AppColorsDark.inputFocusedBorder, width: 1),
        ),
        hintStyle: AppTypography.body.copyWith(
          color: AppColorsDark.textPlaceholder,
        ),
        labelStyle: AppTypography.body.copyWith(
          color: AppColorsDark.textPrimary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.searchBarPadding,
          vertical: AppSpacing.md,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColorsDark.navigationBackground,
        selectedItemColor: AppColorsDark.navigationSelected,
        unselectedItemColor: AppColorsDark.navigationUnselected,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColorsDark.dividerSeparator,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColorsDark.textSecondary,
        size: AppSizes.iconMedium,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge:
            AppTypography.heading1.copyWith(color: AppColorsDark.textPrimary),
        displayMedium:
            AppTypography.heading2.copyWith(color: AppColorsDark.textPrimary),
        headlineMedium:
            AppTypography.subhead.copyWith(color: AppColorsDark.textPrimary),
        bodyLarge:
            AppTypography.body.copyWith(color: AppColorsDark.textPrimary),
        bodyMedium: AppTypography.bodySecondary
            .copyWith(color: AppColorsDark.textSecondary),
        bodySmall:
            AppTypography.caption.copyWith(color: AppColorsDark.textTertiary),
        labelLarge: AppTypography.buttonText
            .copyWith(color: AppColorsDark.textOnAccent),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColorsDark.dialogBackground,
        elevation: 8,
        shadowColor: AppColorsDark.shadowColorStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.cardsButtons),
        ),
        titleTextStyle:
            AppTypography.subhead.copyWith(color: AppColorsDark.textPrimary),
        contentTextStyle:
            AppTypography.body.copyWith(color: AppColorsDark.textSecondary),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColorsDark.bottomSheetBackground,
        elevation: 8,
        shadowColor: AppColorsDark.shadowColorStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppBorderRadius.cardsButtons),
          ),
        ),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColorsDark.primaryAccent;
          }
          return AppColorsDark.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColorsDark.primaryAccent.withValues(alpha: 0.3);
          }
          return AppColorsDark.borderMedium;
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColorsDark.primaryAccent;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColorsDark.textOnAccent),
        side: const BorderSide(color: AppColorsDark.borderMedium),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColorsDark.primaryAccent,
        linearTrackColor: AppColorsDark.borderLight,
        circularTrackColor: AppColorsDark.borderLight,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColorsDark.fabBackground,
        foregroundColor: AppColorsDark.textOnAccent,
        elevation: 6,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.buttonHeight / 2),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        backgroundColor: AppColorsDark.surfaceCards,
        contentTextStyle:
            AppTypography.body.copyWith(color: AppColorsDark.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.cardsButtons),
        ),
      ),

      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColorsDark.chatBackground,
        selectedColor: AppColorsDark.primaryAccent.withValues(alpha: 0.22),
        labelStyle:
            AppTypography.caption.copyWith(color: AppColorsDark.textSecondary),
        selectedShadowColor: Colors.transparent,
        disabledColor: AppColorsDark.dividerSeparator,
        side: const BorderSide(color: AppColorsDark.borderLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
