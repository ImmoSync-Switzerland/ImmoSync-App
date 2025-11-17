import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';

class CompleteProfilePage extends ConsumerStatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  ConsumerState<CompleteProfilePage> createState() =>
      _CompleteProfilePageState();
}

class _CompleteProfilePageState extends ConsumerState<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _roleController = ValueNotifier<String>('tenant');
  final _isCompanyController = ValueNotifier<bool>(false);
  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _birthDate;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    _isCompanyController.dispose();
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _taxIdController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil vervollständigen'),
        backgroundColor: AppColors.primaryAccent,
      ),
      body: authState.missingFields.isEmpty && !authState.needsProfileCompletion
          ? _buildAlreadyComplete()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bitte füllen Sie die fehlenden Pflichtfelder aus.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (authState.missingFields.contains('fullName'))
                      _buildTextField(
                          _fullNameController, 'Vollständiger Name'),
                    if (authState.missingFields.contains('phone'))
                      _buildTextField(_phoneController, 'Telefon'),
                    if (authState.missingFields.contains('role'))
                      _buildRoleSelector(),
                    if (authState.missingFields.contains('isCompany'))
                      _buildIsCompanyToggle(),
                    ValueListenableBuilder<bool>(
                      valueListenable: _isCompanyController,
                      builder: (_, isCompany, __) {
                        if (!isCompany) return const SizedBox.shrink();
                        return Column(
                          children: [
                            if (authState.missingFields.contains('companyName'))
                              _buildTextField(
                                  _companyNameController, 'Firmenname'),
                            if (authState.missingFields
                                .contains('companyAddress'))
                              _buildTextField(
                                  _companyAddressController, 'Firmenadresse'),
                            _buildOptionalTextField(
                                _taxIdController, 'Steuer-ID (optional)'),
                          ],
                        );
                      },
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: _isCompanyController,
                      builder: (_, isCompany, __) {
                        if (isCompany) return const SizedBox.shrink();
                        return Column(
                          children: [
                            if (authState.missingFields.contains('address'))
                              _buildTextField(_addressController, 'Adresse'),
                            if (authState.missingFields.contains('birthDate'))
                              _buildBirthDatePicker(),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: authState.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: authState.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Speichern und fortfahren',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    if (authState.error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        authState.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ]
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAlreadyComplete() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text('Profil bereits vollständig.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Zum Dashboard'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        validator: (v) => (v == null || v.isEmpty) ? 'Erforderlich' : null,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  Widget _buildOptionalTextField(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(
            labelText: '$label (optional)', border: const OutlineInputBorder()),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ValueListenableBuilder<String>(
        valueListenable: _roleController,
        builder: (_, role, __) => DropdownButtonFormField<String>(
          initialValue: role,
          items: const [
            DropdownMenuItem(value: 'tenant', child: Text('Mieter')),
            DropdownMenuItem(value: 'landlord', child: Text('Vermieter')),
          ],
          onChanged: (v) => _roleController.value = v ?? 'tenant',
          decoration: const InputDecoration(
            labelText: 'Rolle',
            border: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }

  Widget _buildIsCompanyToggle() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ValueListenableBuilder<bool>(
        valueListenable: _isCompanyController,
        builder: (_, isCompany, __) => SwitchListTile(
          value: isCompany,
          onChanged: (v) => _isCompanyController.value = v,
          title: const Text('Firmenkonto'),
        ),
      ),
    );
  }

  Widget _buildBirthDatePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            firstDate: DateTime(1900),
            lastDate: DateTime(now.year - 16, now.month, now.day),
            initialDate: DateTime(now.year - 30),
          );
          if (picked != null) {
            setState(() {
              _birthDate = picked;
            });
          }
        },
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Geburtsdatum',
            border: OutlineInputBorder(),
          ),
          child: Text(
            _birthDate == null
                ? 'Wählen...'
                : _birthDate!.toIso8601String().split('T').first,
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = ref.read(authProvider);
    final fields = <String, dynamic>{};
    if (auth.missingFields.contains('fullName')) {
      fields['fullName'] = _fullNameController.text.trim();
    }
    if (auth.missingFields.contains('phone')) {
      fields['phone'] = _phoneController.text.trim();
    }
    if (auth.missingFields.contains('role')) {
      fields['role'] = _roleController.value;
    }
    if (auth.missingFields.contains('isCompany')) {
      fields['isCompany'] = _isCompanyController.value;
    }
    if (_isCompanyController.value) {
      if (auth.missingFields.contains('companyName')) {
        fields['companyName'] = _companyNameController.text.trim();
      }
      if (auth.missingFields.contains('companyAddress')) {
        fields['companyAddress'] = _companyAddressController.text.trim();
      }
      if (_taxIdController.text.isNotEmpty) {
        fields['taxId'] = _taxIdController.text.trim();
      }
    } else {
      if (auth.missingFields.contains('address')) {
        fields['address'] = _addressController.text.trim();
      }
      if (auth.missingFields.contains('birthDate') && _birthDate != null) {
        fields['birthDate'] = _birthDate;
      }
    }
    await ref.read(authProvider.notifier).completeSocialProfile(fields: fields);
    final newState = ref.read(authProvider);
    if (mounted &&
        newState.isAuthenticated &&
        !newState.needsProfileCompletion) {
      context.go('/home');
    }
  }
}
