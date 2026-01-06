import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
// image cache eviction
// eviction configuration
// Removed http_parser import; no longer using multipart upload
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/db_config.dart';
import '../../../../core/widgets/mongo_image.dart';
import '../../../../core/widgets/authenticated_network_image.dart';
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
  static const Color _bgTop = Color(0xFF0A1128);
  static const Color _bgBottom = Colors.black;
  static const Color _cardBg = Color(0xFF1C1C1E);
  static const Color _fieldFill = Color(0xFF2C2C2E);
  static const Color _blue = Color(0xFF3B82F6);
  static const Color _cyan = Color(0xFF22D3EE);

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
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: SafeArea(
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
                        _buildProfileHeaderCard(currentUser),
                        const SizedBox(height: 20),
                        _buildFormSection(),
                        const SizedBox(height: 28),
                        _buildActionButtons(colors),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          context.pop();
        },
      ),
      title: const Text(
        'Edit Profile',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildProfileHeaderCard(user) {
    final roleRaw = (user?.role ?? '').toString().toLowerCase();
    final bool isTenant = roleRaw == 'tenant';
    final badgeColor = isTenant
        ? const Color(0xFFF59E0B).withValues(alpha: 0.18)
        : _blue.withValues(alpha: 0.18);
    final badgeBorder = isTenant
        ? const Color(0xFFF59E0B).withValues(alpha: 0.28)
        : _blue.withValues(alpha: 0.28);

    return BentoCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: _buildAvatarContent(
                        user, ref.read(dynamicColorsProvider)),
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
                      color: _blue,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _cardBg,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _blue.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? 'User Name',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'user@example.com',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: badgeBorder, width: 1),
                  ),
                  child: Text(
                    (user?.role ?? 'User').toString().toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white70,
                      letterSpacing: 0.6,
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

  Widget _buildFormSection() {
    return BentoCard(
      padding: const EdgeInsets.all(20),
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
                    color: _blue.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _blue.withValues(alpha: 0.28),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: _blue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Personal Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
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
            ),
            const SizedBox(height: 20),
            _buildInputField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email_outlined,
              enabled: false,
              suffixIcon: Icons.lock_outline,
            ),
            const SizedBox(height: 12),
            const Text(
              'Email cannot be changed for security reasons',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white54,
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
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        color: enabled ? Colors.white : Colors.white54,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: enabled ? Colors.white70 : Colors.white54,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: enabled ? _blue : Colors.white38,
            size: 20,
          ),
        ),
        suffixIcon: suffixIcon != null
            ? Icon(
                suffixIcon,
                color: enabled ? Colors.white70 : Colors.white24,
                size: 18,
              )
            : null,
        filled: true,
        fillColor: enabled ? _fieldFill : _fieldFill.withValues(alpha: 0.65),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
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
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _blue,
                _cyan,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _blue.withValues(alpha: 0.30),
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
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.save_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 12),
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
        SizedBox(
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
                color: Colors.white.withValues(alpha: 0.18),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.transparent,
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
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
            content: const Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 12),
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
            content: const Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 12),
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
        backgroundColor: _cardBg,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        title: const Text('Profile Picture'),
        content: const Text('Select profile picture source'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _pickImageFromGallery();
            },
            child: const Text('Gallery',
                style: TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _pickImageFromCamera();
            },
            child: const Text('Camera',
                style: TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.w700)),
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
              child: const Text('Remove',
                  style: TextStyle(
                      color: Color(0xFFEF4444), fontWeight: FontWeight.w800)),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel',
                style: TextStyle(
                    color: Colors.white54, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
          source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
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
      final picked = await picker.pickImage(
          source: ImageSource.camera, maxWidth: 1024, imageQuality: 85);
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
    final String? existing =
        (user?.profileImageUrl ?? user?.profileImage)?.toString();
    final String? refStr = uploaded ?? existing;
    bool looksLikeUrl(String v) =>
        v.startsWith('http://') ||
        v.startsWith('https://') ||
        v.startsWith('data:');
    if (refStr != null && refStr.isNotEmpty) {
      return looksLikeUrl(refStr)
          ? Image(
              image: AuthenticatedNetworkImageProvider(refStr),
              key: ValueKey(refStr), // force refresh when URL changes
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            )
          : MongoImage(
              imageId: refStr,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            );
    }
    return Container(
      color: Colors.transparent,
      child: Center(
        child: Text(
          user?.fullName.isNotEmpty == true
              ? user!.fullName[0].toUpperCase()
              : 'U',
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
        if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
          return 'image/heic';
        }
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
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Current user id (optional)
      final current = ref.read(currentUserProvider);
      final userId = current?.id;
      final uri = userId != null && userId.isNotEmpty
          ? Uri.parse('${DbConfig.apiUrl}/users/$userId/profile-image')
          : Uri.parse('${DbConfig.apiUrl}/users/me/profile-image');
      final resp = await http.post(uri,
          headers: headers, body: jsonEncode({'dataUrl': dataUrl}));
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        String message = 'Upload failed (${resp.statusCode})';
        try {
          final j = jsonDecode(resp.body);
          message = j['error']?.toString() ?? message;
        } catch (_) {}
        _showError(message);
        return;
      }
      final j = jsonDecode(resp.body) as Map<String, dynamic>;
      final String? canonicalUrl = (j['profileImageUrl']?.toString()) ??
          (j['url']?.toString()) ??
          (j['user'] is Map ? j['user']['profileImageUrl']?.toString() : null);
      if (canonicalUrl == null || canonicalUrl.isEmpty) {
        _showError('Upload succeeded but no URL returned');
        return;
      }

      // Build a cache-busted URL so Flutter treats it as a new resource
      final bustedUrl =
          '$canonicalUrl${canonicalUrl.contains('?') ? '&' : '?'}v=${DateTime.now().millisecondsSinceEpoch}';

      // Evict old image from Flutter cache to ensure immediate refresh
      final oldUrl = (current?.profileImageUrl.toString().isNotEmpty == true
              ? current!.profileImageUrl
              : current?.profileImage)
          ?.toString();
      bool _isHttp(String? v) =>
          v != null && (v.startsWith('http://') || v.startsWith('https://'));
      try {
        if (_isHttp(oldUrl)) {
          final provider = AuthenticatedNetworkImageProvider(oldUrl!);
          await provider.evict(
            cache: PaintingBinding.instance.imageCache,
            configuration: ImageConfiguration.empty,
          );
        }
      } catch (_) {}

      // Update local state and persist busted URL
      setState(() {
        _uploadedImageIdOrUrl = bustedUrl;
      });
      try {
        if (userId != null && userId.isNotEmpty) {
          await prefs.setString('immosync-profileImage-$userId', bustedUrl);
        }
      } catch (_) {}
      // Update current user model in provider with the busted URL
      if (current != null) {
        ref.read(currentUserProvider.notifier).setUserModel(
              current.copyWith(
                profileImage: bustedUrl,
                profileImageUrl: bustedUrl,
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

class BentoCard extends StatelessWidget {
  const BentoCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _EditProfilePageState._cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
