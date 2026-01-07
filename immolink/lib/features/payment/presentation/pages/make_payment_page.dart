import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/payment/domain/models/payment.dart';
import 'package:immosync/features/payment/presentation/providers/payment_providers.dart';
import 'package:immosync/features/property/presentation/providers/property_providers.dart';
import 'package:immosync/features/property/domain/models/property.dart';
import 'package:immosync/core/theme/app_colors.dart';
import 'package:immosync/l10n/app_localizations.dart';

const _backgroundStart = Color(0xFF0A1128);
const _backgroundEnd = Colors.black;
const _cardColor = Color(0xFF1C1C1E);
const _fieldColor = Color(0xFF2C2C2E);
const _textPrimary = Colors.white;
const _textSecondary = Colors.white70;

const _fieldBorderRadius = BorderRadius.all(Radius.circular(12));

class MakePaymentPage extends ConsumerStatefulWidget {
  final String? propertyId;

  const MakePaymentPage({super.key, this.propertyId});

  @override
  ConsumerState<MakePaymentPage> createState() => _MakePaymentPageState();
}

class _MakePaymentPageState extends ConsumerState<MakePaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedPropertyId;
  String? _selectedPaymentMethod;
  String? _selectedPaymentType;

  final List<String> _paymentMethods = [
    'Credit Card',
    'Bank Transfer',
    'PayPal',
    'Other'
  ];

  final List<String> _paymentTypes = ['Rent', 'Deposit', 'Fee', 'Other'];

  @override
  void initState() {
    super.initState();
    _selectedPropertyId = widget.propertyId;
    _selectedPaymentMethod = _paymentMethods.first;
    _selectedPaymentType = _paymentTypes.first;
  }

  String _formatAddress(Property property) {
    final street = property.address.street.trim();
    final city = property.address.city.trim();
    final postal = property.address.postalCode.trim();
    final parts = [
      if (street.isNotEmpty) street,
      if (postal.isNotEmpty || city.isNotEmpty)
        [postal, city].where((e) => e.isNotEmpty).join(' '),
    ].where((e) => e.isNotEmpty).toList();
    final l10n = AppLocalizations.of(context)!;
    return parts.isNotEmpty ? parts.join(', ') : l10n.property;
  }

  String _paymentTypeDisplay(AppLocalizations l10n, String type) {
    switch (type.toLowerCase()) {
      case 'rent':
        return l10n.rent;
      case 'deposit':
        return l10n.deposit;
      case 'fee':
        return l10n.fee;
      default:
        return l10n.other;
    }
  }

  String _paymentMethodDisplay(AppLocalizations l10n, String method) {
    switch (method.toLowerCase()) {
      case 'credit card':
        return l10n.creditDebitCard;
      case 'bank transfer':
        return l10n.bankTransfer;
      case 'paypal':
        return l10n.paypal;
      default:
        return l10n.other;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProperties = ref.watch(tenantPropertiesProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          l10n.makePayment,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: userProperties.when(
          data: (properties) {
            if (properties.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.home_outlined,
                      size: 64,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noPropertiesFound,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.noPropertiesToMakePaymentsFor,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'You have no properties to make payments for.',
                        style: TextStyle(
                          fontSize: 14,
                          color: _textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              if (_selectedPropertyId == null ||
                  !properties.any((p) => p.id == _selectedPropertyId)) {
                _selectedPropertyId = properties.first.id;
              }

              final selectedProperty = properties.firstWhere(
                (p) => p.id == _selectedPropertyId,
                orElse: () => properties.first,
              );

              if (_amountController.text.isEmpty) {
                _amountController.text =
                    selectedProperty.outstandingPayments.toString();
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPropertySection(properties, selectedProperty),
                      const SizedBox(height: 24),
                      _buildPaymentDetailsSection(),
                      const SizedBox(height: 24),
                      _buildNotesSection(),
                      const SizedBox(height: 32),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPropertySection(properties, selectedProperty),
                  const SizedBox(height: 24),
                  _buildPaymentDetailsSection(),
                  const SizedBox(height: 24),
                  _buildNotesSection(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                ],
              ),
            );
          },
          loading: () => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                    strokeWidth: 2.5,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  l10n.loadingProperties,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ],
              ),
            ),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  l10n.errorLoadingProperties,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: _textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPropertySection(
      List<Property> properties, Property selectedProperty) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.property,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 14,
            ),
            decoration: const InputDecoration(
              filled: true,
              fillColor: _fieldColor,
              border: OutlineInputBorder(
                borderRadius: _fieldBorderRadius,
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: _fieldBorderRadius,
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: _fieldBorderRadius,
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: properties.map((property) {
              final addressLabel = _formatAddress(property);
              return DropdownMenuItem<String>(
                value: property.id,
                child: Text(
                  addressLabel,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _textPrimary),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.primaryAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.outstandingPaymentsWithAmount(
                        'CHF ${selectedProperty.outstandingPayments}',
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsSection() {
    final l10n = AppLocalizations.of(context)!;
    // Ensure selections remain valid & unique
    if (_selectedPaymentType != null &&
        !_paymentTypes.contains(_selectedPaymentType)) {
      _selectedPaymentType = _paymentTypes.first;
    }
    if (_selectedPaymentMethod != null &&
        !_paymentMethods.contains(_selectedPaymentMethod)) {
      _selectedPaymentMethod = _paymentMethods.first;
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.paymentDetailsTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.paymentType,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedPaymentType,
                      dropdownColor: _fieldColor,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _textSecondary,
                      ),
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: _fieldColor,
                        border: OutlineInputBorder(
                          borderRadius: _fieldBorderRadius,
                          borderSide: BorderSide.none,
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedPaymentType,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                          dropdownColor: AppColors.surfaceCards,
                          items: _paymentTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(_paymentTypeDisplay(l10n, type)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedPaymentType = newValue;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.paymentMethod,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      items: _paymentTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(
                            type,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _textPrimary),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedPaymentType = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedPaymentMethod,
                      dropdownColor: _fieldColor,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _textSecondary,
                      ),
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: _fieldColor,
                        border: OutlineInputBorder(
                          borderRadius: _fieldBorderRadius,
                          borderSide: BorderSide.none,
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedPaymentMethod,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                          dropdownColor: AppColors.surfaceCards,
                          items: _paymentMethods.map((method) {
                            return DropdownMenuItem<String>(
                              value: method,
                              child: Text(_paymentMethodDisplay(l10n, method)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedPaymentMethod = newValue;
                            });
                          },
                        ),
                      ),
                      items: _paymentMethods.map((method) {
                        return DropdownMenuItem<String>(
                          value: method,
                          child: Text(
                            method,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _textPrimary),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedPaymentMethod = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${l10n.amount} (CHF)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Amount (CHF)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            cursorColor: Colors.greenAccent,
            decoration: const InputDecoration(
              filled: true,
              fillColor: _fieldColor,
              hintText: 'Enter amount',
              hintStyle: TextStyle(
                color: Colors.white54,
              ),
              child: TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: l10n.enterAmount,
                  hintStyle: const TextStyle(
                    color: AppColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  prefixText: 'CHF ',
                  prefixStyle: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterAmount;
                  }
                  if (double.tryParse(value) == null) {
                    return l10n.pleaseEnterValidNumber;
                  }
                  if (double.parse(value) <= 0) {
                    return l10n.amountMustBeGreaterThanZero;
                  }
                  return null;
                },
              ),
            ),
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an amount';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              if (double.parse(value) <= 0) {
                return 'Amount must be greater than 0';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.notesOptional,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              border: OutlineInputBorder(
                borderRadius: _fieldBorderRadius,
                borderSide: BorderSide.none,
              ),
              child: TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.addAdditionalNotes,
                  hintStyle: const TextStyle(
                    color: AppColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: _fieldBorderRadius,
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.all(16),
            ),
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _submitPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAccent,
          foregroundColor: AppColors.textOnAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.payment,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.submitPayment,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
      child: GestureDetector(
        onTap: _submitPayment,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF22D3EE)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.credit_card,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 10),
              Text(
                'Submit Payment',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitPayment() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPropertyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectProperty),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.userNotAuthenticated),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.processingPayment,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final payment = Payment(
        id: '',
        tenantId: currentUser.id,
        propertyId: _selectedPropertyId!,
        amount: double.parse(_amountController.text),
        type: _selectedPaymentType!.toLowerCase(),
        paymentMethod: _selectedPaymentMethod!.toLowerCase(),
        status: 'pending',
        date: DateTime.now(),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      await ref.read(paymentNotifierProvider.notifier).createPayment(payment);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.paymentSubmittedSuccessfully),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        context.pop(); // Return to previous page
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToSubmitPayment(e)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class BentoCard extends StatelessWidget {
  const BentoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.backgroundColor = _cardColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
