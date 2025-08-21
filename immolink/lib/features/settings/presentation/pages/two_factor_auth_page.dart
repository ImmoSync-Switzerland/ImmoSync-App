import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/config/db_config.dart';

class TwoFactorAuthPage extends ConsumerStatefulWidget {
  const TwoFactorAuthPage({super.key});

  @override
  ConsumerState<TwoFactorAuthPage> createState() => _TwoFactorAuthPageState();
}

class _TwoFactorAuthPageState extends ConsumerState<TwoFactorAuthPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _is2FAEnabled = false;
  String? _maskedPhone;
  bool _showVerification = false;
  bool _showDisableVerification = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _check2FAStatus();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _check2FAStatus() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${DbConfig.apiUrl}/auth/2fa/status/${currentUser.id}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _is2FAEnabled = data['enabled'] ?? false;
          _maskedPhone = data['phoneNumber'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to check 2FA status: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _setup2FA() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    if (_phoneController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your phone number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${DbConfig.apiUrl}/auth/2fa/setup-2fa'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': currentUser.id,
          'phoneNumber': _phoneController.text.trim(),
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _showVerification = true;
          _successMessage = data['message'];
        });
      } else {
        setState(() {
          _errorMessage = data['error'] ?? 'Failed to setup 2FA';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to setup 2FA: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verify2FASetup() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    if (_codeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the verification code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${DbConfig.apiUrl}/auth/2fa/verify-2fa-setup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': currentUser.id,
          'verificationCode': _codeController.text.trim(),
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _is2FAEnabled = true;
          _maskedPhone = data['phoneNumber'];
          _showVerification = false;
          _successMessage = data['message'];
        });
        _codeController.clear();
        _phoneController.clear();
      } else {
        setState(() {
          _errorMessage = data['error'] ?? 'Failed to verify 2FA';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to verify 2FA: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _disable2FA() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${DbConfig.apiUrl}/auth/2fa/disable'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': currentUser.id,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _showDisableVerification = true;
          _successMessage = data['message'];
        });
      } else {
        setState(() {
          _errorMessage = data['error'] ?? 'Failed to disable 2FA';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to disable 2FA: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyDisable2FA() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    if (_codeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the verification code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${DbConfig.apiUrl}/auth/2fa/disable'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': currentUser.id,
          'verificationCode': _codeController.text.trim(),
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _is2FAEnabled = false;
          _maskedPhone = null;
          _showDisableVerification = false;
          _successMessage = data['message'];
        });
        _codeController.clear();
      } else {
        setState(() {
          _errorMessage = data['error'] ?? 'Failed to disable 2FA';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to disable 2FA: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(dynamicColorsProvider);
    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        backgroundColor: colors.primaryBackground,
        elevation: 0,
        title: Text(
          'Two-Factor Authentication',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.primaryBackground, colors.surfaceCards],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(colors),
                    const SizedBox(height: 24),
                    if (_errorMessage != null) ...[
                      _buildErrorCard(colors),
                      const SizedBox(height: 16),
                    ],
                    if (_successMessage != null) ...[
                      _buildSuccessCard(colors),
                      const SizedBox(height: 16),
                    ],
                    if (!_is2FAEnabled) _buildSetupSection(colors),
                    if (_is2FAEnabled && !_showDisableVerification) _buildEnabledSection(colors),
                    if (_showVerification) _buildVerificationSection(colors),
                    if (_showDisableVerification) _buildDisableVerificationSection(colors),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatusCard(DynamicAppColors colors) {
    return Card(
      elevation: 4,
      color: colors.surfaceCards,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _is2FAEnabled ? Icons.security : Icons.security_outlined,
                  color: _is2FAEnabled ? colors.success : colors.warning,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Security Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _is2FAEnabled 
                    ? colors.success.withValues(alpha: 0.1)
                    : colors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _is2FAEnabled ? Icons.check_circle : Icons.warning,
                    color: _is2FAEnabled ? colors.success : colors.warning,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _is2FAEnabled ? '2FA Enabled' : '2FA Disabled',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (_is2FAEnabled && _maskedPhone != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Phone: $_maskedPhone',
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(DynamicAppColors colors) {
    return Card(
      color: colors.error.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.error, color: colors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(color: colors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard(DynamicAppColors colors) {
    return Card(
      color: colors.success.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: colors.success),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _successMessage!,
                style: TextStyle(color: colors.success),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupSection(DynamicAppColors colors) {
    return Card(
      elevation: 4,
      color: colors.surfaceCards,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Setup Two-Factor Authentication',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add an extra layer of security to your account by enabling SMS-based two-factor authentication.',
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: '+41 12 345 67 89',
                prefixIcon: Icon(Icons.phone, color: colors.primaryAccent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.primaryAccent),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _setup2FA,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primaryAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Send Verification Code',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textOnAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnabledSection(DynamicAppColors colors) {
    return Card(
      elevation: 4,
      color: colors.surfaceCards,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Two-Factor Authentication Enabled',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your account is protected with SMS-based two-factor authentication. You will receive a verification code on your registered phone number when logging in.',
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _disable2FA,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Disable 2FA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.error,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationSection(DynamicAppColors colors) {
    return Card(
      elevation: 4,
      color: colors.surfaceCards,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter Verification Code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'We sent a 6-digit verification code to your phone number. Enter it below to complete the 2FA setup.',
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Verification Code',
                hintText: '123456',
                prefixIcon: Icon(Icons.sms, color: colors.primaryAccent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.primaryAccent),
                ),
                counterText: '',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verify2FASetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primaryAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Verify and Enable 2FA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textOnAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisableVerificationSection(DynamicAppColors colors) {
    return Card(
      elevation: 4,
      color: colors.surfaceCards,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Disable Two-Factor Authentication',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'We sent a verification code to your phone number. Enter it below to disable 2FA.',
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Verification Code',
                hintText: '123456',
                prefixIcon: Icon(Icons.sms, color: colors.primaryAccent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.primaryAccent),
                ),
                counterText: '',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyDisable2FA,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Confirm Disable 2FA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textOnAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
