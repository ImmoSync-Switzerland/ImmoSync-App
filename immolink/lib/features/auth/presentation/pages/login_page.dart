import 'dart:ui';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:immosync/core/config/db_config.dart';
import 'package:immosync/l10n/app_localizations.dart';

import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return const LoginScreen();
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const _bgTop = Color(0xFF0A1128);
  static const _bgBottom = Colors.black;
  static const _card = Color(0xFF1C1C1E);
  static const _field = Color(0xFF2C2C2E);
  static const _primaryBlue = Color(0xFF3B82F6);
  static const _accentCyan = Color(0xFF22D3EE);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();
  String? _currentError; // Track current error message

  bool _snackShownForThisError = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Listen to auth state changes
    ref.listen<AuthState>(authProvider, (previous, current) {
      if (current.isAuthenticated) {
        setState(() {
          _currentError = null;
        });
        if (mounted) {
          context.go('/home'); // Navigate when authenticated
        }
      } else if (current.needsProfileCompletion && !current.isLoading) {
        setState(() {
          _currentError = null;
        });
        if (mounted) {
          context.go('/complete-profile');
        }
      } else if (current.error != null && !current.isLoading) {
        setState(() {
          _currentError = current.error;
        });

        if (mounted && !_snackShownForThisError) {
          _snackShownForThisError = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_formatErrorMessage(current.error!)),
              backgroundColor: Colors.red.withValues(alpha: 0.85),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (current.isLoading) {
        // Clear error when starting new login attempt
        _snackShownForThisError = false;
        setState(() {
          _currentError = null;
        });
      }
    });

    final authState = ref.watch(authProvider);
    final bool showApple =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final bool showGoogle =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [LoginScreen._bgTop, LoginScreen._bgBottom],
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
                                      const BoxConstraints(maxWidth: 440),
                                  child: BentoCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _buildBrandingHeader(),
                                        const SizedBox(height: 22),
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
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 10),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () => context
                                                .push('/forgot-password'),
                                            style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 6),
                                              foregroundColor: Colors.white70,
                                              textStyle: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                            child:
                                                Text(l10n.forgotPasswordTitle),
                                          ),
                                        ),
                                        if (_currentError != null) ...[
                                          const SizedBox(height: 10),
                                          _InlineErrorCard(
                                            message: _formatErrorMessage(
                                                _currentError!),
                                          ),
                                        ],
                                        const SizedBox(height: 16),
                                        if (authState.isLoading)
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 6),
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                                color: LoginScreen._primaryBlue,
                                              ),
                                            ),
                                          )
                                        else
                                          GradientButton(
                                            text: l10n.signIn,
                                            onPressed: _handleSignIn,
                                          ),
                                        if (!authState.isLoading)
                                          ..._buildSocialButtons(
                                            showApple: showApple,
                                            showGoogle: showGoogle,
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

  Widget _buildBrandingHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: LoginScreen._field,
            boxShadow: [
              BoxShadow(
                color: LoginScreen._primaryBlue.withValues(alpha: 0.35),
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
                    color: LoginScreen._primaryBlue,
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.welcomeBackTitle,
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
          l10n.signInToManageYourProperties,
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
        fillColor: LoginScreen._field,
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
            '${l10n.dontHaveAccount} ',
            style: const TextStyle(
              color: Colors.white60,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          TextButton(
            onPressed: () => context.push('/register'),
            style: TextButton.styleFrom(
              foregroundColor: LoginScreen._primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            child: Text(l10n.createOne),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    _snackShownForThisError = false;
    await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  List<Widget> _buildSocialButtons({
    required bool showApple,
    required bool showGoogle,
  }) {
    if (!showApple && !showGoogle) return const [];

    final l10n = AppLocalizations.of(context)!;

    return [
      const SizedBox(height: 12),
      if (showApple)
        SocialButton(
          text: l10n.signInWithApple,
          icon: FontAwesomeIcons.apple,
          onPressed: _handleAppleSignIn,
        ),
      if (showGoogle)
        SocialButton(
          text: l10n.signInWithGoogle,
          icon: FontAwesomeIcons.google,
          onPressed: _handleGoogleSignIn,
        ),
    ];
  }

  Future<void> _handleGoogleSignIn() async {
    _snackShownForThisError = false;

    try {
      final String googleClientId = DbConfig.googleClientId;
      if (googleClientId.isEmpty) {
        throw Exception(
            'Google Sign-In is not configured. Set GOOGLE_CLIENT_ID (Web client ID) via .env or --dart-define.');
      }

      debugPrint(
          '[LoginScreen] Starting Google Sign-In (clientId=${googleClientId.substring(0, 12)}...)');
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile', 'openid'],
        // For Android, this must be the Web client ID (OAuth 2.0 client ID)
        // so that an ID token can be issued for backend verification.
        serverClientId: googleClientId,
      );

      // Helps ensure account picker shows reliably and avoids stale sessions.
      await googleSignIn.signOut();
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) return; // user cancelled

      debugPrint('[LoginScreen] GoogleSignIn account: ${account.email}');
      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;
      debugPrint(
          '[LoginScreen] GoogleSignIn returned idToken=${idToken != null && idToken.isNotEmpty}');
      if (idToken == null || idToken.isEmpty) {
        throw Exception(
            'Google Sign-In did not return an ID token. Verify GOOGLE_CLIENT_ID is the Web client ID and that the correct SHA-1/SHA-256 fingerprints are registered in Google/Firebase for this Android app.');
      }

      if (kDebugMode) {
        final claims = _tryDecodeJwtClaims(idToken);
        if (claims != null) {
          debugPrint(
              '[LoginScreen] Google idToken claims aud=${claims['aud']} iss=${claims['iss']} azp=${claims['azp']}');
        }
      }

      debugPrint(
          '[LoginScreen] Calling backend socialLogin(provider=google, tokenLen=${idToken.length})');
      await ref.read(authProvider.notifier).socialLogin(
            provider: 'google',
            idToken: idToken,
          );
      debugPrint('[LoginScreen] socialLogin(provider=google) completed');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_formatErrorMessage(_formatGoogleSignInError(e))),
          backgroundColor: Colors.red.withValues(alpha: 0.85),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatGoogleSignInError(Object error) {
    if (error is PlatformException) {
      final String message = error.message ?? error.toString();

      // Common Google Sign-In Android errors:
      // - ApiException: 10 => DEVELOPER_ERROR (wrong SHA1/SHA256 or wrong client id/package)
      // - 12500 => sign in failed (often misconfigured OAuth client / SHA)
      if (message.contains('ApiException: 10') || message.contains('12500')) {
        return 'Google Sign-In ist nicht korrekt konfiguriert (OAuth/SHA-Fingerprints). Bitte prüfen: Android Paketname (ch.immosync.app), SHA-1/SHA-256 im Firebase/Google Console, und GOOGLE_CLIENT_ID = Web Client ID.';
      }

      if (error.code == 'sign_in_canceled') {
        return 'Google Sign-In abgebrochen.';
      }
      return message;
    }
    return error.toString();
  }

  Map<String, dynamic>? _tryDecodeJwtClaims(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length < 2) return null;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final obj = jsonDecode(decoded);
      if (obj is Map<String, dynamic>) return obj;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleAppleSignIn() async {
    _snackShownForThisError = false;

    try {
      final AuthorizationCredentialAppleID credential =
          await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final String? idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Apple Sign-In failed: missing identity token');
      }

      await ref.read(authProvider.notifier).socialLogin(
            provider: 'apple',
            idToken: idToken,
          );
    } on SignInWithAppleAuthorizationException catch (e) {
      // If user cancels, don't show an error.
      if (e.code == AuthorizationErrorCode.canceled) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_formatErrorMessage(e.message)),
          backgroundColor: Colors.red.withValues(alpha: 0.85),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_formatErrorMessage(e.toString())),
          backgroundColor: Colors.red.withValues(alpha: 0.85),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatErrorMessage(String error) {
    // Remove "Exception: " prefix if present
    final String cleanError = error.replaceFirst('Exception: ', '');

    // Clean up common error messages to be more user-friendly
    if (cleanError.contains('Invalid credentials') ||
        cleanError.contains('401')) {
      return 'Ungültige E-Mail oder Passwort. Bitte überprüfen Sie Ihre Zugangsdaten und versuchen Sie es erneut.';
    } else if (cleanError.contains('Network') ||
        cleanError.contains('connection') ||
        cleanError.contains('Connection refused')) {
      return 'Netzwerkfehler. Bitte überprüfen Sie Ihre Internetverbindung und versuchen Sie es erneut.';
    } else if (cleanError.contains('timeout')) {
      return 'Zeitüberschreitung der Anfrage. Bitte versuchen Sie es erneut.';
    } else if (cleanError.contains('SocketException')) {
      return 'Verbindung zum Server fehlgeschlagen. Bitte überprüfen Sie Ihre Internetverbindung.';
    } else if (cleanError.toLowerCase().contains('login failed')) {
      return 'Anmeldung fehlgeschlagen. Bitte überprüfen Sie Ihre E-Mail und Ihr Passwort.';
    } else {
      return cleanError.isNotEmpty
          ? cleanError
          : 'Anmeldung fehlgeschlagen. Bitte versuchen Sie es erneut.';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
            color: LoginScreen._card,
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
            colors: [LoginScreen._primaryBlue, LoginScreen._accentCyan],
          ),
          boxShadow: [
            BoxShadow(
              color: LoginScreen._primaryBlue.withValues(alpha: 0.30),
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

class SocialButton extends StatelessWidget {
  const SocialButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: LoginScreen._field,
          foregroundColor: Colors.white,
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.10),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        ),
        icon: Icon(icon, size: 18),
        label: Text(text),
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
