import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_colors_dark.dart';
import '../providers/theme_provider.dart';

// Dynamic color provider that switches between light and dark colors
final dynamicColorsProvider = Provider<DynamicAppColors>((ref) {
  final effectiveTheme = ref.watch(effectiveThemeProvider);
  return DynamicAppColors(isDark: effectiveTheme == 'dark');
});

// Helper class that provides colors based on current theme
class DynamicAppColors {
  final bool isDark;
  
  DynamicAppColors({required this.isDark});
  
  // Primary colors
  Color get primaryBackground => isDark ? AppColorsDark.primaryBackground : AppColors.primaryBackground;
  Color get surfaceCards => isDark ? AppColorsDark.surfaceCards : AppColors.surfaceCards;
  Color get surfaceSecondary => isDark ? AppColorsDark.surfaceSecondary : AppColors.surfaceSecondary;
  Color get dividerSeparator => isDark ? AppColorsDark.dividerSeparator : AppColors.dividerSeparator;
  
  // Accent colors
  Color get primaryAccent => isDark ? AppColorsDark.primaryAccent : AppColors.primaryAccent;
  Color get luxuryGold => isDark ? AppColorsDark.luxuryGold : AppColors.luxuryGold;
  Color get accentLight => isDark ? AppColorsDark.accentLight : AppColors.accentLight;
  Color get goldLight => isDark ? AppColorsDark.goldLight : AppColors.goldLight;
  
  // Text colors
  Color get textPrimary => isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
  Color get textSecondary => isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
  Color get textTertiary => isDark ? AppColorsDark.textTertiary : AppColors.textTertiary;
  Color get textPlaceholder => isDark ? AppColorsDark.textPlaceholder : AppColors.textPlaceholder;
  Color get textOnAccent => isDark ? AppColorsDark.textOnAccent : AppColors.textOnAccent;
  Color get textOnGold => isDark ? AppColorsDark.textOnGold : AppColors.textOnGold;
  
  // Status colors
  Color get success => isDark ? AppColorsDark.success : AppColors.success;
  Color get warning => isDark ? AppColorsDark.warning : AppColors.warning;
  Color get error => isDark ? AppColorsDark.error : AppColors.error;
  Color get info => isDark ? AppColorsDark.info : AppColors.info;
  
  // Status light variants
  Color get successLight => isDark ? AppColorsDark.successLight : AppColors.successLight;
  Color get warningLight => isDark ? AppColorsDark.warningLight : AppColors.warningLight;
  Color get errorLight => isDark ? AppColorsDark.errorLight : AppColors.errorLight;
  Color get infoLight => isDark ? AppColorsDark.infoLight : AppColors.infoLight;
  
  // Effects & shadows
  Color get shadowColor => isDark ? AppColorsDark.shadowColor : AppColors.shadowColor;
  Color get shadowColorMedium => isDark ? AppColorsDark.shadowColorMedium : AppColors.shadowColorMedium;
  Color get shadowColorStrong => isDark ? AppColorsDark.shadowColorStrong : AppColors.shadowColorStrong;
  Color get glassBackground => isDark ? AppColorsDark.glassBackground : AppColors.glassBackground;
  Color get overlayBackground => isDark ? AppColorsDark.overlayBackground : AppColors.overlayBackground;
  Color get overlayWhite => isDark ? AppColorsDark.overlayWhite : AppColors.overlayWhite;
  
  // Borders
  Color get borderLight => isDark ? AppColorsDark.borderLight : AppColors.borderLight;
  Color get borderMedium => isDark ? AppColorsDark.borderMedium : AppColors.borderMedium;
  Color get borderAccent => isDark ? AppColorsDark.borderAccent : AppColors.borderAccent;
  
  // Chat specific
  Color get chatBackground => isDark ? AppColorsDark.chatBackground : AppColors.chatBackground;
  Color get chatBubbleUser => isDark ? AppColorsDark.chatBubbleUser : AppColors.chatBubbleUser;
  Color get chatBubbleOther => isDark ? AppColorsDark.chatBubbleOther : AppColors.chatBubbleOther;
  Color get chatInputBackground => isDark ? AppColorsDark.chatInputBackground : AppColors.chatInputBackground;
  
  // Gradients
  Color get gradientStart => isDark ? AppColorsDark.gradientStart : AppColors.gradientStart;
  Color get gradientEnd => isDark ? AppColorsDark.gradientEnd : AppColors.gradientEnd;
  Color get luxuryGradientStart => isDark ? AppColorsDark.luxuryGradientStart : AppColors.luxuryGradientStart;
  Color get luxuryGradientEnd => isDark ? AppColorsDark.luxuryGradientEnd : AppColors.luxuryGradientEnd;
  
  // Helper method to create gradients
  LinearGradient createGradient({
    AlignmentGeometry? begin,
    AlignmentGeometry? end,
    bool isLuxury = false,
  }) {
    return LinearGradient(
      begin: begin ?? Alignment.topLeft,
      end: end ?? Alignment.bottomRight,
      colors: isLuxury 
        ? [luxuryGradientStart, luxuryGradientEnd]
        : [gradientStart, gradientEnd],
    );
  }
  
  // Helper method for surface elevation
  Color surfaceWithElevation(int elevation) {
    if (isDark) {
      // In dark mode, add white overlay for elevation
      final opacity = (elevation * 0.05).clamp(0.0, 0.15);
      return Color.alphaBlend(
        Colors.white.withValues(alpha: opacity),
        surfaceCards,
      );
    } else {
      // In light mode, use subtle shadows
      return surfaceCards;
    }
  }
}
