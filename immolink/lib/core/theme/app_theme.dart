import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
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
        displayLarge: AppTypography.heading1,
        displayMedium: AppTypography.heading2,
        headlineMedium: AppTypography.subhead,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.bodySecondary,
        bodySmall: AppTypography.caption,
        labelLarge: AppTypography.buttonText,
      ),
      
      // Visual density
      visualDensity: VisualDensity.adaptivePlatformDensity,
      
      // Material 3
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      // Color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryAccent,
        brightness: Brightness.dark,
        primary: AppColors.primaryAccent,
        surface: AppColors.darkSurfaceCards,
        error: AppColors.error,
        background: AppColors.darkPrimaryBackground,
        onPrimary: AppColors.darkTextOnAccent,
        onSurface: AppColors.darkTextPrimary,
        onBackground: AppColors.darkTextPrimary,
        onError: AppColors.darkTextOnAccent,
        secondary: AppColors.luxuryGold,
        onSecondary: AppColors.darkTextOnGold,
        tertiary: AppColors.darkSurfaceSecondary,
        onTertiary: AppColors.darkTextSecondary,
        outline: AppColors.darkDividerSeparator,
        outlineVariant: AppColors.darkBorderLight,
        surfaceVariant: AppColors.darkSurfaceSecondary,
        onSurfaceVariant: AppColors.darkTextSecondary,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: AppColors.darkPrimaryBackground,
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkPrimaryBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        toolbarHeight: AppSizes.topAppBarHeight,
        titleTextStyle: AppTypography.darkSubhead,
        iconTheme: IconThemeData(
          color: AppColors.darkTextPrimary,
          size: AppSizes.iconMedium,
        ),
      ),
      
      // Card Theme
      cardTheme: CardTheme(
        color: AppColors.darkSurfaceCards,
        elevation: 0,
        shadowColor: AppColors.darkShadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.cardsButtons),
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAccent,
          foregroundColor: AppColors.darkTextOnAccent,
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
          textStyle: AppTypography.darkBody.copyWith(
            color: AppColors.primaryAccent,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryAccent,
          side: const BorderSide(color: AppColors.primaryAccent),
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.cardsButtons),
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceCards,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.searchBar),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.searchBar),
          borderSide: BorderSide(color: AppColors.darkBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.searchBar),
          borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1),
        ),
        hintStyle: AppTypography.darkBody.copyWith(
          color: AppColors.darkTextPlaceholder,
        ),
        labelStyle: AppTypography.darkBody.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.searchBarPadding,
          vertical: AppSpacing.md,
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkPrimaryBackground,
        selectedItemColor: AppColors.primaryAccent,
        unselectedItemColor: AppColors.darkTextPlaceholder,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTypography.darkCaption,
        unselectedLabelStyle: AppTypography.darkCaption,
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: AppColors.darkDividerSeparator,
        thickness: 1,
        space: 1,
      ),
      
      // Icon Theme
      iconTheme: IconThemeData(
        color: AppColors.darkTextSecondary,
        size: AppSizes.iconMedium,
      ),
      
      // Primary Icon Theme
      primaryIconTheme: IconThemeData(
        color: AppColors.darkTextPrimary,
        size: AppSizes.iconMedium,
      ),
      
      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTypography.darkHeading1,
        displayMedium: AppTypography.darkHeading2,
        headlineMedium: AppTypography.darkSubhead,
        bodyLarge: AppTypography.darkBody,
        bodyMedium: AppTypography.darkBodySecondary,
        bodySmall: AppTypography.darkCaption,
        labelLarge: AppTypography.buttonText,
        titleMedium: AppTypography.darkSubhead,
        titleSmall: AppTypography.darkBody,
        labelMedium: AppTypography.darkBodySecondary,
        labelSmall: AppTypography.darkCaption,
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primaryAccent;
          }
          return AppColors.darkTextTertiary;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primaryAccent.withValues(alpha: 0.3);
          }
          return AppColors.darkBorderLight;
        }),
      ),
      
      // ListTile Theme
      listTileTheme: ListTileThemeData(
        textColor: AppColors.darkTextPrimary,
        iconColor: AppColors.darkTextSecondary,
        tileColor: AppColors.darkSurfaceCards,
        selectedTileColor: AppColors.darkAccentLight,
        selectedColor: AppColors.primaryAccent,
      ),
      
      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.darkSurfaceCards,
        titleTextStyle: AppTypography.darkHeading2,
        contentTextStyle: AppTypography.darkBody,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.modalsOverlays),
        ),
      ),
      
      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurfaceSecondary,
        contentTextStyle: AppTypography.darkBody,
        actionTextColor: AppColors.primaryAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.cardsButtons),
        ),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceSecondary,
        labelStyle: AppTypography.darkBodySecondary,
        selectedColor: AppColors.darkAccentLight,
        secondarySelectedColor: AppColors.primaryAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.cardsButtons),
        ),
      ),
      
      // Visual density
      visualDensity: VisualDensity.adaptivePlatformDensity,
      
      // Material 3
      useMaterial3: true,
      
      // Brightness
      brightness: Brightness.dark,
    );
  }
}
