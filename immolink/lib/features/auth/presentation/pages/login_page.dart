import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();
  String? _currentError; // Track current error message
  bool _isShowingErrorDialog = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    ref.listen<AuthState>(authProvider, (previous, current) {
      print(
          'LoginPage: Auth state changed - isAuth=${current.isAuthenticated}, error=${current.error}, loading=${current.isLoading}');
      print(
          'LoginPage: _isShowingErrorDialog=$_isShowingErrorDialog, mounted=$mounted');

      if (current.isAuthenticated) {
        print('LoginPage: User authenticated, navigating to /home');
        // Clear any previous error
        setState(() {
          _currentError = null;
        });
        if (mounted) {
          context.go('/home'); // Navigate when authenticated
        }
      } else if (current.error != null && !current.isLoading) {
        // Set error state to display inline
        print('LoginPage: Setting error state: ${current.error}');
        print('LoginPage: _currentError before setState: $_currentError');
        setState(() {
          _currentError = current.error;
        });
        print('LoginPage: _currentError after setState: $_currentError');

        // Also try dialog if mounted and not already showing
        if (mounted && !_isShowingErrorDialog) {
          print('LoginPage: Showing error dialog for: ${current.error}');
          _isShowingErrorDialog = true;

          // Show a SnackBar as a fallback if dialog doesn't work
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login failed: ${current.error}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );

          _showErrorDialog(context, current.error!);
        }
      } else if (current.isLoading) {
        // Clear error when starting new login attempt
        setState(() {
          _currentError = null;
        });
      } else if (current.error != null) {
        print(
            'LoginPage: Error exists but not showing dialog - loading: ${current.isLoading}, _isShowingErrorDialog: $_isShowingErrorDialog, mounted: $mounted');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF), // Pure white
              Color(0xFFF0F4FF), // Very light blue
              Color(0xFFE0EAFF), // Light blue
              Color(0xFFD1E0FF), // Soft blue
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 48),
                      _buildLoginCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.home_work,
                      size: 40,
                      color: Color(0xFF2563EB),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ImmoSync',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B), // Dark slate
                letterSpacing: -1,
              ),
            ),
            const Text(
              'Your Property Management Solution',
              style: TextStyle(
                color: Color(0xFF64748B), // Slate gray
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    final authState = ref.watch(authProvider);
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Willkommen zurück',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Melden Sie sich bei Ihrem Konto an',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),
            _buildTextField(
              controller: _emailController,
              icon: Icons.email_outlined,
              label: 'E-Mail',
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _passwordController,
              icon: Icons.lock_outline,
              label: 'Passwort',
              isPassword: true,
            ),
            const SizedBox(height: 16),
            if (_currentError != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.shade400,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade200.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade600,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Anmeldung fehlgeschlagen',
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatErrorMessage(_currentError!),
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            _buildForgotPassword(),
            const SizedBox(height: 32),
            if (authState.isLoading)
              Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryAccent,
                  strokeWidth: 3,
                ),
              )
            else
              _buildLoginButton(),
            const SizedBox(height: 24),
            _buildDivider(),
            const SizedBox(height: 24),
            _buildSocialLogin(),
            const SizedBox(height: 24),
            _buildRegisterLink(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Dieses Feld ist erforderlich';
        }
        if (label == 'E-Mail' && !value.contains('@')) {
          return 'Bitte geben Sie eine gültige E-Mail-Adresse ein';
        }
        return null;
      },
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : null,
        labelText: label,
        labelStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: AppColors.textPlaceholder,
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppColors.primaryBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.borderLight, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primaryAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        errorStyle: TextStyle(
          color: AppColors.error,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2563EB), // Royal blue
            Color(0xFF1D4ED8), // Deeper blue
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            print('LoginPage: Login button pressed - calling auth provider');
            print(
                'LoginPage: Login attempt with: ${_emailController.text}'); // Debug log

            await ref.read(authProvider.notifier).login(
                  _emailController.text,
                  _passwordController.text,
                );

            if (mounted) {
              print('LoginPage: Auth provider login call completed');
            } else {
              print('LoginPage: Widget unmounted after login call');
            }
          } else {
            print('LoginPage: Form validation failed');
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Anmelden',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          context.push('/forgot-password');
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Passwort vergessen?',
          style: TextStyle(
            color: AppColors.primaryAccent,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.borderLight, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Oder fortfahren mit',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.borderLight, thickness: 1)),
      ],
    );
  }

  Widget _buildSocialLogin() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialButton(
          icon: FontAwesomeIcons.google,
          onPressed: _handleGoogle,
        ),
        const SizedBox(width: 16),
        // Apple login temporarily removed
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: FaIcon(
          icon,
          color: Colors.grey.shade700,
          size: 20,
        ),
      ),
    );
  }

  Future<void> _handleGoogle() async {
    // Request an ID token by providing the OAuth2 Web Client ID from env
    final clientId = dotenv.dotenv.env['GOOGLE_CLIENT_ID'];
    final googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: (clientId != null && clientId.isNotEmpty) ? clientId : null,
    );
    try {
      final account = await googleSignIn.signIn();
      if (account == null) return; // canceled
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        setState(() {
          _currentError = (clientId == null || clientId.isEmpty)
              ? 'Google Sign-In fehlgeschlagen: GOOGLE_CLIENT_ID fehlt in .env'
              : 'Google Sign-In fehlgeschlagen (kein Token)';
        });
        return;
      }
      await ref
          .read(authProvider.notifier)
          .socialLogin(provider: 'google', idToken: idToken);
      final st = ref.read(authProvider);
      if (st.needsProfileCompletion && mounted) {
        context.push('/complete-profile');
      }
    } catch (e) {
      setState(() {
        _currentError = 'Google Sign-In Fehler: $e';
      });
    }
  }

  // Apple login handler removed temporarily

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Noch kein Konto?',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: () => context.push('/register'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Registrieren',
            style: TextStyle(
              color: AppColors.primaryAccent,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _showErrorDialog(BuildContext context, String error) {
    print('LoginPage: _showErrorDialog called with error: $error');
    print(
        'LoginPage: Context is valid: ${context.mounted}, Widget mounted: $mounted');

    if (!mounted) {
      print('LoginPage: Widget not mounted, skipping dialog');
      _isShowingErrorDialog = false;
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        print('LoginPage: Dialog builder called - creating dialog widget');
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFFEF2F2),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Color(0xFFDC2626),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Anmeldung fehlgeschlagen',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _formatErrorMessage(error),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _isShowingErrorDialog = false;
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Erneut versuchen',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      // Reset flag when dialog is dismissed by any means
      print('LoginPage: Error dialog dismissed, resetting flag');
      _isShowingErrorDialog = false;
    });
  }

  String _formatErrorMessage(String error) {
    // Remove "Exception: " prefix if present
    String cleanError = error.replaceFirst('Exception: ', '');

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
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
