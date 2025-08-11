import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_colors_dark.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(      // Color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryAccent,
        brightness: Brightness.light,
        primary: AppColors.primaryAccent,
        surface: AppColors.surfaceCards,
        error: AppColors.error,
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
        iconTheme: IconThemeData(
          color: AppColors.textPrimary,
          size: AppSizes.iconMedium,
        ),
      ),
      
      // Card Theme
      cardTheme: CardTheme(
        color: AppColors.primaryBackground,
        elevation: 0,
        shadowColor: AppColors.shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.cardsButtons),
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonHeight / 2), // Pill shape
          ),
          minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
          textStyle: AppTypography.buttonText,
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
          borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1),
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
        displayLarge: AppTypography.heading1.copyWith(color: AppColors.textPrimary, inherit: true),
        displayMedium: AppTypography.heading2.copyWith(color: AppColors.textPrimary, inherit: true),
        headlineMedium: AppTypography.subhead.copyWith(color: AppColors.textPrimary, inherit: true),
        bodyLarge: AppTypography.body.copyWith(color: AppColors.textPrimary, inherit: true),
        bodyMedium: AppTypography.bodySecondary.copyWith(color: AppColors.textSecondary, inherit: true),
        bodySmall: AppTypography.caption.copyWith(color: AppColors.textTertiary, inherit: true),
        labelLarge: AppTypography.buttonText.copyWith(color: AppColors.textOnAccent, inherit: true),
      ),
      
      // Visual density
      visualDensity: VisualDensity.adaptivePlatformDensity,
      
      // Material 3
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
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
        iconTheme: IconThemeData(
          color: AppColorsDark.textPrimary,
          size: AppSizes.iconMedium,
        ),
      ),
      
      // Card Theme
      cardTheme: CardTheme(
        color: AppColorsDark.surfaceCards,
        elevation: 0,
        shadowColor: AppColorsDark.shadowColor,
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
          textStyle: AppTypography.buttonText.copyWith(
            color: AppColorsDark.textOnAccent,
          ),
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
          borderSide: BorderSide(color: AppColorsDark.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.searchBar),
          borderSide: BorderSide(color: AppColorsDark.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.searchBar),
          borderSide: BorderSide(color: AppColorsDark.inputFocusedBorder, width: 1),
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
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColorsDark.navigationBackground,
        selectedItemColor: AppColorsDark.navigationSelected,
        unselectedItemColor: AppColorsDark.navigationUnselected,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: AppColorsDark.dividerSeparator,
        thickness: 1,
        space: 1,
      ),
      
      // Icon Theme
      iconTheme: IconThemeData(
        color: AppColorsDark.textSecondary,
        size: AppSizes.iconMedium,
      ),
      
      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTypography.heading1.copyWith(color: AppColorsDark.textPrimary),
        displayMedium: AppTypography.heading2.copyWith(color: AppColorsDark.textPrimary),
        headlineMedium: AppTypography.subhead.copyWith(color: AppColorsDark.textPrimary),
        bodyLarge: AppTypography.body.copyWith(color: AppColorsDark.textPrimary),
        bodyMedium: AppTypography.bodySecondary.copyWith(color: AppColorsDark.textSecondary),
        bodySmall: AppTypography.caption.copyWith(color: AppColorsDark.textTertiary),
        labelLarge: AppTypography.buttonText.copyWith(color: AppColorsDark.textOnAccent),
      ),
      
      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: AppColorsDark.dialogBackground,
        elevation: 8,
        shadowColor: AppColorsDark.shadowColorStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.cardsButtons),
        ),
        titleTextStyle: AppTypography.subhead.copyWith(
          color: AppColorsDark.textPrimary,
        ),
        contentTextStyle: AppTypography.body.copyWith(
          color: AppColorsDark.textSecondary,
        ),
      ),
      
      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColorsDark.bottomSheetBackground,
        elevation: 8,
        shadowColor: AppColorsDark.shadowColorStrong,
        shape: const RoundedRectangleBorder(
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
        side: BorderSide(color: AppColorsDark.borderMedium),
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
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
      
      // Visual density
      visualDensity: VisualDensity.adaptivePlatformDensity,
      
      // Material 3
      useMaterial3: true,
    );
  }
}
