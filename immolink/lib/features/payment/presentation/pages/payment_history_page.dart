import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:immosync/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/payment/domain/models/payment.dart';
import 'package:immosync/features/payment/presentation/providers/payment_providers.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

const _backgroundStart = Color(0xFF0A1128);
const _backgroundEnd = Colors.black;
const _cardColor = Color(0xFF1C1C1E);
const _surfaceDark = Color(0xFF2C2C2E);
const _textPrimary = Colors.white;
const _textSecondary = Colors.white70;
const _textTertiary = Colors.white54;
const _chipGradientDark = Color(0xFF2E7D32);
const _chipGradientLight = Color(0xFF66BB6A);

class PaymentHistoryPage extends ConsumerStatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  ConsumerState<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends ConsumerState<PaymentHistoryPage> {
  String? _selectedStatus;
  String? _selectedType;

  List<Payment> _filterPayments(List<Payment> payments) {
    return payments.where((payment) {
      final bool statusMatch =
          _selectedStatus == null || payment.status == _selectedStatus;
      final bool typeMatch =
          _selectedType == null || payment.type == _selectedType;
      return statusMatch && typeMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context)!;
    final paymentsAsync = currentUser?.role == 'landlord'
        ? ref.watch(landlordPaymentsProvider)
        : ref.watch(tenantPaymentsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          l10n.paymentHistory,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: _textPrimary,
            size: 20,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_backgroundStart, _backgroundEnd],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(l10n),
                const SizedBox(height: 16),
                _buildFilterCard(l10n),
                const SizedBox(height: 20),
                paymentsAsync.when(
                  data: (paymentsList) {
                    final filteredPayments = _filterPayments(paymentsList);
                    if (filteredPayments.isEmpty) {
                      return _buildEmptyStateCard(l10n);
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredPayments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final payment = filteredPayments[index];
                        final isIncoming = currentUser?.role == 'landlord';
                        return _buildTransactionCard(payment, isIncoming);
                      },
                    );
                  },
                  loading: () => BentoCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _chipGradientLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.loadingPaymentHistory,
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  error: (error, stack) => BentoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 44,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.errorLoadingPaymentHistory,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              ref.invalidate(currentUser?.role == 'landlord'
                                  ? landlordPaymentsProvider
                                  : tenantPaymentsProvider);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _textPrimary,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.16),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(l10n.retry),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(AppLocalizations l10n) {
    return BentoCard(
      glowColor: const Color(0xFF2E7D32),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF66BB6A).withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: Color(0xFF66BB6A),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.paymentHistory,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.trackAllTransactions,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard(AppLocalizations l10n) {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.filter_list_rounded,
                color: _textPrimary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                l10n.filterPayments,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Status',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildFilterPill(
                  label: 'All',
                  selected: _selectedStatus == null,
                  onTap: () => _setStatus(null)),
              _buildFilterPill(
                  label: 'Completed',
                  selected: _selectedStatus == 'completed',
                  onTap: () => _setStatus('completed')),
              _buildFilterPill(
                  label: 'Pending',
                  selected: _selectedStatus == 'pending',
                  onTap: () => _setStatus('pending')),
              _buildFilterPill(
                  label: 'Failed',
                  selected: _selectedStatus == 'failed',
                  onTap: () => _setStatus('failed')),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Type',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildFilterPill(
                label: l10n.allTypes,
                selected: _selectedType == null,
                onTap: () => _setType(null),
              ),
              _buildFilterPill(
                label: 'Rent',
                selected: _selectedType == 'rent',
                onTap: () => _setType('rent'),
              ),
              _buildFilterPill(
                label: 'Maintenance',
                selected: _selectedType == 'maintenance',
                onTap: () => _setType('maintenance'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _setStatus(String? value) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedStatus = value;
    });
  }

  void _setType(String? value) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedType = value;
    });
  }

  Widget _buildFilterPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? null : _surfaceDark,
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [_chipGradientDark, _chipGradientLight],
                )
              : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFF2E7D32).withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.10),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? _textPrimary : _textTertiary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard(AppLocalizations l10n) {
    return BentoCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card_rounded,
              size: 64,
              color: Colors.white.withValues(alpha: 0.22),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.noPaymentHistoryFound,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your transactions will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: _textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Payment payment, bool isIncoming) {
    final amountText =
        NumberFormat.currency(symbol: 'CHF ').format(payment.amount);
    final dateText = DateFormat('MMM d, yyyy').format(payment.date);

    final arrowColor = isIncoming ? const Color(0xFF66BB6A) : Colors.redAccent;
    final arrowIcon =
        isIncoming ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;

    return BentoCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: arrowColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: arrowColor.withValues(alpha: 0.28),
                width: 1,
              ),
            ),
            child: Icon(
              arrowIcon,
              color: arrowColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.type.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amountText,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF66BB6A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                payment.status.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BentoCard extends StatelessWidget {
  const BentoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.glowColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: glowColor == null
            ? null
            : [
                BoxShadow(
                  color: glowColor!.withValues(alpha: 0.22),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: child,
    );
  }
}
