import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  // Text Styles following the design specifications using Google Fonts Inter
  static TextStyle heading1 = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600, // Semibold
    height: 32 / 24, // Line height 32pt / font size 24pt
    color: AppColors.textPrimary,
  );
  
  static TextStyle heading2 = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600, // Semibold
    height: 28 / 20, // Line height 28pt / font size 20pt
    color: AppColors.textPrimary,
  );
  
  static TextStyle subhead = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500, // Medium
    height: 24 / 16, // Line height 24pt / font size 16pt
    color: AppColors.textPrimary,
  );
  
  static TextStyle body = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
    height: 20 / 14, // Line height 20pt / font size 14pt
    color: AppColors.textPrimary,
  );
  
  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400, // Regular
    height: 16 / 12, // Line height 16pt / font size 12pt
    color: AppColors.textSecondary,
  );
  
  // Additional text styles for specific use cases
  static TextStyle bodySecondary = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: AppColors.textSecondary,
  );
  
  static TextStyle captionPrimary = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    color: AppColors.textPrimary,
  );
  
  static TextStyle buttonText = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600, // Semibold
    color: Colors.white,
  );
  
  static TextStyle tabActive = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600, // Semibold
    color: AppColors.primaryAccent,
  );
  
  static TextStyle tabInactive = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500, // Medium
    color: AppColors.textSecondary,
  );

  // Dark theme text styles
  static TextStyle get darkHeading1 => heading1.copyWith(color: AppColors.darkTextPrimary);
  static TextStyle get darkHeading2 => heading2.copyWith(color: AppColors.darkTextPrimary);
  static TextStyle get darkSubhead => subhead.copyWith(color: AppColors.darkTextPrimary);
  static TextStyle get darkBody => body.copyWith(color: AppColors.darkTextPrimary);
  static TextStyle get darkCaption => caption.copyWith(color: AppColors.darkTextSecondary);
  static TextStyle get darkBodySecondary => bodySecondary.copyWith(color: AppColors.darkTextSecondary);
  static TextStyle get darkCaptionPrimary => captionPrimary.copyWith(color: AppColors.darkTextPrimary);
  static TextStyle get darkTabActive => tabActive.copyWith(color: AppColors.primaryAccent);
  static TextStyle get darkTabInactive => tabInactive.copyWith(color: AppColors.darkTextSecondary);
}
