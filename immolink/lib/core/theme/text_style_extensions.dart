import 'package:flutter/material.dart';

/// Extension to ensure consistent TextStyle properties for smooth theme transitions
extension TextStyleExtensions on TextStyle {
  /// Creates a TextStyle with explicit inherit: false to prevent interpolation issues
  TextStyle get noInherit => copyWith(inherit: false);

  /// Creates a TextStyle with explicit inherit: true for theme compatibility
  TextStyle get withInherit => copyWith(inherit: true);
}

/// Helper class to create TextStyles with consistent inherit properties
class ThemeTextStyle {
  /// Creates a TextStyle with inherit: false to prevent interpolation errors
  static TextStyle create({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
    String? fontFamily,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
      fontFamily: fontFamily,
      inherit: false, // Explicit inherit to prevent interpolation issues
    );
  }
}
