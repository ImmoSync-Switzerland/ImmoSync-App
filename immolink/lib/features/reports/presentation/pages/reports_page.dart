import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:immosync/features/auth/presentation/providers/user_role_provider.dart';
import 'package:immosync/features/payment/presentation/providers/payment_providers.dart';
import 'package:immosync/features/property/presentation/providers/property_providers.dart';
import 'package:immosync/features/maintenance/presentation/providers/maintenance_providers.dart';
import 'package:immosync/core/widgets/common_bottom_nav.dart';
import 'package:immosync/core/providers/currency_provider.dart';
import 'package:immosync/core/providers/dynamic_colors_provider.dart';
import 'package:intl/intl.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedPeriod = '';
  List<String> _periods = const [];

  // Helper method for responsive font sizes
  double _getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return baseFontSize * 0.85; // Smaller phones
    } else if (screenWidth < 400) {
      return baseFontSize * 0.9;  // Medium phones
    }
    return baseFontSize; // Tablets and larger
  }

  @override
  void initState() {
    super.initState();
  _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
    // Initialize localized period labels after first frame to access context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _periods = [
          l10n.thisWeek,
          l10n.thisMonth,
          l10n.thisQuarter,
          l10n.thisYear,
        ];
        _selectedPeriod = l10n.thisMonth;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userRole = ref.watch(userRoleProvider);
    final isLandlord = userRole == 'landlord';
    final colors = ref.watch(dynamicColorsProvider);

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colors.surfaceCards,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: colors.textSecondary,
              size: 18,
            ),
          ),
        ),
        title: Text(
          l10n.analyticsAndReports,
          style: TextStyle(
            fontSize: _getResponsiveFontSize(context, 22),
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
            letterSpacing: -0.6,
            inherit: true,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: _showExportDialog,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.primaryAccent,
                      colors.primaryAccent.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primaryAccent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.download_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  colors.borderLight.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPeriodSelector(l10n, colors),
              const SizedBox(height: 32),
              if (isLandlord)
                _buildLandlordReports(context, ref, l10n)
              else
                _buildTenantReports(context, ref, l10n),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CommonBottomNav(),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
  title: Text(AppLocalizations.of(context)!.exportReportsTitle),
  content: Text(AppLocalizations.of(context)!.exportFormatPrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _exportToPDF();
            },
            child: Text(AppLocalizations.of(context)!.exportPdf),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(AppLocalizations l10n, DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: _periods.map<Widget>((period) {
          final isSelected = period == _selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = period),
              child: _buildPeriodChip(period, isSelected, colors),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPeriodChip(String label, bool isSelected, DynamicAppColors colors) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        gradient: isSelected
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.info,
                colors.info.withValues(alpha: 0.8),
              ],
            )
          : null,
        color: isSelected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected 
            ? Colors.transparent 
            : colors.borderLight,
          width: 1,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: colors.info.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ] : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : colors.textSecondary,
          fontSize: _getResponsiveFontSize(context, 12),
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLandlordReports(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final properties = ref.watch(landlordPropertiesProvider);
    final payments = ref.watch(landlordPaymentsProvider);
    final maintenanceRequests = ref.watch(landlordMaintenanceRequestsProvider);
    final colors = ref.watch(dynamicColorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFinancialOverview(properties, payments, ref, l10n, colors),
        const SizedBox(height: 24),
        _buildPropertyMetrics(properties, l10n, colors),
        const SizedBox(height: 24),
        _buildMaintenanceOverview(maintenanceRequests, l10n, colors),
        const SizedBox(height: 24),
        _buildRevenueChart(properties, payments, ref, l10n, colors),
      ],
    );
  }

  Widget _buildTenantReports(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final payments = ref.watch(tenantPaymentsProvider);
    final maintenanceRequests = ref.watch(tenantMaintenanceRequestsProvider);
    final colors = ref.watch(dynamicColorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTenantPaymentSummary(payments, ref, l10n, colors),
        const SizedBox(height: 24),
        _buildTenantMaintenanceHistory(maintenanceRequests, l10n, colors),
        const SizedBox(height: 24),
        _buildPaymentHistory(payments, ref, l10n, colors),
      ],
    );
  }

  Widget _buildFinancialOverview(AsyncValue properties, AsyncValue payments, WidgetRef ref, AppLocalizations l10n, DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surfaceCards,
            colors.success.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.success.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.success,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: colors.surfaceCards,
                  size: 24,
                ),
              ),
              const SizedBox(width: 20),
              Text(
                l10n.financialOverview,
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(context, 22),
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          properties.when(
            data: (propertyList) {
              final totalRevenue = propertyList
                  .where((p) => p.status == 'rented')
                  .fold(0.0, (sum, p) => sum + p.rentAmount);
              
              return payments.when(
                data: (paymentsList) {
                  final completedPayments = paymentsList
                      .where((p) => p.status == 'completed')
                      .fold(0.0, (sum, p) => sum + p.amount);
                  final pendingPayments = paymentsList
                      .where((p) => p.status == 'pending')
                      .fold(0.0, (sum, p) => sum + p.amount);
                  
                  return Column(
                    children: [
                      Container(
                        width: double.infinity,
                        child: _buildFinancialMetric(
                          l10n.monthlyRevenue,
                          _formatCurrency(totalRevenue),
                          Icons.trending_up,
                          colors.success,
                          colors,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        child: _buildFinancialMetric(
                          l10n.collected,
                          _formatCurrency(completedPayments),
                          Icons.check_circle_outline,
                          colors.info,
                          colors,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        child: _buildFinancialMetric(
                          l10n.outstanding,
                          _formatCurrency(pendingPayments),
                          Icons.hourglass_empty,
                          colors.warning,
                          colors,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Text(l10n.errorLoadingPaymentHistory),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text(l10n.errorLoadingProperties),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final currency = ref.read(currencyProvider);
    String symbol;
    switch (currency.toUpperCase()) {
      case 'USD':
        symbol = '\$';
        break;
      case 'EUR':
        symbol = '€';
        break;
      case 'CHF':
        symbol = 'CHF ';
        break;
      default:
        symbol = '\$';
    }
    return NumberFormat.currency(symbol: symbol, decimalDigits: 2).format(amount);
  }

  Widget _buildFinancialMetric(String title, String value, IconData icon, Color color, DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: _getResponsiveFontSize(context, 20),
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: _getResponsiveFontSize(context, 11),
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
              letterSpacing: 0.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyMetrics(AsyncValue properties, AppLocalizations l10n, DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surfaceCards,
            colors.info.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.info.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.info,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.home_work_outlined,
                  color: colors.surfaceCards,
                  size: 24,
                ),
              ),
              const SizedBox(width: 20),
              Text(
                l10n.propertyOverview,
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(context, 22),
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          properties.when(
            data: (propertyList) {
              final totalProperties = propertyList.length;
              final rentedProperties = propertyList.where((p) => p.status == 'rented').length;
              final availableProperties = propertyList.where((p) => p.status == 'available').length;
              
              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    child: _buildFinancialMetric(
                      l10n.totalProperties,
                      totalProperties.toString(),
                      Icons.home_outlined,
                      colors.info,
                      colors,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    child: _buildFinancialMetric(
                      l10n.occupied,
                      rentedProperties.toString(),
                      Icons.check_circle_outline,
                      colors.success,
                      colors,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    child: _buildFinancialMetric(
                      l10n.available,
                      availableProperties.toString(),
                      Icons.radio_button_unchecked,
                      colors.textSecondary,
                      colors,
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text(l10n.errorLoadingProperties),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceOverview(AsyncValue maintenanceRequests, AppLocalizations l10n, DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surfaceCards,
            colors.warning.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.warning.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.warning,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.build_circle_outlined,
                  color: colors.surfaceCards,
                  size: 24,
                ),
              ),
              const SizedBox(width: 20),
              Text(
                l10n.maintenanceOverview,
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(context, 22),
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          maintenanceRequests.when(
            data: (requestList) {
              final totalRequests = requestList.length;
              final pendingRequests = requestList.where((r) => r.status == 'pending').length;
              final completedRequests = requestList.where((r) => r.status == 'completed').length;
              
              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    child: _buildFinancialMetric(
                      l10n.totalRequests,
                      totalRequests.toString(),
                      Icons.list_alt_outlined,
                      colors.textSecondary,
                      colors,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    child: _buildFinancialMetric(
                      l10n.pending,
                      pendingRequests.toString(),
                      Icons.hourglass_empty,
                      colors.warning,
                      colors,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    child: _buildFinancialMetric(
                      l10n.completed,
                      completedRequests.toString(),
                      Icons.check_circle_outline,
                      colors.success,
                      colors,
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text(l10n.errorLoadingMaintenanceData),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(AsyncValue properties, AsyncValue payments, WidgetRef ref, AppLocalizations l10n, DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surfaceCards,
            const Color(0xFF8B5CF6).withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 20),
              Text(
                l10n.revenueAnalytics,
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(context, 22),
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.borderLight,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                l10n.revenueChartComingSoon,
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantPaymentSummary(AsyncValue payments, WidgetRef ref, AppLocalizations l10n, DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surfaceCards,
            colors.success.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.success.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.success,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: colors.surfaceCards,
                  size: 24,
                ),
              ),
              const SizedBox(width: 20),
              Text(
                l10n.paymentSummary,
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(context, 22),
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          payments.when(
            data: (paymentsList) {
              final totalPaid = paymentsList
                  .where((p) => p.status == 'completed')
                  .fold(0.0, (sum, p) => sum + p.amount);
              final pendingAmount = paymentsList
                  .where((p) => p.status == 'pending')
                  .fold(0.0, (sum, p) => sum + p.amount);
              final totalPayments = paymentsList.length;

              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    child: _buildFinancialMetric(
                      l10n.totalPaid,
                      _formatCurrency(totalPaid),
                      Icons.check_circle_outline,
                      colors.success,
                      colors,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    child: _buildFinancialMetric(
                      l10n.pending,
                      _formatCurrency(pendingAmount),
                      Icons.hourglass_empty,
                      colors.warning,
                      colors,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    child: _buildFinancialMetric(
                      l10n.totalPayments,
                      totalPayments.toString(),
                      Icons.receipt_long_outlined,
                      colors.info,
                      colors,
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text(l10n.errorLoadingPaymentSummary),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantMaintenanceHistory(AsyncValue maintenanceRequests, AppLocalizations l10n, DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surfaceCards,
            colors.warning.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.warning.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.handyman_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 20),
              Text(
                l10n.maintenanceRequests,
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(context, 22),
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          maintenanceRequests.when(
            data: (requestList) {
              if (requestList.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 48,
                          color: Color(0xFF10B981),
                        ),
                        SizedBox(height: 16),
                        Text(
                          l10n.noMaintenanceRequests,
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(context, 16),
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: requestList.take(5).map<Widget>((request) {
                  final statusColor = _getMaintenanceStatusColor(request.status, colors);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.borderLight,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getMaintenanceStatusIcon(request.status),
                            color: statusColor,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.title,
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(context, 16),
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM d, yyyy').format(request.requestedDate),
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(context, 14),
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatStatusText(request.status),
                            style: TextStyle(
                              fontSize: _getResponsiveFontSize(context, 12),
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text(l10n.errorLoadingMaintenanceRequests),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory(AsyncValue payments, WidgetRef ref, AppLocalizations l10n, DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surfaceCards,
            const Color(0xFF3B82F6).withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.history,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 20),
              Text(
                l10n.recentPayments,
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(context, 22),
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          payments.when(
            data: (paymentsList) {
              if (paymentsList.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      l10n.noPaymentsFound,
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(context, 16),
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: paymentsList.take(5).map<Widget>((payment) {
                  final statusColor = payment.status == 'completed' 
                    ? const Color(0xFF10B981) 
                    : const Color(0xFFF59E0B);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.borderLight,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            payment.status == 'completed' 
                              ? Icons.check_circle_outline 
                              : Icons.hourglass_empty,
                            color: statusColor,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatCurrency(payment.amount),
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(context, 18),
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${payment.type.toUpperCase()} - ${DateFormat('MMM d, yyyy').format(payment.date)}',
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(context, 14),
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatStatusText(payment.status),
                            style: TextStyle(
                              fontSize: _getResponsiveFontSize(context, 12),
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text(l10n.errorLoadingPaymentHistory),
          ),
        ],
      ),
    );
  }

  Color _getMaintenanceStatusColor(String status, DynamicAppColors colors) {
    switch (status.toLowerCase()) {
      case 'completed':
        return colors.success;
      case 'in_progress':
        return colors.info;
      case 'pending':
        return colors.warning;
      default:
        return colors.textSecondary;
    }
  }

  IconData _getMaintenanceStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'in_progress':
        return Icons.engineering;
      case 'pending':
        return Icons.hourglass_empty;
      default:
        return Icons.help_outline;
    }
  }

  String _formatStatusText(String status) {
    // Convert underscores to spaces and capitalize properly
    return status
        .toLowerCase()
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }

  void _exportToPDF() {
    final colors = ref.read(dynamicColorsProvider);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.generatingPdfReport),
          ],
        ),
      ),
    );

    // Simulate PDF generation
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop(); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pdfExportInfo),
          backgroundColor: colors.info,
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.ok,
            onPressed: () {},
          ),
        ),
      );
    });
  }
}
