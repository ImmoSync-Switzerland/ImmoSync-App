import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/core/providers/dynamic_colors_provider.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/payment/domain/models/payment.dart';
import 'package:immosync/features/payment/presentation/providers/payment_providers.dart';
import 'package:immosync/features/property/presentation/providers/property_providers.dart';
import '../../../../../l10n/app_localizations.dart';

class StripePaymentPage extends ConsumerStatefulWidget {
  final String? propertyId;
  final double? amount;
  final String? paymentType;

  const StripePaymentPage({
    super.key,
    this.propertyId,
    this.amount,
    this.paymentType,
  });

  @override
  ConsumerState<StripePaymentPage> createState() => _StripePaymentPageState();
}

class _StripePaymentPageState extends ConsumerState<StripePaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  CardFieldInputDetails? _cardFieldInputDetails;
  
  String? _selectedPropertyId;
  String? _selectedPaymentType;
  bool _isProcessing = false;
  bool _useStripe = true;

  final List<String> _paymentTypes = [
    'Rent',
    'Deposit',
    'Utilities',
    'Maintenance Fee',
    'Late Fee',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _selectedPropertyId = widget.propertyId;
    _selectedPaymentType = widget.paymentType ?? _paymentTypes.first;
    if (widget.amount != null) {
      _amountController.text = widget.amount.toString();
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
    final colors = ref.watch(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;
    final userProperties = ref.watch(tenantPropertiesProvider);

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Make Payment',
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
      body: userProperties.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: colors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load properties',
                style: TextStyle(
                  fontSize: 18,
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.refresh(tenantPropertiesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (properties) {
          if (properties.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.home_outlined,
                    size: 64,
                    color: colors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No properties found',
                    style: TextStyle(
                      fontSize: 18,
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You need to be assigned to a property to make payments',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Set default property if not set
          if (_selectedPropertyId == null || 
              !properties.any((p) => p.id == _selectedPropertyId)) {
            _selectedPropertyId = properties.first.id;
          }

          final selectedProperty = properties.firstWhere(
            (p) => p.id == _selectedPropertyId,
            orElse: () => properties.first,
          );

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildPropertySection(properties, selectedProperty, colors, l10n),
                const SizedBox(height: 24),
                _buildPaymentDetailsSection(colors, l10n),
                const SizedBox(height: 24),
                _buildPaymentMethodSection(colors, l10n),
                const SizedBox(height: 24),
                _buildNotesSection(colors, l10n),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(colors, l10n),
    );
  }

  Widget _buildPropertySection(dynamic properties, dynamic selectedProperty, DynamicAppColors colors, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Property',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceCards,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderLight),
          ),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedPropertyId,
                decoration: InputDecoration(
                  labelText: 'Select Property',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: properties.map<DropdownMenuItem<String>>((property) {
                  return DropdownMenuItem(
                    value: property.id,
                    child: Text('${property.address.street}, ${property.address.city}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPropertyId = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Monthly Rent:',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textSecondary,
                    ),
                  ),
                  Text(
                    '\$${selectedProperty.rentAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDetailsSection(DynamicAppColors colors, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceCards,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderLight),
          ),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedPaymentType,
                decoration: InputDecoration(
                  labelText: 'Payment Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _paymentTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentType = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount (\$)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Amount is required';
                  final amount = double.tryParse(value!);
                  if (amount == null || amount <= 0) return 'Please enter a valid amount';
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection(DynamicAppColors colors, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        
        // Payment method toggle
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colors.surfaceCards,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderLight),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _useStripe = true);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _useStripe ? colors.primaryAccent : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.credit_card,
                          size: 16,
                          color: _useStripe ? Colors.white : colors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Credit Card',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _useStripe ? Colors.white : colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _useStripe = false);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_useStripe ? colors.primaryAccent : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance,
                          size: 16,
                          color: !_useStripe ? Colors.white : colors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Bank Transfer',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: !_useStripe ? Colors.white : colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Stripe card field or bank transfer info
        if (_useStripe) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surfaceCards,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderLight),
            ),
            child: Column(
              children: [
                CardField(
                  onCardChanged: (card) {
                    setState(() {
                      _cardFieldInputDetails = card;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.security,
                      size: 16,
                      color: colors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your payment is processed securely by Stripe',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surfaceCards,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: colors.primaryAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Bank Transfer Instructions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Transfer funds to the following account and include your payment reference:',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Account: ImmoLink Payments\nIBAN: CH12 3456 7890 1234 5678\nReference: Your property ID',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textPrimary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNotesSection(DynamicAppColors colors, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Notes (Optional)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            hintText: 'Any additional information about this payment...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: colors.surfaceCards,
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildBottomBar(DynamicAppColors colors, AppLocalizations l10n) {
    final canPay = _useStripe 
        ? _cardFieldInputDetails?.complete == true && !_isProcessing
        : !_isProcessing;

    final amount = double.tryParse(_amountController.text) ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        border: Border(
          top: BorderSide(color: colors.borderLight),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (amount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colors.primaryAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canPay ? _handlePayment : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _useStripe ? 'Pay Now' : 'Record Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _handlePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final amount = double.parse(_amountController.text);
      
      if (_useStripe) {
        // Process Stripe payment
        await _processStripePayment(user, amount);
      } else {
        // Record bank transfer payment
        await _recordBankTransferPayment(user, amount);
      }

      // Success
      _showSuccessDialog();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _processStripePayment(dynamic user, double amount) async {
    // Create payment intent through backend
    final clientSecret = await ref.read(paymentServiceProvider).createPaymentIntent(
      amount: amount,
      propertyId: _selectedPropertyId!,
      tenantId: user.id,
      paymentType: _selectedPaymentType!.toLowerCase(),
    );

    // Process through Stripe
    await Stripe.instance.confirmPayment(
      paymentIntentClientSecret: clientSecret,
      data: const PaymentMethodParams.card(
        paymentMethodData: PaymentMethodData(),
      ),
    );

    // Create payment record
    await ref.read(paymentServiceProvider).createPayment(
      Payment(
        id: '',
        propertyId: _selectedPropertyId!,
        tenantId: user.id,
        amount: amount,
        date: DateTime.now(),
        status: 'completed',
        type: _selectedPaymentType!.toLowerCase(),
        paymentMethod: 'stripe',
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      ),
    );
  }

  Future<void> _recordBankTransferPayment(dynamic user, double amount) async {
    // Record bank transfer payment (pending status)
    await ref.read(paymentServiceProvider).createPayment(
      Payment(
        id: '',
        propertyId: _selectedPropertyId!,
        tenantId: user.id,
        amount: amount,
        date: DateTime.now(),
        status: 'pending',
        type: _selectedPaymentType!.toLowerCase(),
        paymentMethod: 'bank_transfer',
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      ),
    );
  }

  void _showSuccessDialog() {
    final colors = ref.read(dynamicColorsProvider);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceCards,
        title: Row(
          children: [
            Icon(Icons.check_circle, color: colors.success),
            const SizedBox(width: 8),
            Text(
              'Payment Submitted',
              style: TextStyle(color: colors.textPrimary),
            ),
          ],
        ),
        content: Text(
          _useStripe 
              ? 'Your payment has been processed successfully.'
              : 'Your payment has been recorded. Please complete the bank transfer using the provided details.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/payments');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryAccent,
            ),
            child: const Text('View Payments'),
          ),
        ],
      ),
    );
  }
}
