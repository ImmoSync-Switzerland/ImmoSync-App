import 'package:flutter/material.dart';

/// Global app background used across screens.
///
/// Wrap route content with this to render the deep navy → black gradient
/// behind every page.
class AppGradientBackground extends StatelessWidget {
  const AppGradientBackground({super.key, required this.child});

  static const Color top = Color(0xFF0A1128);
  static const Color bottom = Colors.black;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ),
      ),
      child: child,
    );
  }
}
