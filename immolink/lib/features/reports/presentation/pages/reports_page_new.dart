import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/payment/domain/models/payment.dart';
import 'package:immosync/features/payment/presentation/providers/payment_providers.dart';
import 'package:immosync/features/property/domain/models/property.dart';
import 'package:immosync/features/property/presentation/providers/property_providers.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/widgets/common_bottom_nav.dart';
import '../../../home/presentation/models/dashboard_design.dart';
import '../../../home/presentation/pages/glass_dashboard_shared.dart';
import '../../../settings/providers/settings_provider.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(currentUserProvider);
    final bool isLandlord = currentUser?.role == 'landlord';
    final design = dashboardDesignFromId(
      ref.watch(settingsProvider).dashboardDesign,
    );
    final bool glassMode = design == DashboardDesign.glass;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(routeAwareNavigationProvider.notifier).setIndex(3);
    });

    final content = _buildReportsContent(
      ref: ref,
      colors: colors,
      l10n: l10n,
      isLandlord: isLandlord,
      glassMode: glassMode,
    );

    if (glassMode) {
      return GlassPageScaffold(
        title: l10n.analyticsAndReports,
        onBack: () => context.go('/home'),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
          child: content,
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        backgroundColor: colors.primaryBackground,
        elevation: 0,
        title: Text(
          l10n.analyticsAndReports,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary),
          onPressed: () => context.go('/home'),
        ),
      ),
      bottomNavigationBar: const CommonBottomNav(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: content,
        ),
      ),
    );
  }

  Widget _buildReportsContent({
    required WidgetRef ref,
    required DynamicAppColors colors,
    required AppLocalizations l10n,
    required bool isLandlord,
    required bool glassMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReportPeriod(
          colors: colors,
          l10n: l10n,
          glassMode: glassMode,
        ),
        const SizedBox(height: 20),
        if (isLandlord)
          _buildLandlordReports(
            ref: ref,
            colors: colors,
            l10n: l10n,
            glassMode: glassMode,
          )
        else
          _buildTenantReports(
            ref: ref,
            colors: colors,
            l10n: l10n,
            glassMode: glassMode,
          ),
      ],
    );
  }

  Widget _buildReportPeriod({
    required DynamicAppColors colors,
    required AppLocalizations l10n,
    required bool glassMode,
  }) {
    final labelColor = _primaryTextColor(colors, glassMode);
    final hintColor = _secondaryTextColor(colors, glassMode);

    return _sectionCard(
      colors: colors,
      glassMode: glassMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.reportPeriod,
            style: TextStyle(
              color: labelColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: glassMode
                  ? Colors.white.withValues(alpha: 0.12)
                  : colors.surfaceWithElevation(2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: glassMode
                    ? Colors.white.withValues(alpha: 0.2)
                    : colors.borderLight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: glassMode ? Colors.white : colors.primaryAccent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.thisMonth,
                    style: TextStyle(
                      color: labelColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: hintColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandlordReports({
    required WidgetRef ref,
    required DynamicAppColors colors,
    required AppLocalizations l10n,
    required bool glassMode,
  }) {
    final propertiesAsync = ref.watch(landlordPropertiesProvider);
    final paymentsAsync = ref.watch(landlordPaymentsProvider);

    final properties = propertiesAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <Property>[],
    );
    final payments = paymentsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <Payment>[],
    );

    final loadingProperties = propertiesAsync.isLoading && properties.isEmpty;
    final loadingPayments = paymentsAsync.isLoading && payments.isEmpty;
    final propertyError =
        propertiesAsync.whenOrNull(error: (error, _) => error);
    final paymentError = paymentsAsync.whenOrNull(error: (error, _) => error);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (propertyError != null || paymentError != null)
          _buildErrorState(
            colors: colors,
            l10n: l10n,
            error: propertyError ?? paymentError!,
            glassMode: glassMode,
          ),
        _buildFinancialSummaryCard(
          ref: ref,
          colors: colors,
          payments: payments,
          properties: properties,
          isLoading: loadingPayments,
          l10n: l10n,
          glassMode: glassMode,
        ),
        const SizedBox(height: 20),
        _buildOccupancyCard(
          colors: colors,
          properties: properties,
          isLoading: loadingProperties,
          l10n: l10n,
          glassMode: glassMode,
        ),
      ],
    );
  }

  Widget _buildFinancialSummaryCard({
    required WidgetRef ref,
    required DynamicAppColors colors,
    required List<Payment> payments,
    required List<Property> properties,
    required bool isLoading,
    required AppLocalizations l10n,
    required bool glassMode,
  }) {
    final currencyNotifier = ref.read(currencyProvider.notifier);
    final completedIncome = payments
        .where((payment) => payment.status.toLowerCase() == 'completed')
        .fold<double>(0.0, (sum, payment) => sum + payment.amount);
    final pendingIncome = payments
        .where((payment) => payment.status.toLowerCase() == 'pending')
        .fold<double>(0.0, (sum, payment) => sum + payment.amount);
    final outstandingBalance = properties.fold<double>(
      0.0,
      (sum, property) => sum + property.outstandingPayments,
    );

    return _sectionCard(
      colors: colors,
      glassMode: glassMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.financialSummary,
                style: TextStyle(
                  color: _primaryTextColor(colors, glassMode),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: 82,
                  height: 4,
                  child: LinearProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      glassMode ? Colors.white : colors.primaryAccent,
                    ),
                    backgroundColor:
                        (glassMode ? Colors.white : colors.primaryAccent)
                            .withValues(alpha: 0.15),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetricRow(
            colors: colors,
            glassMode: glassMode,
            icon: Icons.trending_up_rounded,
            iconColor: colors.success,
            title: l10n.totalIncome,
            value: currencyNotifier.formatAmount(completedIncome),
          ),
          const SizedBox(height: 12),
          _buildMetricRow(
            colors: colors,
            glassMode: glassMode,
            icon: Icons.timer_outlined,
            iconColor: colors.warning,
            title: l10n.outstandingPayments,
            value: currencyNotifier.formatAmount(pendingIncome),
          ),
          const SizedBox(height: 12),
          _buildMetricRow(
            colors: colors,
            glassMode: glassMode,
            icon: Icons.warning_amber_rounded,
            iconColor: colors.error,
            title: l10n.totalOutstanding,
            value: currencyNotifier.formatAmount(outstandingBalance),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyCard({
    required DynamicAppColors colors,
    required List<Property> properties,
    required bool isLoading,
    required AppLocalizations l10n,
    required bool glassMode,
  }) {
    final total = properties.length;
    final occupied = properties
        .where((property) => property.status.toLowerCase() == 'rented')
        .length;
    final occupancyRate = total == 0 ? 0.0 : (occupied / total * 100);

    return _sectionCard(
      colors: colors,
      glassMode: glassMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.occupancyRate,
                style: TextStyle(
                  color: _primaryTextColor(colors, glassMode),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: 82,
                  height: 4,
                  child: LinearProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      glassMode ? Colors.white : colors.primaryAccent,
                    ),
                    backgroundColor:
                        (glassMode ? Colors.white : colors.primaryAccent)
                            .withValues(alpha: 0.15),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (total == 0)
            _buildEmptyState(
              colors: colors,
              message: l10n.noPropertiesFound,
              icon: Icons.home_outlined,
              glassMode: glassMode,
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: occupancyRate / 100,
                        strokeWidth: 8,
                        backgroundColor: glassMode
                            ? Colors.white.withValues(alpha: 0.2)
                            : colors.borderLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          glassMode ? Colors.white : colors.success,
                        ),
                      ),
                      Center(
                        child: Text(
                          '${occupancyRate.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: _primaryTextColor(colors, glassMode),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.rented}: $occupied',
                        style: TextStyle(
                          color: _primaryTextColor(colors, glassMode),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${l10n.numberOfProperties}: $total',
                        style: TextStyle(
                          color: _secondaryTextColor(colors, glassMode),
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

  Widget _buildTenantReports({
    required WidgetRef ref,
    required DynamicAppColors colors,
    required AppLocalizations l10n,
    required bool glassMode,
  }) {
    final paymentsAsync = ref.watch(tenantPaymentsProvider);
    final payments = paymentsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <Payment>[],
    );
    final isLoading = paymentsAsync.isLoading && payments.isEmpty;
    final error = paymentsAsync.whenOrNull(error: (error, _) => error);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null)
          _buildErrorState(
            colors: colors,
            l10n: l10n,
            error: error,
            glassMode: glassMode,
          ),
        _buildTenantSummaryCard(
          ref: ref,
          colors: colors,
          payments: payments,
          isLoading: isLoading,
          l10n: l10n,
          glassMode: glassMode,
        ),
        const SizedBox(height: 20),
        _buildPaymentHistory(
          paymentsAsync: paymentsAsync,
          ref: ref,
          colors: colors,
          l10n: l10n,
          glassMode: glassMode,
        ),
      ],
    );
  }

  Widget _buildTenantSummaryCard({
    required WidgetRef ref,
    required DynamicAppColors colors,
    required List<Payment> payments,
    required bool isLoading,
    required AppLocalizations l10n,
    required bool glassMode,
  }) {
    final currencyNotifier = ref.read(currencyProvider.notifier);
    final total =
        payments.fold<double>(0.0, (sum, payment) => sum + payment.amount);
    final completed = payments
        .where((payment) => payment.status.toLowerCase() == 'completed')
        .fold<double>(0.0, (sum, payment) => sum + payment.amount);
    final pending = payments
        .where((payment) => payment.status.toLowerCase() == 'pending')
        .fold<double>(0.0, (sum, payment) => sum + payment.amount);

    return _sectionCard(
      colors: colors,
      glassMode: glassMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.paymentSummary,
                style: TextStyle(
                  color: _primaryTextColor(colors, glassMode),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: 82,
                  height: 4,
                  child: LinearProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      glassMode ? Colors.white : colors.primaryAccent,
                    ),
                    backgroundColor:
                        (glassMode ? Colors.white : colors.primaryAccent)
                            .withValues(alpha: 0.15),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetricRow(
            colors: colors,
            glassMode: glassMode,
            icon: Icons.attach_money_rounded,
            iconColor: colors.primaryAccent,
            title: l10n.totalPayments,
            value: currencyNotifier.formatAmount(total),
          ),
          const SizedBox(height: 12),
          _buildMetricRow(
            colors: colors,
            glassMode: glassMode,
            icon: Icons.check_circle_outline,
            iconColor: colors.success,
            title: l10n.completed,
            value: currencyNotifier.formatAmount(completed),
          ),
          const SizedBox(height: 12),
          _buildMetricRow(
            colors: colors,
            glassMode: glassMode,
            icon: Icons.hourglass_bottom_rounded,
            iconColor: colors.warning,
            title: l10n.pending,
            value: currencyNotifier.formatAmount(pending),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory({
    required AsyncValue<List<Payment>> paymentsAsync,
    required WidgetRef ref,
    required DynamicAppColors colors,
    required AppLocalizations l10n,
    required bool glassMode,
  }) {
    return _sectionCard(
      colors: colors,
      glassMode: glassMode,
      child: paymentsAsync.when(
        data: (payments) {
          if (payments.isEmpty) {
            return _buildEmptyState(
              colors: colors,
              message: l10n.noPaymentsFound,
              icon: Icons.receipt_long_outlined,
              glassMode: glassMode,
            );
          }

          final sortedPayments = payments.toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.recentPayments,
                style: TextStyle(
                  color: _primaryTextColor(colors, glassMode),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ...sortedPayments.take(6).map(
                    (payment) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: _buildPaymentHistoryRow(
                        payment: payment,
                        ref: ref,
                        colors: colors,
                        l10n: l10n,
                        glassMode: glassMode,
                      ),
                    ),
                  ),
            ],
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              glassMode ? Colors.white : colors.primaryAccent,
            ),
          ),
        ),
        error: (error, _) => _buildEmptyState(
          colors: colors,
          message: error.toString(),
          icon: Icons.error_outline,
          glassMode: glassMode,
        ),
      ),
    );
  }

  Widget _buildPaymentHistoryRow({
    required Payment payment,
    required WidgetRef ref,
    required DynamicAppColors colors,
    required AppLocalizations l10n,
    required bool glassMode,
  }) {
    final currencyNotifier = ref.read(currencyProvider.notifier);
    final Color statusColor = _statusColor(payment.status, colors);
    final String formattedDate = DateFormat.yMMMd().format(payment.date);
    final String formattedType = _formatPaymentType(payment.type, l10n);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: glassMode ? 0.25 : 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _statusIcon(payment.status),
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
                currencyNotifier.formatAmount(payment.amount),
                style: TextStyle(
                  color: _primaryTextColor(colors, glassMode),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$formattedDate • $formattedType',
                style: TextStyle(
                  color: _secondaryTextColor(colors, glassMode),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: glassMode ? 0.25 : 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            payment.status.toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow({
    required DynamicAppColors colors,
    required bool glassMode,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: glassMode
                ? Colors.white.withValues(alpha: 0.2)
                : iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: glassMode ? Colors.white : iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: _secondaryTextColor(colors, glassMode),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: _primaryTextColor(colors, glassMode),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required DynamicAppColors colors,
    required String message,
    required IconData icon,
    required bool glassMode,
  }) {
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: glassMode ? Colors.white : colors.textSecondary,
          size: 28,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _secondaryTextColor(colors, glassMode),
          ),
        ),
      ],
    );

    if (glassMode) {
      return GlassContainer(
        padding: const EdgeInsets.all(20),
        child: child,
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceWithElevation(1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildErrorState({
    required DynamicAppColors colors,
    required AppLocalizations l10n,
    required Object error,
    required bool glassMode,
  }) {
    final child = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.error_outline,
          color: glassMode ? Colors.white : colors.error,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.somethingWentWrong,
                style: TextStyle(
                  color: _primaryTextColor(colors, glassMode),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                error.toString(),
                style: TextStyle(
                  color: _secondaryTextColor(colors, glassMode),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _sectionCard(
        colors: colors,
        glassMode: glassMode,
        child: child,
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'pending':
        return Icons.hourglass_bottom_rounded;
      case 'failed':
        return Icons.error_outline;
      case 'refunded':
        return Icons.refresh_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Color _statusColor(String status, DynamicAppColors colors) {
    switch (status.toLowerCase()) {
      case 'completed':
        return colors.success;
      case 'pending':
        return colors.warning;
      case 'failed':
        return colors.error;
      case 'refunded':
        return colors.info;
      default:
        return colors.textSecondary;
    }
  }

  String _formatPaymentType(String type, AppLocalizations l10n) {
    if (type.isEmpty) {
      return '-';
    }
    switch (type.toLowerCase()) {
      case 'rent':
        return l10n.rent;
      default:
        return type[0].toUpperCase() + type.substring(1);
    }
  }

  Widget _sectionCard({
    required DynamicAppColors colors,
    required Widget child,
    required bool glassMode,
    EdgeInsets padding = const EdgeInsets.all(20),
  }) {
    if (glassMode) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: GlassContainer(
          width: double.infinity,
          padding: padding,
          child: child,
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surfaceWithElevation(1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderLight),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }

  Color _primaryTextColor(DynamicAppColors colors, bool glassMode) =>
      glassMode ? Colors.white : colors.textPrimary;

  Color _secondaryTextColor(DynamicAppColors colors, bool glassMode) =>
      glassMode ? Colors.white.withValues(alpha: 0.8) : colors.textSecondary;
}
