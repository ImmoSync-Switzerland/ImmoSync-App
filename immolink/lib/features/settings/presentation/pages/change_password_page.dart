import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/domain/services/auth_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

const _bgTop = Color(0xFF0A1128);
const _bgBottom = Colors.black;
const _bentoCard = Color(0xFF1C1C1E);
const _requirementsSurface = Color(0xFF151517);
const _primaryBlue = Color(0xFF3B82F6);
const _primaryBlue2 = Color(0xFF2563EB);

const _inputFill = _bentoCard;
const _inputBorder = Colors.white10;

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

/// Backwards compatible wrapper (existing routes/imports).
class ChangePasswordPage extends ChangePasswordScreen {
  const ChangePasswordPage({super.key});
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_onNewPasswordChanged);
  }

  void _onNewPasswordChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _newPasswordController.removeListener(_onNewPasswordChanged);
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_bgTop, _bgBottom],
            ),
          ),
        ),
        title: Text(
          l10n.changePasswordPageTitle,
          style: AppTypography.pageTitle.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: topInset),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Container(
                decoration: BoxDecoration(
                  color: _bentoCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.changePasswordPageTitle,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.changePasswordSubtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Current Password Field
                      _buildPasswordField(
                        controller: _currentPasswordController,
                        label: l10n.changePasswordCurrentLabel,
                        obscureText: _obscureCurrentPassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscureCurrentPassword = !_obscureCurrentPassword;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.changePasswordCurrentRequired;
                          }
                          return null;
                        },
                        colors: colors,
                      ),
                      const SizedBox(height: 24),

                      // New Password Field
                      _buildPasswordField(
                        controller: _newPasswordController,
                        label: l10n.changePasswordNewLabel,
                        obscureText: _obscureNewPassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.changePasswordNewRequired;
                          }
                          if (value.length < 8) {
                            return l10n.changePasswordNewLength;
                          }
                          if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)')
                              .hasMatch(value)) {
                            return l10n.changePasswordNewComplexity;
                          }
                          return null;
                        },
                        colors: colors,
                      ),
                      const SizedBox(height: 16),

                      _buildPasswordRequirements(l10n),

                      const SizedBox(height: 24),

                      // Confirm Password Field
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        label: l10n.confirmNewPassword,
                        obscureText: _obscureConfirmPassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.changePasswordConfirmRequired;
                          }
                          if (value != _newPasswordController.text) {
                            return l10n.changePasswordConfirmMismatch;
                          }
                          return null;
                        },
                        colors: colors,
                      ),
                      const SizedBox(height: 32),

                      const SizedBox(height: 28),

                      _buildUpdateButton(l10n),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
    required DynamicAppColors colors,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: _inputFill,
        hintStyle: const TextStyle(color: Colors.white38),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: Colors.white70,
          ),
          onPressed: onToggleVisibility,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _inputBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.error, width: 1.2),
        ),
        errorStyle: TextStyle(
          color: colors.error,
          fontSize: 12,
          height: 1.2,
        ),
      ),
    );
  }

  bool get _meetsLength => _newPasswordController.text.length >= 8;

  bool get _hasUppercase =>
      RegExp(r'[A-Z]').hasMatch(_newPasswordController.text);

  bool get _hasLowercase =>
      RegExp(r'[a-z]').hasMatch(_newPasswordController.text);

  bool get _hasNumber => RegExp(r'\d').hasMatch(_newPasswordController.text);

  Widget _buildPasswordRequirements(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: _requirementsSurface,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.passwordRequirementsTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          _buildRequirementRow(l10n.passwordRequirementLength, _meetsLength),
          _buildRequirementRow(
              l10n.passwordRequirementUppercase, _hasUppercase),
          _buildRequirementRow(
              l10n.passwordRequirementLowercase, _hasLowercase),
          _buildRequirementRow(l10n.passwordRequirementNumbers, _hasNumber),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool met) {
    final Color color = met ? Colors.greenAccent : Colors.white60;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: met ? Colors.greenAccent : Colors.white30,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: color,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [_primaryBlue, _primaryBlue2],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _changePassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  l10n.changePasswordButton,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: -0.1,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    final colors = ref.read(dynamicColorsProvider);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser?.id == null) {
        throw Exception('User not logged in');
      }

      await _authService.changePassword(
        userId: currentUser!.id,
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.passwordChangedSuccessfully),
            backgroundColor: colors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppLocalizations.of(context)!.failedToChangePassword}: $e'),
            backgroundColor: colors.error,
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
}
