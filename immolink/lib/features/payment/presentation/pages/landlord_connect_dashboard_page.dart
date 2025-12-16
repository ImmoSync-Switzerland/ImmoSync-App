import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/core/providers/dynamic_colors_provider.dart';
import 'package:immosync/features/payment/domain/services/connect_service.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/payment/presentation/widgets/stripe_connect_payments_dashboard.dart';
import 'package:immosync/features/home/presentation/models/dashboard_design.dart';
import 'package:immosync/features/home/presentation/pages/glass_dashboard_shared.dart';
import 'package:immosync/features/settings/providers/settings_provider.dart';

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
    final design = dashboardDesignFromId(
      ref.watch(settingsProvider).dashboardDesign,
    );
    final bool glassMode = design == DashboardDesign.glass;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final Widget body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _buildBody(colors, l10n, user, glassMode: glassMode);

    if (glassMode) {
      return GlassPageScaffold(
        title: 'Payment Dashboard',
        showBottomNav: false,
        onBack: () => context.go('/landlord/payments'),
        body: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: body,
        ),
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
                    .map(
                      (tab) => Tab(
                        icon: Icon(tab['icon']),
                        text: tab['title'],
                      ),
                    )
                    .toList(),
              )
            : null,
      ),
      body: body,
    );
  }

  bool _buildAccountReady() {
    if (_accountStatus == null) return false;
    final hasAccount = _accountStatus!['hasAccount'] ?? false;
    final status = _accountStatus!['status'] ?? 'not_created';
    final chargesEnabled = _accountStatus!['chargesEnabled'] ?? false;

    return hasAccount && status == 'complete' && chargesEnabled;
  }

  Widget _buildBody(
    DynamicAppColors colors,
    AppLocalizations l10n,
    user, {
    required bool glassMode,
  }) {
    if (!_buildAccountReady()) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: _buildAccountNotReady(
            colors,
            l10n,
            glassMode: glassMode,
          ),
        ),
      );
    }

    final accountId = _accountStatus!['accountId'] as String?;
    if (accountId == null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: _buildErrorState(
            colors,
            'Account ID not found',
            glassMode: glassMode,
          ),
        ),
      );
    }

    final tabViews = _dashboardTabs.map((tab) {
      final header = _buildTabHeader(colors, tab, glassMode: glassMode);
      final dashboard = _buildDashboardContainer(
        colors,
        accountId,
        tab['component'],
        glassMode: glassMode,
      );
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: 16),
            dashboard,
          ],
        ),
      );
    }).toList();

    if (glassMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
              indicatorColor: Colors.white,
              tabs: _dashboardTabs
                  .map(
                    (tab) => Tab(
                      icon: Icon(tab['icon']),
                      text: tab['title'],
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: tabViews,
            ),
          ),
        ],
      );
    }

    return TabBarView(
      controller: _tabController,
      children: tabViews,
    );
  }

  Map<String, String> _buildAppearanceOverrides(DynamicAppColors colors) => {
        'colorPrimary':
            '#${(colors.primaryAccent.r * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.primaryAccent.g * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.primaryAccent.b * 255).round().toRadixString(16).padLeft(2, '0')}',
        'colorBackground':
            '#${(colors.primaryBackground.r * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.primaryBackground.g * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.primaryBackground.b * 255).round().toRadixString(16).padLeft(2, '0')}',
        'colorText':
            '#${(colors.textPrimary.r * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.textPrimary.g * 255).round().toRadixString(16).padLeft(2, '0')}${(colors.textPrimary.b * 255).round().toRadixString(16).padLeft(2, '0')}',
        'borderRadius': '12px',
      };

  Widget _buildDashboardContainer(
    DynamicAppColors colors,
    String accountId,
    String component, {
    required bool glassMode,
  }) {
    final dashboard = ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: StripeConnectPaymentsDashboard(
        accountId: accountId,
        componentType: component,
        customAppearance: _buildAppearanceOverrides(colors),
      ),
    );

    if (glassMode) {
      return GlassContainer(
        padding: const EdgeInsets.all(16),
        child: dashboard,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.borderLight),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: dashboard,
    );
  }

  Widget _buildTabHeader(
    DynamicAppColors colors,
    Map<String, dynamic> tab, {
    required bool glassMode,
  }) {
    final titleColor = glassMode ? Colors.white : colors.textPrimary;
    final descriptionColor =
        glassMode ? Colors.white.withValues(alpha: 0.8) : colors.textSecondary;
    final iconBackground = glassMode
        ? Colors.white.withValues(alpha: 0.15)
        : colors.primaryAccent.withValues(alpha: 0.1);
    final iconColor = glassMode ? Colors.white : colors.primaryAccent;

    final child = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(8),
            border: glassMode
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  )
                : null,
          ),
          child: Icon(
            tab['icon'],
            color: iconColor,
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
                  color: titleColor,
                ),
              ),
              Text(
                tab['description'],
                style: TextStyle(
                  fontSize: 12,
                  color: descriptionColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return _sectionCard(
      colors: colors,
      glassMode: glassMode,
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _buildAccountNotReady(
    DynamicAppColors colors,
    AppLocalizations l10n, {
    required bool glassMode,
  }) {
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

    final iconWidget = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: glassMode ? 0.15 : 0.1),
        shape: BoxShape.circle,
        border: glassMode
            ? Border.all(color: Colors.white.withValues(alpha: 0.2))
            : null,
      ),
      child: Icon(
        icon,
        size: 64,
        color: glassMode ? Colors.white : iconColor,
      ),
    );

    final titleStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: glassMode ? Colors.white : colors.textPrimary,
    );

    final descriptionStyle = TextStyle(
      fontSize: 16,
      color: glassMode
          ? Colors.white.withValues(alpha: 0.85)
          : colors.textSecondary,
    );

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: glassMode ? Colors.white : colors.primaryAccent,
      foregroundColor: glassMode ? Colors.black87 : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        iconWidget,
        const SizedBox(height: 24),
        Text(
          title,
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: descriptionStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pushNamed('/connect/setup'),
          style: buttonStyle,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_forward,
                size: 20,
                color: glassMode ? Colors.black87 : Colors.white,
              ),
              const SizedBox(width: 8),
              const Text(
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
    );

    return _sectionCard(
      colors: colors,
      glassMode: glassMode,
      padding: const EdgeInsets.all(32),
      child: content,
    );
  }

  Widget _buildErrorState(
    DynamicAppColors colors,
    String message, {
    required bool glassMode,
  }) {
    final titleStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: glassMode ? Colors.white : colors.textPrimary,
    );
    final messageStyle = TextStyle(
      fontSize: 16,
      color: glassMode
          ? Colors.white.withValues(alpha: 0.85)
          : colors.textSecondary,
    );
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: glassMode ? Colors.white : colors.primaryAccent,
      foregroundColor: glassMode ? Colors.black87 : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: glassMode ? Colors.white : colors.error,
        ),
        const SizedBox(height: 24),
        Text(
          'Error Loading Dashboard',
          style: titleStyle,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: messageStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _checkAccountStatus,
          style: buttonStyle,
          child: Text(AppLocalizations.of(context)!.retry),
        ),
      ],
    );

    return _sectionCard(
      colors: colors,
      glassMode: glassMode,
      padding: const EdgeInsets.all(32),
      child: content,
    );
  }

  Widget _sectionCard({
    required DynamicAppColors colors,
    required Widget child,
    required bool glassMode,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    if (glassMode) {
      return GlassContainer(
        padding: padding,
        child: child,
      );
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderLight),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
