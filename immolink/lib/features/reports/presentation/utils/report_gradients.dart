import 'package:flutter/material.dart';

class ReportGradients {
  static LinearGradient glassAccent(Color accent, {required bool isDark}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        accent.withValues(alpha: isDark ? 0.85 : 0.90),
        accent.withValues(alpha: isDark ? 0.55 : 0.60),
        accent.withValues(alpha: isDark ? 0.28 : 0.32),
      ],
    );
  }

  static LinearGradient subtleSurface(Color base, {required bool isDark}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        base.withValues(alpha: isDark ? 0.12 : 0.18),
        base.withValues(alpha: isDark ? 0.06 : 0.10),
      ],
    );
  }

  static LinearGradient whiteShine() => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x33FFFFFF),
          Color(0x11FFFFFF),
          Color(0x05FFFFFF),
        ],
      );
}
