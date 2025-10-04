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
import 'package:immosync/features/reports/services/pdf_exporter.dart';
import 'package:fl_chart/fl_chart.dart';

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
      return baseFontSize * 0.9; // Medium phones
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
              // Modern hero header & period selector
              _buildHeroHeader(l10n, isLandlord, colors),
              const SizedBox(height: 20),
              _buildPeriodSelector(l10n, colors),
              const SizedBox(height: 28),
              _buildModernReport(isLandlord, l10n, colors),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CommonBottomNav(),
    );
  }

  Widget _buildHeroHeader(AppLocalizations l10n, bool isLandlord, DynamicAppColors colors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final compact = w < 360;
        final titleSize = _getResponsiveFontSize(context, compact ? 22 : 26);
        final subtitleSize = compact ? 11.5 : 13.0;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 18 : 24,
            vertical: compact ? 24 : 30,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.primaryAccent.withValues(alpha: 0.85),
                colors.info.withValues(alpha: 0.75),
                colors.surfaceCards.withValues(alpha: 0.10),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.borderLight.withValues(alpha: 0.25), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(compact ? 14 : 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          colors.surfaceCards.withValues(alpha: 0.95),
                          colors.surfaceCards.withValues(alpha: 0.75),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      isLandlord ? Icons.analytics_outlined : Icons.insights_outlined,
                      size: compact ? 26 : 30,
                      color: colors.primaryAccent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          alignment: Alignment.centerLeft,
                          fit: BoxFit.scaleDown,
                          child: Text(
                            isLandlord ? l10n.analyticsAndReports : l10n.paymentSummary,
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              height: 1.05,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isLandlord ? l10n.financialOverview : l10n.recentActivity,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: subtitleSize,
                            fontWeight: FontWeight.w500,
                            color: colors.textPrimary.withValues(alpha: 0.75),
                            letterSpacing: -0.15,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildExportPill(l10n, colors),
                ],
              ),
              SizedBox(height: compact ? 18 : 22),
              _buildKpiStrip(isLandlord, l10n, colors),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExportPill(AppLocalizations l10n, DynamicAppColors colors) {
    return GestureDetector(
      onTap: _showExportDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            colors: [colors.info, colors.primaryAccent],
          ),
          boxShadow: [
            BoxShadow(
              color: colors.info.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf_outlined, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              l10n.export,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiStrip(bool isLandlord, AppLocalizations l10n, DynamicAppColors colors) {
    final payments = ref.watch(isLandlord ? landlordPaymentsProvider : tenantPaymentsProvider);
    final maintenance = ref.watch(isLandlord ? landlordMaintenanceRequestsProvider : tenantMaintenanceRequestsProvider);
    final properties = isLandlord ? ref.watch(landlordPropertiesProvider) : ref.watch(tenantPropertiesProvider);

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      int columns;
      if (width < 340) {
        columns = 1;
      } else if (width < 560) {
        columns = 2;
      } else if (width < 820) {
        columns = isLandlord ? 3 : 3;
      } else {
        columns = isLandlord ? 4 : 3; // tenant has fewer KPIs
      }
      final spacing = 14.0;
      final cardWidth = (width - spacing * (columns - 1)) / columns;

      List<Widget> cards = [
        _asyncKpiCard(
          label: l10n.collected,
          asyncValue: payments,
          icon: Icons.check_circle_outline,
          color: colors.success,
          valueBuilder: (list) => _formatCurrency(list.where((p) => p.status == 'completed').fold<double>(0, (s, p) => s + p.amount)),
          minWidth: cardWidth,
        ),
        _asyncKpiCard(
          label: l10n.outstanding,
          asyncValue: payments,
          icon: Icons.hourglass_bottom,
          color: colors.warning,
          valueBuilder: (list) => _formatCurrency(list.where((p) => p.status == 'pending').fold<double>(0, (s, p) => s + p.amount)),
          minWidth: cardWidth,
        ),
      ];
      if (isLandlord) {
        cards.add(
          _asyncKpiCard(
            label: l10n.occupancyRate,
            asyncValue: properties,
            icon: Icons.apartment_outlined,
            color: colors.info,
            valueBuilder: (list) {
              final total = list.length;
              final rented = list.where((p) => p.status == 'rented').length;
              final rate = total == 0 ? 0 : (rented / total * 100);
              return '${rate.toStringAsFixed(0)}%';
            },
            minWidth: cardWidth,
          ),
        );
      }
      cards.add(
        _asyncKpiCard(
          label: l10n.maintenance,
          asyncValue: maintenance,
            icon: Icons.build_circle_outlined,
            color: colors.error,
            valueBuilder: (list) => list.where((r) => r.status != 'completed' && r.status != 'closed').length.toString(),
            minWidth: cardWidth,
          ),
      );

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: cards.map((c) => SizedBox(width: cardWidth, child: c)).toList(),
      );
    });
  }

  Widget _asyncKpiCard<T>({
    required String label,
    required AsyncValue<List<T>> asyncValue,
    required String Function(List<T>) valueBuilder,
    required IconData icon,
    required Color color,
    required double minWidth,
  }) {
    final colors = ref.watch(dynamicColorsProvider);
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: Container(
        constraints: BoxConstraints(minWidth: minWidth, maxWidth: 240),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.surfaceCards,
              color.withValues(alpha: 0.10),
            ],
          ),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: asyncValue.when(
          data: (data) => _kpiContent(label, valueBuilder(data), icon, color),
          loading: () => _kpiShimmer(label, icon, color),
          error: (_, __) => _kpiError(label, icon, color),
        ),
      ),
    );
  }

  Widget _kpiContent(String label, String value, IconData icon, Color color) {
    final colors = ref.watch(dynamicColorsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.08)]),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const Spacer(),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: colors.textSecondary,
              ),
            )
          ],
        ),
        const SizedBox(height: 10),
        FittedBox(
          alignment: Alignment.centerLeft,
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _kpiShimmer(String label, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
          ),
          child: Icon(icon, color: color.withValues(alpha: 0.5), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 16, width: 80, decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: color.withValues(alpha: 0.25))),
              const SizedBox(height: 6),
              Container(height: 10, width: 60, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: color.withValues(alpha: 0.18))),
              const SizedBox(height: 2),
              Text(label.toUpperCase(), style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.4), letterSpacing: 0.6)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kpiError(String label, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text('—', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color))),
        Text(label.toUpperCase(), style: TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildModernReport(bool isLandlord, AppLocalizations l10n, DynamicAppColors colors) {
    // Use existing detailed sections below but wrap them into a modern layered container set
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLandlord) ...[
          _modernSectionHeader(Icons.trending_up, l10n.financialOverview, colors, accent: colors.success),
          const SizedBox(height: 16),
          _buildLandlordReports(context, ref, l10n),
        ] else ...[
          _modernSectionHeader(Icons.payments_outlined, l10n.paymentSummary, colors, accent: colors.success),
          const SizedBox(height: 16),
          _buildTenantReports(context, ref, l10n),
        ],
      ],
    );
  }

  Widget _modernSectionHeader(IconData icon, String title, DynamicAppColors colors, {required Color accent}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [accent.withValues(alpha: 0.9), accent.withValues(alpha: 0.6)]),
            boxShadow: [
              BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: _getResponsiveFontSize(context, 24),
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
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

  Widget _buildPeriodChip(
      String label, bool isSelected, DynamicAppColors colors) {
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
          color: isSelected ? Colors.transparent : colors.borderLight,
          width: 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: colors.info.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ]
            : null,
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

  Widget _buildLandlordReports(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
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

  Widget _buildTenantReports(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
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

  Widget _buildFinancialOverview(AsyncValue properties, AsyncValue payments,
      WidgetRef ref, AppLocalizations l10n, DynamicAppColors colors) {
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
    return NumberFormat.currency(symbol: symbol, decimalDigits: 2)
        .format(amount);
  }

  Widget _buildFinancialMetric(String title, String value, IconData icon,
      Color color, DynamicAppColors colors) {
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

  Widget _buildPropertyMetrics(
      AsyncValue properties, AppLocalizations l10n, DynamicAppColors colors) {
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
              final rentedProperties =
                  propertyList.where((p) => p.status == 'rented').length;
              final availableProperties =
                  propertyList.where((p) => p.status == 'available').length;

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

  Widget _buildMaintenanceOverview(AsyncValue maintenanceRequests,
      AppLocalizations l10n, DynamicAppColors colors) {
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
              final pendingRequests =
                  requestList.where((r) => r.status == 'pending').length;
              final completedRequests =
                  requestList.where((r) => r.status == 'completed').length;

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

  Widget _buildRevenueChart(AsyncValue properties, AsyncValue payments,
      WidgetRef ref, AppLocalizations l10n, DynamicAppColors colors) {
    return payments.when(
      data: (paymentsList) {
        // Aggregate last 6 months revenue from completed payments
        final now = DateTime.now();
        final months = List.generate(6, (i) => DateTime(now.year, now.month - (5 - i), 1));
        final monthKeys = months.map((d) => '${d.year}-${d.month.toString().padLeft(2,'0')}').toList();
        final totals = {for (final k in monthKeys) k: 0.0};
        for (final p in paymentsList.where((p) => p.status == 'completed')) {
          final k = '${p.date.year}-${p.date.month.toString().padLeft(2,'0')}';
          if (totals.containsKey(k)) totals[k] = (totals[k] ?? 0) + p.amount;
        }
        final maxY = (totals.values.fold<double>(0, (m, v) => v > m ? v : m)).clamp(1, double.infinity);
        final spots = <FlSpot>[];
        for (var i = 0; i < monthKeys.length; i++) {
          spots.add(FlSpot(i.toDouble(), totals[monthKeys[i]]!));
        }

        String monthLabel(int index) {
          if (index < 0 || index >= months.length) return '';
            return DateFormat('MMM').format(months[index]);
        }

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
                    child: const Icon(
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
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: maxY * 1.2,
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: maxY == 0 ? 1 : (maxY / 4).ceilToDouble(),
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: colors.borderLight.withValues(alpha: 0.5),
                        strokeWidth: 1,
                      ),
                      drawVerticalLine: false,
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                          interval: maxY == 0 ? 1 : (maxY / 4).ceilToDouble(),
                          getTitlesWidget: (v, meta) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              _compactCurrency(v),
                              style: TextStyle(fontSize: 10, color: colors.textSecondary),
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (v, meta) => Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              monthLabel(v.toInt()),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textSecondary),
                            ),
                          ),
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipRoundedRadius: 10,
                        getTooltipItems: (touched) => touched.map((barSpot) {
                          final idx = barSpot.x.toInt();
                          return LineTooltipItem(
                            '${monthLabel(idx)}\n${_formatCurrency(barSpot.y)}',
                            TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 12),
                          );
                        }).toList(),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: const Color(0xFF8B5CF6),
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF8B5CF6).withValues(alpha: 0.30),
                              const Color(0xFF8B5CF6).withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colors.surfaceCards,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.borderLight),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colors.surfaceCards,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colors.error),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.errorLoadingPaymentHistory, style: TextStyle(color: colors.textSecondary))),
          ],
        ),
      ),
    );
  }

  String _compactCurrency(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  Widget _buildTenantPaymentSummary(AsyncValue payments, WidgetRef ref,
      AppLocalizations l10n, DynamicAppColors colors) {
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

  Widget _buildTenantMaintenanceHistory(AsyncValue maintenanceRequests,
      AppLocalizations l10n, DynamicAppColors colors) {
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
                  final statusColor =
                      _getMaintenanceStatusColor(request.status, colors);
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  final isClosed = request.status.toLowerCase() == 'closed';
                  final chipTextColor = isClosed
                      ? (isDark ? colors.textPrimary : colors.textSecondary)
                      : statusColor;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? colors.surfaceCards : colors.surfaceSecondary,
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
                            color: statusColor.withValues(alpha: isDark ? 0.25 : 0.12),
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
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM d, yyyy')
                                    .format(request.requestedDate),
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(context, 14),
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: isDark ? 0.28 : 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatStatusText(request.status),
                            style: TextStyle(
                              fontSize: _getResponsiveFontSize(context, 12),
                              fontWeight: FontWeight.w600,
                              color: chipTextColor,
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

  Widget _buildPaymentHistory(AsyncValue payments, WidgetRef ref,
      AppLocalizations l10n, DynamicAppColors colors) {
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
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
      case 'closed':
        return Colors.grey;
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
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }

  Future<void> _exportToPDF() async {
    final colors = ref.read(dynamicColorsProvider);

    try {
      // Ask for export mode: Actual (Ist) vs Planned (Soll)
      final l10n = AppLocalizations.of(context)!;
      final isPlanned = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          bool planned = false;
          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: Text(l10n.analyticsAndReports),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<bool>(
                    value: false,
                    groupValue: planned,
                    onChanged: (v) => setState(() => planned = v ?? false),
                    title: Text(l10n.actual),
                  ),
                  RadioListTile<bool>(
                    value: true,
                    groupValue: planned,
                    onChanged: (v) => setState(() => planned = v ?? false),
                    title: Text(l10n.planned),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(planned),
                  child: Text(l10n.generateReport),
                ),
              ],
            ),
          );
        },
      );

      if (isPlanned == null) {
        // User cancelled
        return;
      }

      // Show loading dialog now
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
      // Determine role
      final userRole = ref.read(userRoleProvider);
      final isLandlord = userRole == 'landlord';

      // Build last 6 months list (oldest -> newest)
      final now = DateTime.now();
      final months = List<DateTime>.generate(
        6,
        (i) => DateTime(now.year, now.month - (5 - i), 1),
      );

      // Helpers to map dates to yyyy-MM keys
      String keyFor(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

      // Initialize maps for sums
      final revenueByMonth = <String, double>{
        for (final m in months) keyFor(m): 0.0,
      };
      final expensesByMonth = <String, double>{
        for (final m in months) keyFor(m): 0.0,
      };

      // Load payments (role-specific)
      final payments = await (isLandlord
          ? ref.read(landlordPaymentsProvider.future)
          : ref.read(tenantPaymentsProvider.future));

      int pendingCount = 0;
      int completedCount = 0;
      double collectedSum = 0.0;
      double outstandingSum = 0.0;
      for (final p in payments) {
        final status = (p.status).toLowerCase();
        if (status == 'completed') {
          completedCount++;
          collectedSum += p.amount;
          if (!isPlanned) {
            final k = keyFor(DateTime(p.date.year, p.date.month, 1));
            if (revenueByMonth.containsKey(k)) {
              revenueByMonth[k] = (revenueByMonth[k] ?? 0) + p.amount;
            }
          }
        } else if (status == 'pending') {
          pendingCount++;
          outstandingSum += p.amount;
        }
      }

      // Load maintenance to approximate expenses from actual/estimated cost
      final maintenance = await (isLandlord
          ? ref.read(landlordMaintenanceRequestsProvider.future)
          : ref.read(tenantMaintenanceRequestsProvider.future));

      for (final r in maintenance) {
        final when = r.completedDate ?? r.scheduledDate ?? r.requestedDate;
        final k = keyFor(DateTime(when.year, when.month, 1));
        final double cost;
        if (isPlanned) {
          // planned: take estimated only
          cost = r.cost?.estimated ?? 0.0;
        } else {
          // actual: take actual if present else estimated
          cost = r.cost?.actual ?? r.cost?.estimated ?? 0.0;
        }
        if (expensesByMonth.containsKey(k)) {
          expensesByMonth[k] = (expensesByMonth[k] ?? 0) + cost;
        }
      }

      // If planned: fill revenue per month with monthly rent sums instead of payments
      if (isPlanned) {
        double monthlyPlannedRevenue = 0.0;
        try {
          if (isLandlord) {
            final properties = await ref.read(landlordPropertiesProvider.future);
            monthlyPlannedRevenue = properties
                .where((p) => p.status.toLowerCase() == 'rented')
                .fold<double>(0.0, (sum, p) => sum + p.rentAmount);
          } else {
            final tenantProps = await ref.read(tenantPropertiesProvider.future);
            monthlyPlannedRevenue = tenantProps
                .fold<double>(0.0, (sum, p) => sum + p.rentAmount);
          }
        } catch (_) {}
        for (final m in months) {
          final k = keyFor(m);
          revenueByMonth[k] = monthlyPlannedRevenue;
        }
      }

      // Convert to aligned int lists for PDF
      final revenue = months
          .map((m) => revenueByMonth[keyFor(m)]?.round() ?? 0)
          .toList();
      final expenses = months
          .map((m) => expensesByMonth[keyFor(m)]?.round() ?? 0)
          .toList();

      // Compute occupancy (landlord only)
      double occupancyRate = 1.0;
      if (isLandlord) {
        try {
          final properties = await ref.read(landlordPropertiesProvider.future);
          if (properties.isNotEmpty) {
            final total = properties.length;
            final rented = properties
                .where((p) => p.status.toLowerCase() == 'rented')
                .length;
            occupancyRate = total == 0 ? 0.0 : rented / total;
          } else {
            occupancyRate = 0.0;
          }
        } catch (_) {
          occupancyRate = 1.0;
        }
      }

      // Currency formatting based on app currency setting
      final appCurrency = ref.read(currencyProvider);
      NumberFormat currencyFmt;
      switch (appCurrency) {
        case 'EUR':
          currencyFmt = NumberFormat.currency(locale: 'de_DE', symbol: '€');
          break;
        case 'USD':
          currencyFmt = NumberFormat.currency(locale: 'en_US', symbol: '\$');
          break;
        case 'GBP':
          currencyFmt = NumberFormat.currency(locale: 'en_GB', symbol: '£');
          break;
        case 'CHF':
        default:
          currencyFmt = NumberFormat.currency(locale: 'de_CH', symbol: 'CHF');
          break;
      }

      // Compute Month-specific KPIs
      // Monthly Revenue KPI (landlord): sum of rents of rented properties (align with dashboard)
      String? monthlyRevenueLabel;
      String? monthlyRevenueValue;
      if (isLandlord) {
        try {
          final properties = await ref.read(landlordPropertiesProvider.future);
          final totalMonthlyRent = properties
              .where((p) => p.status.toLowerCase() == 'rented')
              .fold<double>(0.0, (sum, p) => sum + p.rentAmount);
          monthlyRevenueLabel = AppLocalizations.of(context)!.monthlyRevenue;
          monthlyRevenueValue = currencyFmt.format(totalMonthlyRent);
        } catch (_) {
          // ignore – keep KPI hidden if failed
        }
      } else {
        // Tenant: show Monthly Rent Due (sum of tenant properties rent amounts if available)
        try {
          final tenantProps = await ref.read(tenantPropertiesProvider.future);
          final totalMonthlyRent = tenantProps
              .fold<double>(0.0, (sum, p) => sum + p.rentAmount);
          monthlyRevenueLabel = AppLocalizations.of(context)!.monthlyRent;
          monthlyRevenueValue = currencyFmt.format(totalMonthlyRent);
        } catch (_) {
          // ignore
        }
      }

      // Close loading dialog before invoking share sheet
      if (mounted) Navigator.of(context).pop();

      // Generate & share PDF
      await PdfExporter.exportFinancialReport(
        context: context,
        currency: currencyFmt,
        months: months,
        revenue: revenue,
        expenses: expenses,
        occupancyRate: occupancyRate,
        locale: Localizations.localeOf(context).toLanguageTag(),
        reportTitle: AppLocalizations.of(context)!.analyticsAndReports,
        revenueVsExpensesTitle: AppLocalizations.of(context)!.revenueVsExpenses,
        totalRevenueLabel: AppLocalizations.of(context)!.totalRevenue,
        totalExpensesLabel: AppLocalizations.of(context)!.totalExpenses,
        netIncomeLabel: AppLocalizations.of(context)!.netIncome,
        occupancyLabel: AppLocalizations.of(context)!.occupancyRate,
        monthlyRevenueLabel: monthlyRevenueLabel,
        monthlyRevenueValue: monthlyRevenueValue,
        collectedLabel: AppLocalizations.of(context)!.collected,
        collectedValue: currencyFmt.format(collectedSum),
        outstandingLabel: AppLocalizations.of(context)!.outstanding,
        outstandingValue: currencyFmt.format(outstandingSum),
        reportModeLabel: isPlanned ? l10n.planned : l10n.actual,
  monthHeader: AppLocalizations.of(context)!.month,
  revenueHeader: AppLocalizations.of(context)!.revenue,
  expensesHeader: AppLocalizations.of(context)!.expenses,
  netHeader: AppLocalizations.of(context)!.net,
        showOccupancy: isLandlord,
        altKpiLabel: isLandlord ? null : AppLocalizations.of(context)!.status,
        altKpiValue: isLandlord ? null : '✔ $completedCount • ⏳ $pendingCount',
      );

      // Optional confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.exportPdf),
            backgroundColor: colors.success,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export PDF: $e'),
            backgroundColor: colors.error,
          ),
        );
      }
    }
  }
}
