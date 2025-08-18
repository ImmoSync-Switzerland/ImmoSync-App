import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:immolink/core/providers/dynamic_colors_provider.dart';
import 'package:immolink/features/payment/domain/services/connect_service.dart';
import 'package:immolink/features/auth/presentation/providers/auth_provider.dart';
import 'package:immolink/features/payment/presentation/widgets/stripe_connect_onboarding_widget.dart';
import '../../../../../l10n/app_localizations.dart';

class LandlordConnectSetupPage extends ConsumerStatefulWidget {
  const LandlordConnectSetupPage({super.key});

  @override
  ConsumerState<LandlordConnectSetupPage> createState() => _LandlordConnectSetupPageState();
}

class _LandlordConnectSetupPageState extends ConsumerState<LandlordConnectSetupPage> {
  final ConnectService _connectService = ConnectService();
  bool _isLoading = false;
  Map<String, dynamic>? _accountStatus;

  @override
  void initState() {
    super.initState();
    _checkAccountStatus();
  }

  Future<void> _checkAccountStatus() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final status = await _connectService.getAccountStatus(user.id);
      setState(() {
        _accountStatus = status;
      });
    } catch (e) {
      print('Error checking account status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Payment Setup',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colors.surfaceCards,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(colors, l10n),
                const SizedBox(height: 24),
                _buildStatusCard(colors, l10n),
                const SizedBox(height: 24),
                _buildBenefitsCard(colors, l10n),
                const SizedBox(height: 32),
                _buildActionButton(colors, l10n, user),
              ],
            ),
          ),
    );
  }

  Widget _buildHeaderCard(DynamicAppColors colors, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primaryAccent.withValues(alpha: 0.1),
            colors.primaryAccent.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primaryAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primaryAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Receive Rent Payments',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'Set up your payment account to receive rent directly from tenants',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(DynamicAppColors colors, AppLocalizations l10n) {
    if (_accountStatus == null) return SizedBox();

    final hasAccount = _accountStatus!['hasAccount'] ?? false;
    final status = _accountStatus!['status'] ?? 'not_created';
    final chargesEnabled = _accountStatus!['chargesEnabled'] ?? false;

    Color statusColor = colors.textSecondary;
    IconData statusIcon = Icons.pending;
    String statusText = 'Not Set Up';

    if (hasAccount) {
      if (status == 'complete' && chargesEnabled) {
        statusColor = colors.success;
        statusIcon = Icons.check_circle;
        statusText = 'Active & Ready';
      } else {
        statusColor = colors.warning;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Setup In Progress';
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      hasAccount && status == 'pending' 
                        ? 'Complete your account setup to start receiving payments'
                        : hasAccount && chargesEnabled
                          ? 'Your account is ready to receive payments'
                          : 'Set up your payment account to get started',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsCard(DynamicAppColors colors, AppLocalizations l10n) {
    final benefits = [
      {
        'icon': Icons.flash_on,
        'title': 'Instant Payments',
        'description': 'Receive rent payments instantly via cards and bank transfers'
      },
      {
        'icon': Icons.security,
        'title': 'Secure & Reliable',
        'description': 'Bank-level security with automatic fraud protection'
      },
      {
        'icon': Icons.account_balance,
        'title': 'Multiple Payment Methods',
        'description': 'Accept cards, bank transfers, and instant payments'
      },
      {
        'icon': Icons.receipt_long,
        'title': 'Automatic Records',
        'description': 'All transactions are automatically tracked and recorded'
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Benefits',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...benefits.map((benefit) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    benefit['icon'] as IconData,
                    color: colors.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        benefit['title'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        benefit['description'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildActionButton(DynamicAppColors colors, AppLocalizations l10n, user) {
    if (_accountStatus == null) return SizedBox();

    final hasAccount = _accountStatus!['hasAccount'] ?? false;
    final status = _accountStatus!['status'] ?? 'not_created';
    final chargesEnabled = _accountStatus!['chargesEnabled'] ?? false;

    if (hasAccount) {
      if (status == 'complete' && chargesEnabled) {
        return _buildCompletedState(colors);
      } else {
        return _buildEmbeddedOnboarding(colors, user);
      }
    }

    return _buildCreateAccountButton(colors, user);
  }

  Widget _buildCreateAccountButton(DynamicAppColors colors, user) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _createAccount(user),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primaryAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Set Up Payment Account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildCompletedState(DynamicAppColors colors) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: colors.success,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Account Ready ✓',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmbeddedOnboarding(DynamicAppColors colors, user) {
    final accountId = _accountStatus!['accountId'] as String?;
    
    if (accountId == null) {
      return _buildCreateAccountButton(colors, user);
    }

    if (kIsWeb) {
      // Use embedded onboarding for web
      return Column(
        children: [
          const SizedBox(height: 24),
          StripeConnectOnboardingWidget(
            accountId: accountId,
            returnUrl: 'immolink://connect/return',
            refreshUrl: 'immolink://connect/refresh',
            customAppearance: {
              'colorPrimary': '#${(colors.primaryAccent.r * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.primaryAccent.g * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.primaryAccent.b * 255).round().toRadixString(16).padLeft(2, '0')}',
              'colorBackground': '#${(colors.primaryBackground.r * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.primaryBackground.g * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.primaryBackground.b * 255).round().toRadixString(16).padLeft(2, '0')}',
              'colorText': '#${(colors.textPrimary.r * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.textPrimary.g * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.textPrimary.b * 255).round().toRadixString(16).padLeft(2, '0')}',
            },
          ),
        ],
      );
    } else {
      // Use hosted onboarding for mobile
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : () => _completeSetup(user),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.warning,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.launch, size: 20),
              const SizedBox(width: 8),
              Text(
                'Complete Setup',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _createAccount(user) async {
    setState(() => _isLoading = true);

    try {
      final result = await _connectService.createConnectAccount(
        landlordId: user.id,
        email: user.email,
      );

      if (result['accountId'] != null) {
        await _startOnboarding(result['accountId']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating account: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeSetup(user) async {
    if (_accountStatus?['accountId'] != null) {
      await _startOnboarding(_accountStatus!['accountId']);
    }
  }

  Future<void> _startOnboarding(String accountId) async {
    try {
      final onboardingUrl = await _connectService.createOnboardingLink(
        accountId: accountId,
        returnUrl: 'immolink://connect/return',
        refreshUrl: 'immolink://connect/refresh',
      );

      final uri = Uri.parse(onboardingUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // Refresh status when user returns
        if (mounted) {
          Future.delayed(Duration(seconds: 2), () {
            _checkAccountStatus();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting onboarding: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
