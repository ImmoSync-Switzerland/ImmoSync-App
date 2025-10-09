import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
// Removed http_parser import; no longer using multipart upload
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/db_config.dart';
import '../../../../core/widgets/mongo_image.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/services/user_service.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _userService = UserService();
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;
  File? _selectedImageFile;
  String? _uploadedImageIdOrUrl;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Load current user data
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      _nameController.text = currentUser.fullName;
      _emailController.text = currentUser.email;
      // _phoneController.text = currentUser.phone ?? '';
    }

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final colors = ref.watch(dynamicColorsProvider);

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: _buildAppBar(colors),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(colors),
                      const SizedBox(height: 32),
                      _buildProfileImageSection(currentUser, colors),
                      const SizedBox(height: 32),
                      _buildFormSection(colors),
                      const SizedBox(height: 40),
                      _buildActionButtons(colors),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(DynamicAppColors colors) {
    return AppBar(
      backgroundColor: colors.primaryBackground,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.surfaceCards,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.borderLight,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadowColor,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_back_ios_new,
            color: colors.textPrimary,
            size: 18,
          ),
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          context.pop();
        },
      ),
      title: Text(
        'Edit Profile',
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildHeaderSection(DynamicAppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Information',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Update your personal information and account details',
          style: TextStyle(
            fontSize: 16,
            color: colors.textTertiary,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImageSection(user, DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surfaceCards,
            colors.luxuryGradientStart,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColorMedium,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.primaryAccent.withValues(alpha: 0.1),
                      colors.luxuryGold.withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border.all(
                    color: colors.primaryAccent.withValues(alpha: 0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadowColor,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: _buildAvatarContent(user, colors),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showImagePickerDialog();
                  },
                  child: Container(
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
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.primaryBackground,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primaryAccent.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? 'User Name',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'user@example.com',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textTertiary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.luxuryGold.withValues(alpha: 0.1),
                        colors.luxuryGold.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.luxuryGold.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    user?.role.toUpperCase() ?? 'USER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.luxuryGold,
                      letterSpacing: 0.5,
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

  Widget _buildFormSection(DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surfaceCards,
            colors.accentLight.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColorMedium,
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors.primaryAccent.withValues(alpha: 0.2),
                        colors.primaryAccent.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.primaryAccent.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    color: colors.primaryAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Personal Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _buildInputField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your full name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
              colors: colors,
            ),
            const SizedBox(height: 20),
            _buildInputField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email_outlined,
              enabled: false,
              suffixIcon: Icons.lock_outline,
              colors: colors,
            ),
            const SizedBox(height: 12),
            Text(
              'Email cannot be changed for security reasons',
              style: TextStyle(
                fontSize: 13,
                color: colors.textTertiary,
                fontStyle: FontStyle.italic,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(height: 20),
            _buildInputField(
              controller: _phoneController,
              label: 'Phone Number (Optional)',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (value.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                }
                return null;
              },
              colors: colors,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    IconData? suffixIcon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    required DynamicAppColors colors,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        color: enabled ? colors.textPrimary : colors.textTertiary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: enabled ? colors.textSecondary : colors.textTertiary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: enabled ? colors.primaryAccent : colors.textTertiary,
            size: 20,
          ),
        ),
        suffixIcon: suffixIcon != null
            ? Icon(
                suffixIcon,
                color: colors.textTertiary,
                size: 18,
              )
            : null,
        filled: true,
        fillColor: enabled
            ? colors.primaryBackground
            : colors.surfaceCards.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colors.borderLight,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colors.borderLight,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colors.primaryAccent,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colors.error,
            width: 1,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colors.borderLight.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }

  Widget _buildActionButtons(DynamicAppColors colors) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.primaryAccent,
                colors.primaryAccent.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors.primaryAccent.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.save_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: _isLoading
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    context.pop();
                  },
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: colors.borderMedium,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: colors.surfaceCards,
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _saveProfile() async {
    final colors = ref.read(dynamicColorsProvider);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    HapticFeedback.mediumImpact();

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser?.id == null) {
        throw Exception('User not logged in');
      }

  final updated = await _userService.updateProfile(
        userId: currentUser!.id,
        fullName: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        profileImage: _uploadedImageIdOrUrl,
      );

  // Update the user provider with new model
  ref.read(currentUserProvider.notifier).setUserModel(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Profile updated successfully',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: colors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );

        // Navigate back after successful save
        context.pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Failed to update profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: colors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile Picture'),
        content: const Text('Select profile picture source'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _pickImageFromGallery();
            },
            child: const Text('Gallery'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _pickImageFromCamera();
            },
            child: const Text('Camera'),
          ),
          if (_uploadedImageIdOrUrl != null || _selectedImageFile != null)
            TextButton(
              onPressed: () {
                setState(() {
                  _uploadedImageIdOrUrl = null;
                  _selectedImageFile = null;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Remove'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
      if (picked == null) return;
      setState(() {
        _selectedImageFile = File(picked.path);
      });
      await _uploadSelectedImage();
    } catch (e) {
      _showError('Failed to pick image');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.camera, maxWidth: 1024, imageQuality: 85);
      if (picked == null) return;
      setState(() {
        _selectedImageFile = File(picked.path);
      });
      await _uploadSelectedImage();
    } catch (e) {
      _showError('Failed to capture image');
    }
  }

  Widget _buildAvatarContent(user, DynamicAppColors colors) {
    // Priority: chosen file preview -> uploaded image id/url -> existing user.profileImage/profileImageUrl -> initials
    if (_selectedImageFile != null) {
      return Image.file(_selectedImageFile!, fit: BoxFit.cover);
    }
    final String? uploaded = _uploadedImageIdOrUrl;
    final String? existing = (user?.profileImageUrl ?? user?.profileImage)?.toString();
    final String? refStr = uploaded ?? existing;
    bool looksLikeUrl(String v) => v.startsWith('http://') || v.startsWith('https://') || v.startsWith('data:');
    if (refStr != null && refStr.isNotEmpty) {
      return looksLikeUrl(refStr)
          ? Image.network(refStr, width: 80, height: 80, fit: BoxFit.cover)
          : MongoImage(imageId: refStr, width: 80, height: 80, fit: BoxFit.cover);
    }
    return Container(
      color: Colors.transparent,
      child: Center(
        child: Text(
          user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'U',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: colors.primaryAccent,
          ),
        ),
      ),
    );
  }

  Future<void> _uploadSelectedImage() async {
    if (_selectedImageFile == null) return;
    final colors = ref.read(dynamicColorsProvider);
    try {
      setState(() => _isLoading = true);
      // Build data URL from file
      String _guessMime(String path) {
        final lower = path.toLowerCase();
        if (lower.endsWith('.png')) return 'image/png';
        if (lower.endsWith('.webp')) return 'image/webp';
        if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
        if (lower.endsWith('.gif')) return 'image/gif';
        return 'image/jpeg';
      }
      final mime = _guessMime(_selectedImageFile!.path);
      final bytes = await _selectedImageFile!.readAsBytes();
      final b64 = base64Encode(bytes);
      final dataUrl = 'data:$mime;base64,$b64';

      // Prepare headers with session token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('sessionToken');
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';

      // Current user id
      final current = ref.read(currentUserProvider);
      final userId = current?.id;
      if (userId == null || userId.isEmpty) {
        _showError('Missing user id');
        return;
      }

      final uri = Uri.parse('${DbConfig.apiUrl}/users/$userId/profile-image');
      final resp = await http.post(uri, headers: headers, body: jsonEncode({'dataUrl': dataUrl}));
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        String message = 'Upload failed (${resp.statusCode})';
        try { final j = jsonDecode(resp.body); message = j['error']?.toString() ?? message; } catch (_) {}
        _showError(message);
        return;
      }
      final j = jsonDecode(resp.body) as Map<String, dynamic>;
      final String? canonicalUrl =
          (j['profileImageUrl']?.toString()) ?? (j['url']?.toString()) ?? (j['user'] is Map ? j['user']['profileImageUrl']?.toString() : null);
      if (canonicalUrl == null || canonicalUrl.isEmpty) {
        _showError('Upload succeeded but no URL returned');
        return;
      }

      // Update local state and cache
      setState(() { _uploadedImageIdOrUrl = canonicalUrl; });
      try { await prefs.setString('immosync-profileImage-$userId', canonicalUrl); } catch (_) {}
      // Update current user model in provider
      if (current != null) {
        ref.read(currentUserProvider.notifier).setUserModel(
          current.copyWith(
            profileImage: canonicalUrl,
            // If your model has profileImageUrl in copyWith, set it too (kept for clarity)
          ),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Profile image uploaded'),
        backgroundColor: colors.success,
      ));
    } catch (e) {
      _showError('Failed to upload image');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    final colors = ref.read(dynamicColorsProvider);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: colors.error,
    ));
  }
}
