import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/features/auth/presentation/providers/register_provider.dart';
import 'package:immosync/l10n/app_localizations.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  static const _bgTop = Color(0xFF0A1128);
  static const _bgBottom = Colors.black;
  static const _card = Color(0xFF1C1C1E);
  static const _field = Color(0xFF2C2C2E);
  static const _primaryBlue = Color(0xFF3B82F6);
  static const _accentCyan = Color(0xFF22D3EE);

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  String _selectedRole = 'landlord';

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final registerState = ref.watch(registerProvider);

    ref.listen<RegisterState>(registerProvider, (previous, current) {
      if (!mounted) return;

      if (current.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.accountCreatedPleaseSignIn),
            backgroundColor: Colors.green.withValues(alpha: 0.85),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/login');
      }

      if (current.error != null && !current.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_formatErrorMessage(current.error!)),
            backgroundColor: Colors.red.withValues(alpha: 0.85),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [SignUpScreen._bgTop, SignUpScreen._bgBottom],
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
                              const Spacer(),
                              Center(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 460),
                                  child: BentoCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _buildHeader(),
                                        const SizedBox(height: 18),
                                        _buildRoleSelector(),
                                        const SizedBox(height: 16),
                                        _buildField(
                                          controller: _fullNameController,
                                          hintText: l10n.fullName,
                                          prefixIcon: Icons.person_outline,
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return l10n.fullNameRequired;
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 14),
                                        _buildField(
                                          controller: _emailController,
                                          hintText: l10n.emailAddress,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          prefixIcon: Icons.email_outlined,
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return l10n.emailRequired;
                                            }
                                            if (!value.contains('@')) {
                                              return l10n.enterValidEmail;
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 14),
                                        _buildField(
                                          controller: _passwordController,
                                          hintText: l10n.password,
                                          prefixIcon: Icons.lock_outline,
                                          obscureText: !_isPasswordVisible,
                                          suffix: IconButton(
                                            icon: Icon(
                                              _isPasswordVisible
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                            ),
                                            color: Colors.white54,
                                            onPressed: () {
                                              setState(() {
                                                _isPasswordVisible =
                                                    !_isPasswordVisible;
                                              });
                                            },
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return l10n.passwordRequired;
                                            }
                                            if (value.trim().length < 6) {
                                              return l10n.passwordMinLength;
                                            }
                                            return null;
                                          },
                                        ),
                                        if (registerState.error != null) ...[
                                          const SizedBox(height: 12),
                                          _InlineErrorCard(
                                            message: _formatErrorMessage(
                                                registerState.error!),
                                          ),
                                        ],
                                        const SizedBox(height: 16),
                                        if (registerState.isLoading)
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 6),
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                                color:
                                                    SignUpScreen._primaryBlue,
                                              ),
                                            ),
                                          )
                                        else
                                          GradientButton(
                                            text: l10n.signUp,
                                            onPressed: _handleSignUp,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              _buildFooter(),
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

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: SignUpScreen._field,
            boxShadow: [
              BoxShadow(
                color: SignUpScreen._primaryBlue.withValues(alpha: 0.35),
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
                    color: SignUpScreen._primaryBlue,
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.signUpTitle,
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
          l10n.signUpSubtitle,
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

  Widget _buildRoleSelector() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _RoleChip(
            label: l10n.landlord,
            selected: _selectedRole == 'landlord',
            onTap: () => setState(() => _selectedRole = 'landlord'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _RoleChip(
            label: l10n.tenant,
            selected: _selectedRole == 'tenant',
            onTap: () => setState(() => _selectedRole = 'tenant'),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: SignUpScreen._field,
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Colors.white54,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        prefixIcon: Icon(prefixIcon),
        prefixIconColor: Colors.white54,
        suffixIcon: suffix,
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
    );
  }

  Widget _buildFooter() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.alreadyHaveAccount,
            style: const TextStyle(
              color: Colors.white60,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          TextButton(
            onPressed: () => context.go('/login'),
            style: TextButton.styleFrom(
              foregroundColor: SignUpScreen._primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            child: Text(l10n.signIn),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(registerProvider.notifier).register(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _selectedRole,
          // Existing backend flow expects these fields; keep minimal defaults.
          phone: '',
          isCompany: false,
        );
  }

  String _formatErrorMessage(String error) {
    final l10n = AppLocalizations.of(context)!;
    final clean = error.replaceFirst('Exception: ', '').trim();
    if (clean.contains('Invalid') || clean.contains('400')) {
      return l10n.signUpFailedCheckDetails;
    }
    if (clean.toLowerCase().contains('network') ||
        clean.toLowerCase().contains('socket') ||
        clean.toLowerCase().contains('connection')) {
      return l10n.networkErrorCheckConnection;
    }
    return clean.isNotEmpty ? clean : l10n.signUpFailedTryAgain;
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? SignUpScreen._primaryBlue : SignUpScreen._field;
    final fg = selected ? Colors.white : Colors.white60;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: selected ? 0.12 : 0.08),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class BentoCard extends StatelessWidget {
  const BentoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.14),
            Colors.white.withValues(alpha: 0.06),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: SignUpScreen._card,
            borderRadius: BorderRadius.circular(24),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [SignUpScreen._primaryBlue, SignUpScreen._accentCyan],
          ),
          boxShadow: [
            BoxShadow(
              color: SignUpScreen._primaryBlue.withValues(alpha: 0.30),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
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

class _InlineErrorCard extends StatelessWidget {
  const _InlineErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: Colors.redAccent.withValues(alpha: 0.95),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
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
            alignment: Alignment(-0.9, -0.55),
            size: 360,
            colorA: Color(0xFF4F46E5),
            colorB: Color(0xFF0EA5E9),
          ),
          _GlowBlob(
            alignment: Alignment(0.85, -0.35),
            size: 300,
            colorA: Color(0xFF9333EA),
            colorB: Color(0xFF2563EB),
          ),
          _GlowBlob(
            alignment: Alignment(0.15, 0.85),
            size: 340,
            colorA: Color(0xFF0EA5E9),
            colorB: Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.alignment,
    required this.size,
    required this.colorA,
    required this.colorB,
  });

  final Alignment alignment;
  final double size;
  final Color colorA;
  final Color colorB;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ClipOval(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  colorA.withValues(alpha: 0.45),
                  colorB.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
