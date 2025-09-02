import 'package:flutter/animation.dart';

/// Central motion & animation tokens for consistent UX.
class AppMotion {
  // Durations
  static const short = Duration(milliseconds: 120); // micro interactions
  static const medium = Duration(milliseconds: 220); // standard transitions
  static const long = Duration(milliseconds: 400); // modals / page transitions

  // Curves
  static const easeOut = Curves.easeOutCubic;
  static const easeIn = Curves.easeInCubic;
  static const easeInOut = Curves.easeInOutCubic;
  static const emphasized = Curves.fastEaseInToSlowEaseOut; // Material 3 like
}
