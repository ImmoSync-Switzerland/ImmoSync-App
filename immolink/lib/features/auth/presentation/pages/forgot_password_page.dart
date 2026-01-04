import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/features/auth/domain/services/auth_service.dart';
import 'package:immosync/l10n/app_localizations.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  static const _bgTop = Color(0xFF0A1128);
  static const _bgBottom = Colors.black;
  static const _card = Color(0xFF1C1C1E);
  static const _field = Color(0xFF2C2C2E);
  static const _primaryBlue = Color(0xFF3B82F6);
  static const _accentCyan = Color(0xFF22D3EE);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.forgotPassword(email: _emailController.text.trim());

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.passwordResetEmailSent ??
                  'Password reset email sent! Please check your inbox.',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green.withValues(alpha: 0.85),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.withValues(alpha: 0.85),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: _GlowBlobs()),
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  onPressed: () => context.pop(),
                                  icon: const Icon(Icons.arrow_back_rounded),
                                  color: Colors.white70,
                                  tooltip: MaterialLocalizations.of(context)
                                      .backButtonTooltip,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Center(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 460),
                                  child: BentoCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _buildHeader(l10n),
                                        const SizedBox(height: 18),
                                        _buildEmailField(l10n),
                                        const SizedBox(height: 16),
                                        if (_isLoading)
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 6),
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                                color: _primaryBlue,
                                              ),
                                            ),
                                          )
                                        else
                                          GradientButton(
                                            text: l10n?.sendResetEmail ??
                                                'Send Reset Email',
                                            onPressed: _sendResetEmail,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              _buildFooter(l10n),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _field,
            boxShadow: [
              BoxShadow(
                color: _primaryBlue.withValues(alpha: 0.35),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          child: Center(
            child: ClipOval(
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 46,
                height: 46,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.home_work_rounded,
                    size: 36,
                    color: _primaryBlue,
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n?.forgotPasswordTitle ?? 'Forgot Password?',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n?.forgotPasswordDescription ??
              'Enter your email address and we\'ll send you a link to reset your password.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white60,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(AppLocalizations? l10n) {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: _field,
        hintText: l10n?.email ?? 'Email',
        hintStyle: const TextStyle(
          color: Colors.white54,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        prefixIcon: const Icon(Icons.email_outlined),
        prefixIconColor: Colors.white54,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(
          color: Color(0xFFFCA5A5),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n?.pleaseEnterYourEmail ?? 'Please enter your email';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
            .hasMatch(value.trim())) {
          return l10n?.pleaseEnterValidEmail ??
              'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildFooter(AppLocalizations? l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: TextButton(
        onPressed: () => context.pop(),
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        child: Text(
          l10n?.backToLogin ?? 'Back to Login',
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class BentoCard extends StatelessWidget {
  const BentoCard({super.key, required this.child});
  final Widget child;

  static const _radius = 24.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _ForgotPasswordPageState._card.withValues(alpha: 0.92),
            _ForgotPasswordPageState._card.withValues(alpha: 0.78),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: child,
          ),
        ),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  const GradientButton(
      {super.key, required this.text, required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              _ForgotPasswordPageState._primaryBlue,
              _ForgotPasswordPageState._accentCyan
            ],
          ),
          boxShadow: [
            BoxShadow(
              color:
                  _ForgotPasswordPageState._primaryBlue.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowBlobs extends StatelessWidget {
  const _GlowBlobs();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(
        children: [
          _GlowBlob(
            alignment: Alignment(-0.9, -0.8),
            color: _ForgotPasswordPageState._primaryBlue,
            size: 320,
            blur: 70,
            opacity: 0.22,
          ),
          _GlowBlob(
            alignment: Alignment(0.9, -0.6),
            color: _ForgotPasswordPageState._accentCyan,
            size: 280,
            blur: 70,
            opacity: 0.18,
          ),
          _GlowBlob(
            alignment: Alignment(0.0, 0.95),
            color: Color(0xFFA78BFA),
            size: 360,
            blur: 90,
            opacity: 0.16,
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.alignment,
    required this.color,
    required this.size,
    required this.blur,
    required this.opacity,
  });

  final Alignment alignment;
  final Color color;
  final double size;
  final double blur;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
