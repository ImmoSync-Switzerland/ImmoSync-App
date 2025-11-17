import 'package:flutter/material.dart';
import 'package:immosync/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/core/providers/dynamic_colors_provider.dart';
import 'package:immosync/features/payment/domain/services/connect_service.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/payment/presentation/widgets/stripe_connect_payments_dashboard.dart';

class LandlordConnectDashboardPage extends ConsumerStatefulWidget {
  const LandlordConnectDashboardPage({super.key});

  @override
  ConsumerState<LandlordConnectDashboardPage> createState() =>
      _LandlordConnectDashboardPageState();
}

class _LandlordConnectDashboardPageState
    extends ConsumerState<LandlordConnectDashboardPage>
    with SingleTickerProviderStateMixin {
  final ConnectService _connectService = ConnectService();
  late TabController _tabController;
  bool _isLoading = false;
  Map<String, dynamic>? _accountStatus;

  final List<Map<String, dynamic>> _dashboardTabs = [
    {
      'title': 'Payments',
      'icon': Icons.payment,
      'component': 'payments',
      'description': 'View and manage rent payments',
    },
    {
      'title': 'Payouts',
      'icon': Icons.account_balance_wallet,
      'component': 'payouts',
      'description': 'Track payouts and balance',
    },
    {
      'title': 'Balance',
      'icon': Icons.account_balance,
      'component': 'balances',
      'description': 'View account balance details',
    },
    {
      'title': 'Settings',
      'icon': Icons.settings,
      'component': 'account_management',
      'description': 'Manage account settings',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _dashboardTabs.length, vsync: this);
    _checkAccountStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Payment Dashboard',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colors.surfaceCards,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        bottom: _buildAccountReady()
            ? TabBar(
                controller: _tabController,
                labelColor: colors.primaryAccent,
                unselectedLabelColor: colors.textSecondary,
                indicatorColor: colors.primaryAccent,
                tabs: _dashboardTabs
                    .map((tab) => Tab(
                          icon: Icon(tab['icon']),
                          text: tab['title'],
                        ))
                    .toList(),
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(colors, l10n, user),
    );
  }

  bool _buildAccountReady() {
    if (_accountStatus == null) return false;
    final hasAccount = _accountStatus!['hasAccount'] ?? false;
    final status = _accountStatus!['status'] ?? 'not_created';
    final chargesEnabled = _accountStatus!['chargesEnabled'] ?? false;

    return hasAccount && status == 'complete' && chargesEnabled;
  }

  Widget _buildBody(DynamicAppColors colors, AppLocalizations l10n, user) {
    if (!_buildAccountReady()) {
      return _buildAccountNotReady(colors, l10n);
    }

    final accountId = _accountStatus!['accountId'] as String?;
    if (accountId == null) {
      return _buildErrorState(colors, 'Account ID not found');
    }

    return TabBarView(
      controller: _tabController,
      children: _dashboardTabs.map((tab) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTabHeader(colors, tab),
              const SizedBox(height: 16),
              StripeConnectPaymentsDashboard(
                accountId: accountId,
                componentType: tab['component'],
                customAppearance: {
                  'colorPrimary':
                      '#${(colors.primaryAccent.r * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.primaryAccent.g * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.primaryAccent.b * 255).round().toRadixString(16).padLeft(2, '0')}',
                  'colorBackground':
                      '#${(colors.primaryBackground.r * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.primaryBackground.g * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.primaryBackground.b * 255).round().toRadixString(16).padLeft(2, '0')}',
                  'colorText':
                      '#${(colors.textPrimary.r * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.textPrimary.g * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.textPrimary.b * 255).round().toRadixString(16).padLeft(2, '0')}',
                  'borderRadius': '12px',
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTabHeader(DynamicAppColors colors, Map<String, dynamic> tab) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primaryAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              tab['icon'],
              color: colors.primaryAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tab['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  tab['description'],
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
    );
  }

  Widget _buildAccountNotReady(DynamicAppColors colors, AppLocalizations l10n) {
    final hasAccount = _accountStatus?['hasAccount'] ?? false;
    final status = _accountStatus?['status'] ?? 'not_created';

    String title = 'Set Up Payment Account';
    String description =
        'Complete your account setup to access the payment dashboard';
    IconData icon = Icons.account_balance;
    final Color iconColor = colors.warning;

    if (hasAccount && status == 'pending') {
      title = 'Complete Account Setup';
      description =
          'Finish your account verification to start receiving payments';
      icon = Icons.hourglass_empty;
    } else if (!hasAccount) {
      title = 'Create Payment Account';
      description = 'Set up your Stripe Connect account to manage payments';
      icon = Icons.add_business;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/connect/setup');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryAccent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_forward, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  Widget _buildErrorState(DynamicAppColors colors, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colors.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Dashboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _checkAccountStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryAccent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ),
    );
  }
}
