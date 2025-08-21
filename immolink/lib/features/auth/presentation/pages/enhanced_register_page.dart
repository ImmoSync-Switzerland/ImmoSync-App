import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:immolink/features/auth/presentation/providers/register_provider.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';

class EnhancedRegisterPage extends ConsumerStatefulWidget {
  const EnhancedRegisterPage({super.key});

  @override
  ConsumerState<EnhancedRegisterPage> createState() => _EnhancedRegisterPageState();
}

class _EnhancedRegisterPageState extends ConsumerState<EnhancedRegisterPage> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _taxIdController = TextEditingController();
  
  DateTime? _selectedBirthDate;
  String _selectedRole = 'landlord';
  bool _isCompany = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: colors.primaryBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(l10n, colors),
                    const SizedBox(height: 32),
                    _buildRegistrationForm(l10n, colors),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, DynamicAppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        const SizedBox(height: 16),
        Text(
          'Konto erstellen',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Registrieren Sie sich als Vermieter',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm(AppLocalizations l10n, DynamicAppColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: colors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEntityTypeSwitcher(colors),
            const SizedBox(height: 24),
            
            if (_isCompany) ...[
              _buildCompanyFields(l10n, colors),
            ] else ...[
              _buildIndividualFields(l10n, colors),
            ],
            
            const SizedBox(height: 24),
            _buildCommonFields(l10n, colors),
            const SizedBox(height: 32),
            _buildRegisterButton(l10n, colors),
            const SizedBox(height: 24),
            _buildLoginLink(l10n, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildEntityTypeSwitcher(DynamicAppColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.primaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isCompany = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: !_isCompany ? colors.primaryAccent : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Text(
                  'Einzelperson',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !_isCompany ? Colors.white : colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isCompany = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: _isCompany ? colors.primaryAccent : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  'Firma',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isCompany ? Colors.white : colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualFields(AppLocalizations l10n, DynamicAppColors colors) {
    return Column(
      children: [
        _buildTextField(
          controller: _fullNameController,
          label: 'Vollständiger Name',
          icon: Icons.person,
          colors: colors,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Bitte geben Sie Ihren Namen ein';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _addressController,
          label: 'Adresse',
          icon: Icons.location_on,
          colors: colors,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Bitte geben Sie Ihre Adresse ein';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildBirthDateField(colors),
      ],
    );
  }

  Widget _buildCompanyFields(AppLocalizations l10n, DynamicAppColors colors) {
    return Column(
      children: [
        _buildTextField(
          controller: _companyNameController,
          label: 'Firmenname',
          icon: Icons.business,
          colors: colors,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Bitte geben Sie den Firmennamen ein';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _fullNameController,
          label: 'Ansprechpartner',
          icon: Icons.person,
          colors: colors,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Bitte geben Sie den Ansprechpartner ein';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _companyAddressController,
          label: 'Firmenadresse',
          icon: Icons.location_on,
          colors: colors,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Bitte geben Sie die Firmenadresse ein';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _taxIdController,
          label: 'Steuernummer (optional)',
          icon: Icons.receipt,
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildCommonFields(AppLocalizations l10n, DynamicAppColors colors) {
    return Column(
      children: [
        _buildTextField(
          controller: _emailController,
          label: 'E-Mail',
          icon: Icons.email,
          colors: colors,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Bitte geben Sie Ihre E-Mail ein';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Bitte geben Sie eine gültige E-Mail ein';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Telefonnummer',
          icon: Icons.phone,
          colors: colors,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Bitte geben Sie Ihre Telefonnummer ein';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          label: 'Passwort',
          icon: Icons.lock,
          colors: colors,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
              color: colors.textSecondary,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Bitte geben Sie ein Passwort ein';
            }
            if (value.length < 6) {
              return 'Passwort muss mindestens 6 Zeichen lang sein';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _confirmPasswordController,
          label: 'Passwort bestätigen',
          icon: Icons.lock_outline,
          colors: colors,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
              color: colors.textSecondary,
            ),
            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Bitte bestätigen Sie Ihr Passwort';
            }
            if (value != _passwordController.text) {
              return 'Passwörter stimmen nicht überein';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required DynamicAppColors colors,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(color: colors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.textSecondary),
        prefixIcon: Icon(icon, color: colors.primaryAccent),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: colors.primaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primaryAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.error),
        ),
      ),
    );
  }

  Widget _buildBirthDateField(DynamicAppColors colors) {
    return TextFormField(
      readOnly: true,
      onTap: () => _selectBirthDate(),
      style: TextStyle(color: colors.textPrimary),
      decoration: InputDecoration(
        labelText: 'Geburtsdatum',
        labelStyle: TextStyle(color: colors.textSecondary),
        prefixIcon: Icon(Icons.cake, color: colors.primaryAccent),
        suffixIcon: Icon(Icons.calendar_today, color: colors.textSecondary),
        filled: true,
        fillColor: colors.primaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primaryAccent, width: 2),
        ),
        hintText: _selectedBirthDate != null 
            ? '${_selectedBirthDate!.day}.${_selectedBirthDate!.month}.${_selectedBirthDate!.year}'
            : 'Geburtsdatum auswählen',
        hintStyle: TextStyle(color: colors.textSecondary),
      ),
      validator: !_isCompany ? (value) {
        if (_selectedBirthDate == null) {
          return 'Bitte wählen Sie Ihr Geburtsdatum';
        }
        return null;
      } : null,
    );
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // Must be 18+
      builder: (context, child) {
        final colors = ref.read(dynamicColorsProvider);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: colors.primaryAccent),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  Widget _buildRegisterButton(AppLocalizations l10n, DynamicAppColors colors) {
    final registerState = ref.watch(registerProvider);
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: registerState.isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primaryAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: registerState.isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                'Registrieren',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginLink(AppLocalizations l10n, DynamicAppColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Bereits ein Konto? ',
          style: TextStyle(color: colors.textSecondary),
        ),
        TextButton(
          onPressed: () => context.push('/login'),
          child: Text(
            'Anmelden',
            style: TextStyle(
              color: colors.primaryAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(registerProvider.notifier);
    
    try {
      await notifier.register(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        phone: _phoneController.text.trim(),
        isCompany: _isCompany,
        companyName: _isCompany ? _companyNameController.text.trim() : null,
        companyAddress: _isCompany ? _companyAddressController.text.trim() : null,
        taxId: _isCompany ? _taxIdController.text.trim() : null,
        address: !_isCompany ? _addressController.text.trim() : null,
        birthDate: !_isCompany ? _selectedBirthDate : null,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrierung erfolgreich! Sie können sich jetzt anmelden.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        final error = ref.read(registerProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registrierung fehlgeschlagen: ${error ?? "Unbekannter Fehler"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
