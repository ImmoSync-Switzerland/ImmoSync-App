import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const _bgTop = Color(0xFF0A1128);
  static const _card = Color(0xFF1C1C1E);
  static const _primaryBlue = Color(0xFF3B82F6);
  static const _accentCyan = Color(0xFF22D3EE);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _blobController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Bridge native splash -> Flutter animated splash.
    FlutterNativeSplash.remove();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutBack),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOut),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
      ),
    );

    _blobController.repeat();
    _introController.forward();

    _timer = Timer(const Duration(milliseconds: 3400), () {
      if (!mounted) return;
      context.go('/login');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _introController.dispose();
    _blobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(color: SplashScreen._bgTop),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: _RotatingGlowBlob(controller: _blobController),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _logoOpacity,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: _LogoContainer(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeTransition(
                      opacity: _textOpacity,
                      child: const Text(
                        'ImmoSync',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RotatingGlowBlob extends StatelessWidget {
  const _RotatingGlowBlob({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final angle = controller.value * 6.283185307179586; // 2*pi
          return Center(
            child: Transform.rotate(
              angle: angle,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(
                  width: 520,
                  height: 520,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFA78BFA).withValues(alpha: 0.14),
                        SplashScreen._primaryBlue.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LogoContainer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 164,
      height: 164,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SplashScreen._primaryBlue.withValues(alpha: 0.65),
            const Color(0xFFA78BFA).withValues(alpha: 0.45),
            Colors.white.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              SplashScreen._card.withValues(alpha: 0.92),
              SplashScreen._card.withValues(alpha: 0.78),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: SplashScreen._primaryBlue.withValues(alpha: 0.22),
              blurRadius: 26,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 34,
              offset: const Offset(0, 18),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
            width: 1,
          ),
        ),
        child: Center(
          child: Container(
            width: 126,
            height: 126,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              boxShadow: [
                BoxShadow(
                  color: SplashScreen._accentCyan.withValues(alpha: 0.20),
                  blurRadius: 28,
                  spreadRadius: -6,
                ),
              ],
            ),
            child: const Center(
              child: Image(
                image: AssetImage('assets/logo.png'),
                width: 72,
                height: 72,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
