import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:immolink/features/auth/presentation/providers/register_provider.dart';
import '../../../../core/theme/app_colors.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedRole = 'customer';

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
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF), // Pure white
              Color(0xFFF0F4FF), // Very light blue
              Color(0xFFE0EAFF), // Light blue
              Color(0xFFD1E0FF), // Soft blue
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 24.0 : screenSize.width * 0.1,
                  vertical: 32.0,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildRegistrationForm(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
              onPressed: () => context.pop(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Create Account',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B), // Dark slate
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Join ImmoLink today',
              style: TextStyle(
                color: Color(0xFF64748B), // Slate gray
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isSmallScreen ? 32.0 : 40.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 32,
                offset: const Offset(0, 16),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.8),
                blurRadius: 24,
                offset: const Offset(0, -8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isSmallScreen)
                Row(
                  children: [
                    Expanded(child: _buildTextField(
                      controller: _fullNameController,
                      icon: Icons.person_outline,
                      label: 'Full Name',
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      label: 'Email',
                    )),
                  ],
                )
              else ...[
                _buildTextField(
                  controller: _fullNameController,
                  icon: Icons.person_outline,
                  label: 'Full Name',
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: _emailController,
                  icon: Icons.email_outlined,
                  label: 'Email',
                ),
              ],
              const SizedBox(height: 24),
              _buildDatePicker(),
              const SizedBox(height: 24),
              _buildRoleSelector(),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _passwordController,
                icon: Icons.lock_outline,
                label: 'Password',
                isPassword: true,
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _confirmPasswordController,
                icon: Icons.lock_outline,
                label: 'Confirm Password',
                isPassword: true,
              ),
              const SizedBox(height: 32),
              _buildRegisterButton(),
              const SizedBox(height: 24),
              _buildLoginLink(),
            ],
          ),
        );
      },
    );
  }
  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        hintStyle: TextStyle(color: Colors.grey.shade500),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.9),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
      ),
    );
  }
  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now().subtract(const Duration(days: 6570)),
          firstDate: DateTime.now().subtract(const Duration(days: 36500)),
          lastDate: DateTime.now().subtract(const Duration(days: 6570)),
        );
        if (date != null) {
          setState(() => _selectedDate = date);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Text(
              _selectedDate != null 
                ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                : 'Birth Date',
              style: TextStyle(color: _selectedDate != null ? Colors.black87 : Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am a:',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildRoleOption('tenant', 'Tenant'),
            const SizedBox(width: 16),
            _buildRoleOption('landlord', 'Landlord'),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleOption(String value, String label) {
    final isSelected = _selectedRole == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedRole = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.7),
            border: Border.all(
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    final registerState = ref.watch(registerProvider);
  
    return Column(
      children: [
        if (registerState.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              registerState.error!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: registerState.isLoading 
              ? null 
              : () {
                  if (_validateForm()) {
                    ref.read(registerProvider.notifier).register(
                      fullName: _fullNameController.text,
                      email: _emailController.text,
                      password: _passwordController.text,
                      birthDate: _selectedDate!,
                      role: _selectedRole,
                    );
                  }
                },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: registerState.isLoading
                ? const CircularProgressIndicator()
                : const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  bool _validateForm() {
    if (_fullNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return false;
    }

    if (!_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return false;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return false;
    }

    return true;
  }
  Widget _buildLoginLink() {
    return Center(
      child: TextButton(
        onPressed: () => context.pop(),
        child: const Text(
          'Already have an account? Login',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
