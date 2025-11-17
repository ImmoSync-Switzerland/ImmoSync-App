import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/payment/presentation/providers/payment_providers.dart';
import 'package:immosync/features/property/presentation/providers/property_providers.dart';
import 'package:intl/intl.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/widgets/common_bottom_nav.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/currency_provider.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context)!;
    final isLandlord = currentUser?.role == 'landlord';

    // Set navigation index to Reports (3) when this page is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(routeAwareNavigationProvider.notifier).setIndex(3);
    });

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        title: Text(
          l10n.analyticsAndReports,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () {
            // Navigate back to dashboard instead of popping
            context.go('/home');
          },
        ),
      ),
      bottomNavigationBar: const CommonBottomNav(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryBackground, AppColors.surfaceCards],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportPeriod(context),
              const SizedBox(height: 24),
              isLandlord
                  ? _buildLandlordReports(context, ref)
                  : _buildTenantReports(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportPeriod(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceCards,
            AppColors.luxuryGradientStart.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.reportPeriod,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: AppColors.primaryAccent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.thisMonth,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandlordReports(BuildContext context, WidgetRef ref) {
    final properties = ref.watch(landlordPropertiesProvider);
    final payments = ref.watch(landlordPaymentsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFinancialSummary(context, properties, payments, ref),
        const SizedBox(height: 24),
        _buildOccupancySection(context, properties),
      ],
    );
  }

  Widget _buildTenantReports(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(tenantPaymentsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPaymentSummary(context, payments, ref),
        const SizedBox(height: 24),
        _buildPaymentHistory(payments, ref),
      ],
    );
  }

  Widget _buildFinancialSummary(BuildContext context, AsyncValue properties,
      AsyncValue payments, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceCards,
            AppColors.luxuryGradientStart.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.financialSummary,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          _buildFinancialMetric(
            icon: Icons.attach_money,
            title: AppLocalizations.of(context)!.totalIncome,
            value: ref.read(currencyProvider.notifier).formatAmount(0.00),
            color: Colors.green,
            iconColor: Colors.green,
          ),
          const SizedBox(height: 16),
          _buildFinancialMetric(
            icon: Icons.money_off,
            title: AppLocalizations.of(context)!.outstandingPayments,
            value: ref.read(currencyProvider.notifier).formatAmount(0.00),
            color: Colors.red,
            iconColor: Colors.red,
          ),
          const SizedBox(height: 16),
          _buildFinancialMetric(
            icon: Icons.home,
            title: AppLocalizations.of(context)!.occupancyRate,
            value: '100.0%',
            color: Colors.blue,
            iconColor: Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildFinancialMetric(
            icon: Icons.apartment,
            title: AppLocalizations.of(context)!.totalProperties,
            value: '1',
            color: Colors.purple,
            iconColor: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialMetric({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildOccupancySection(BuildContext context, AsyncValue properties) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceCards,
            AppColors.luxuryGradientStart.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.occupancyRate,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          const Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 20,
                    backgroundColor: AppColors.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '100.0%',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '1 of 1',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(
      BuildContext context, AsyncValue<List<dynamic>> payments, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceCards,
            AppColors.luxuryGradientStart.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.paymentSummary,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          payments.when(
            data: (paymentsList) {
              // Calculate total payments
              final totalPayments = paymentsList.fold<double>(
                0,
                (sum, payment) => sum + payment.amount,
              );

              // Calculate completed payments
              final completedPayments = paymentsList
                  .where((p) => p.status == 'completed')
                  .fold<double>(0, (sum, p) => sum + p.amount);

              // Calculate pending payments
              final pendingPayments = paymentsList
                  .where((p) => p.status == 'pending')
                  .fold<double>(0, (sum, p) => sum + p.amount);

              return Column(
                children: [
                  _buildFinancialMetric(
                    icon: Icons.attach_money,
                    title: 'Total Payments',
                    value: ref
                        .read(currencyProvider.notifier)
                        .formatAmount(totalPayments),
                    color: Colors.blue,
                    iconColor: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  _buildFinancialMetric(
                    icon: Icons.check_circle,
                    title: 'Completed Payments',
                    value: ref
                        .read(currencyProvider.notifier)
                        .formatAmount(completedPayments),
                    color: Colors.green,
                    iconColor: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  _buildFinancialMetric(
                    icon: Icons.hourglass_empty,
                    title: 'Pending Payments',
                    value: ref
                        .read(currencyProvider.notifier)
                        .formatAmount(pendingPayments),
                    color: Colors.orange,
                    iconColor: Colors.orange,
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
              ),
            ),
            error: (error, stack) => Center(
              child: Text(
                'Error loading payments: $error',
                style: const TextStyle(color: AppColors.textTertiary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory(
      AsyncValue<List<dynamic>> payments, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceCards,
            AppColors.luxuryGradientStart.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment History',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          payments.when(
            data: (paymentsList) {
              if (paymentsList.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No payment history found',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }

              // Sort payments by date
              paymentsList.sort((a, b) => b.date.compareTo(a.date));

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: paymentsList.length > 5 ? 5 : paymentsList.length,
                separatorBuilder: (context, index) => const Divider(
                  color: AppColors.borderLight,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final payment = paymentsList[index];

                  Color statusColor;
                  switch (payment.status) {
                    case 'completed':
                      statusColor = Colors.green;
                      break;
                    case 'pending':
                      statusColor = Colors.orange;
                      break;
                    case 'failed':
                      statusColor = Colors.red;
                      break;
                    default:
                      statusColor = Colors.grey;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
                                ? Icons.check_circle
                                : payment.status == 'pending'
                                    ? Icons.hourglass_empty
                                    : Icons.error,
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
                                ref
                                    .read(currencyProvider.notifier)
                                    .formatAmount(payment.amount),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${payment.type.toUpperCase()} - ${DateFormat('MMM d, yyyy').format(payment.date)}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            payment.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
              ),
            ),
            error: (error, stack) => Center(
              child: Text(
                'Error loading payments: $error',
                style: const TextStyle(color: AppColors.textTertiary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
