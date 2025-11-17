import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/property/domain/models/property.dart';
import 'package:immosync/features/property/presentation/providers/property_providers.dart';
import 'package:immosync/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';

class AddPropertyPage extends ConsumerStatefulWidget {
  final Property? propertyToEdit;

  const AddPropertyPage({super.key, this.propertyToEdit});

  @override
  ConsumerState<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends ConsumerState<AddPropertyPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _rentController = TextEditingController();
  final _sizeController = TextEditingController();
  final _roomsController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  List<String> selectedAmenities = [];
  List<String> selectedImages = [];
  FilePickerResult? _pickerResult; // Store the picker result for web
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  final List<String> amenitiesList = [
    'Parking',
    'Elevator',
    'Balcony',
    'Garden',
    'Furnished',
    'Pet Friendly',
    'Storage',
    'Laundry',
    'Swimming Pool',
    'Gym',
    'Air Conditioning',
    'Heating',
    'Dishwasher',
    'Internet',
    'Security System'
  ];

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
    _animationController.forward();

    // Populate fields if editing existing property
    if (widget.propertyToEdit != null) {
      _populateFields(widget.propertyToEdit!);
    }
  }

  void _populateFields(Property property) {
    _addressController.text = property.address.street;
    _cityController.text = property.address.city;
    _postalCodeController.text = property.address.postalCode;
    _rentController.text = property.rentAmount.toString();
    _sizeController.text = property.details.size.toString();
    _roomsController.text = property.details.rooms.toString();
    selectedAmenities = List.from(property.details.amenities);
    selectedImages = List.from(property.imageUrls);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _addressController.dispose();
    _rentController.dispose();
    _sizeController.dispose();
    _roomsController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(dynamicColorsProvider);

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        backgroundColor: colors.primaryBackground,
        elevation: 0,
        systemOverlayStyle: colors.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.propertyToEdit != null
              ? AppLocalizations.of(context)!.editProperty
              : AppLocalizations.of(context)!.addProperty,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            inherit: true,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoadingWidget(colors)
          : AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Opacity(
                    opacity: 1 - (_slideAnimation.value / 30),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(20.0),
                        children: [
                          _buildHeaderSection(colors),
                          const SizedBox(height: 32),
                          _buildLocationCard(colors),
                          const SizedBox(height: 24),
                          _buildDetailsCard(colors),
                          const SizedBox(height: 24),
                          _buildAmenitiesCard(colors),
                          const SizedBox(height: 24),
                          _buildImagesCard(colors),
                          const SizedBox(height: 40),
                          _buildSubmitButton(colors),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildLoadingWidget(DynamicAppColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colors.primaryAccent),
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.propertyToEdit != null
                ? AppLocalizations.of(context)!.updatingProperty
                : AppLocalizations.of(context)!.creatingProperty,
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
              inherit: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(DynamicAppColors colors) {
    final isEditing = widget.propertyToEdit != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEditing
              ? AppLocalizations.of(context)!.editProperty
              : AppLocalizations.of(context)!.newProperty,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
            letterSpacing: -0.8,
            height: 1.1,
            inherit: true,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isEditing
              ? AppLocalizations.of(context)!.updatePropertyDetails
              : AppLocalizations.of(context)!.addPropertyDetails,
          style: TextStyle(
            fontSize: 16,
            color: colors.textTertiary,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.2,
            inherit: true,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(DynamicAppColors colors) {
    final l10n = AppLocalizations.of(context)!;
    return _buildCard(
      title: l10n.location,
      colors: colors,
      children: [
        _buildTextField(
          colors: colors,
          controller: _addressController,
          label: l10n.streetAddress,
          validator: (value) =>
              value?.isEmpty ?? true ? l10n.addressRequired : null,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildTextField(
                colors: colors,
                controller: _cityController,
                label: l10n.city,
                validator: (value) =>
                    value?.isEmpty ?? true ? l10n.cityRequired : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                colors: colors,
                controller: _postalCodeController,
                label: l10n.postalCode,
                validator: (value) =>
                    value?.isEmpty ?? true ? l10n.postalCodeRequired : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsCard(DynamicAppColors colors) {
    final l10n = AppLocalizations.of(context)!;
    return _buildCard(
      title: l10n.propertyDetails,
      colors: colors,
      children: [
        _buildTextField(
          controller: _rentController,
          label:
              '${l10n.monthlyRent} (${ref.read(currencyProvider.notifier).getSymbol()})',
          colors: colors,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value?.isEmpty ?? true) return l10n.rentRequired;
            if (double.tryParse(value!) == null) return 'Invalid amount';
            return null;
          },
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                colors: colors,
                controller: _sizeController,
                label: '${l10n.size} (m²)',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                colors: colors,
                controller: _roomsController,
                label: l10n.rooms,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmenitiesCard(DynamicAppColors colors) {
    final l10n = AppLocalizations.of(context)!;
    return _buildCard(
      colors: colors,
      title: l10n.amenities,
      children: [
        Text(
          l10n.selectAmenities,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.85),
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: amenitiesList.map((amenity) {
            final isSelected = selectedAmenities.contains(amenity);
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  if (isSelected) {
                    selectedAmenities.remove(amenity);
                  } else {
                    selectedAmenities.add(amenity);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.95)
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  amenity,
                  style: TextStyle(
                    color: isSelected ? colors.textPrimary : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildImagesCard(DynamicAppColors colors) {
    final l10n = AppLocalizations.of(context)!;
    return _buildCard(
      colors: colors,
      title: l10n.images,
      children: [
        GestureDetector(
          onTap: _pickImages,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 120,
            decoration: BoxDecoration(
              color: selectedImages.isEmpty
                  ? colors.surfaceCards
                  : colors.primaryAccent.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedImages.isEmpty
                    ? colors.borderLight
                    : colors.primaryAccent.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selectedImages.isEmpty
                        ? Icons.cloud_upload_outlined
                        : Icons.check_circle_outline,
                    size: 28,
                    color: selectedImages.isEmpty
                        ? colors.textTertiary
                        : colors.primaryAccent,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedImages.isEmpty
                        ? l10n.tapToUploadImages
                        : l10n.imagesSelected(selectedImages.length),
                    style: TextStyle(
                      color: selectedImages.isEmpty
                          ? colors.textTertiary
                          : colors.primaryAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (selectedImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: selectedImages.length,
              padding: const EdgeInsets.only(right: 16),
              itemBuilder: (context, index) {
                final imagePath = selectedImages[index];
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.borderLight),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildImagePreview(imagePath, colors),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            width: 24,
                            height: 24,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colors.error.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCard(
      {required String title,
      required List<Widget> children,
      required DynamicAppColors colors}) {
    // Assign gradient colors based on card title
    List<Color> gradientColors;
    Color shadowColor;
    IconData iconData;

    if (title.toLowerCase().contains('location')) {
      gradientColors = [
        const Color(0xFF3B82F6).withValues(alpha: 0.95),
        const Color(0xFF8B5CF6).withValues(alpha: 0.85),
      ];
      shadowColor = const Color(0xFF3B82F6);
      iconData = Icons.location_on_outlined;
    } else if (title.toLowerCase().contains('detail')) {
      gradientColors = [
        const Color(0xFF059669).withValues(alpha: 0.95),
        const Color(0xFF10B981).withValues(alpha: 0.85),
      ];
      shadowColor = const Color(0xFF059669);
      iconData = Icons.home_outlined;
    } else if (title.toLowerCase().contains('amenities')) {
      gradientColors = [
        const Color(0xFFEA580C).withValues(alpha: 0.95),
        const Color(0xFFDC2626).withValues(alpha: 0.85),
      ];
      shadowColor = const Color(0xFFEA580C);
      iconData = Icons.star_outline;
    } else {
      // Images card - Purple
      gradientColors = [
        const Color(0xFF8B5CF6).withValues(alpha: 0.95),
        const Color(0xFF3B82F6).withValues(alpha: 0.85),
      ];
      shadowColor = const Color(0xFF8B5CF6);
      iconData = Icons.image_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  iconData,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required DynamicAppColors colors,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.85),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: TextStyle(
              color: colors.textTertiary,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.95),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.white, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colors.error, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(DynamicAppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: SizedBox(
        width: double.infinity,
        height: 56, // Minimum touch target height
        child: ElevatedButton(
          onPressed: _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primaryAccent,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            widget.propertyToEdit != null
                ? AppLocalizations.of(context)!.updateProperty
                : AppLocalizations.of(context)!.saveProperty,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final colors = ref.read(dynamicColorsProvider);
    try {
      HapticFeedback.lightImpact();
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true, // Important for web
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickerResult = result; // Store the result
          // For web, we need to handle bytes differently
          if (kIsWeb) {
            selectedImages = result.files
                .where((file) => file.bytes != null)
                .map((file) => file.name) // Use file name as identifier on web
                .toList();
          } else {
            selectedImages = result.files
                .where((file) => file.path != null)
                .map((file) => file.path!)
                .toList();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.files.length} Bild(er) ausgewählt'),
            backgroundColor: colors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.noImagesSelected),
            backgroundColor: colors.textSecondary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      print('colors.error selecting images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('colors.error selecting images: ${e.toString()}'),
          backgroundColor: colors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Widget _buildImagePreview(String imagePath, DynamicAppColors colors) {
    // Check if it's a URL (existing image) or a local file path (new upload)
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      // Remote image URL
      return Image.network(
        imagePath,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 100,
            height: 100,
            color: colors.surfaceCards,
            child: Icon(
              Icons.broken_image_outlined,
              color: colors.textTertiary,
              size: 32,
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 100,
            height: 100,
            color: colors.surfaceCards,
            child: Center(
              child: CircularProgressIndicator(
                color: colors.primaryAccent,
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    } else if (kIsWeb) {
      // Web: Use bytes from FilePickerResult
      if (_pickerResult != null) {
        final file = _pickerResult!.files.firstWhere(
          (file) => file.name == imagePath,
          orElse: () => _pickerResult!.files.first,
        );

        if (file.bytes != null) {
          return Image.memory(
            file.bytes!,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 100,
                height: 100,
                color: colors.surfaceCards,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: colors.textTertiary,
                  size: 32,
                ),
              );
            },
          );
        }
      }

      // Fallback for web
      return Container(
        width: 100,
        height: 100,
        color: colors.surfaceCards,
        child: Icon(
          Icons.image_outlined,
          color: colors.textTertiary,
          size: 32,
        ),
      );
    } else {
      // Mobile: Local file path
      return Image.file(
        File(imagePath),
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 100,
            height: 100,
            color: colors.surfaceCards,
            child: Icon(
              Icons.broken_image_outlined,
              color: colors.textTertiary,
              size: 32,
            ),
          );
        },
      );
    }
  }

  void _removeImage(int index) {
    final colors = ref.read(dynamicColorsProvider);
    HapticFeedback.lightImpact();
    setState(() {
      if (index >= 0 && index < selectedImages.length) {
        selectedImages.removeAt(index);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.imageRemoved),
        backgroundColor: colors.textSecondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _submitForm() async {
    final colors = ref.read(dynamicColorsProvider);
    if (_formKey.currentState?.validate() ?? false) {
      HapticFeedback.mediumImpact();
      setState(() {
        _isLoading = true;
      });

      try {
        final currentUser = ref.read(currentUserProvider);
        final landlordId = currentUser?.id.toString() ?? '';

        // If creating a new property (not editing), check subscription limits
        if (widget.propertyToEdit == null) {
          final subscriptionAsync = ref.read(userSubscriptionProvider);
          final propertiesAsync = ref.read(landlordPropertiesProvider);

          if (subscriptionAsync.hasValue && propertiesAsync.hasValue) {
            final subscription = subscriptionAsync.value;
            final currentProperties = propertiesAsync.value ?? [];

            // Check if user has an active subscription
            if (subscription == null || subscription.status != 'active') {
              _showSubscriptionRequiredDialog();
              setState(() {
                _isLoading = false;
              });
              return;
            }

            // Get subscription plan to check property limits
            final plansAsync = ref.read(subscriptionPlansProvider);
            if (plansAsync.hasValue) {
              final plans = plansAsync.value ?? [];
              final currentPlan = plans
                  .where((plan) => plan.id == subscription.planId)
                  .firstOrNull;

              if (currentPlan != null) {
                final currentPropertyCount = currentProperties.length;
                final maxProperties =
                    _extractPropertyLimit(currentPlan.features);

                if (maxProperties != null &&
                    currentPropertyCount >= maxProperties) {
                  _showPropertyLimitReachedDialog(
                      maxProperties, currentPlan.name);
                  setState(() {
                    _isLoading = false;
                  });
                  return;
                }
              }
            }
          }
        }

        // Upload images to MongoDB if any are selected
        final List<String> uploadedImageIds = [];
        if (_pickerResult != null && _pickerResult!.files.isNotEmpty) {
          print('Found ${_pickerResult!.files.length} files to upload');
          final propertyService = ref.read(propertyServiceProvider);

          for (int i = 0; i < _pickerResult!.files.length; i++) {
            final file = _pickerResult!.files[i];
            print(
                'Uploading file ${i + 1}/${_pickerResult!.files.length}: ${file.name}');
            final imageId = await propertyService.uploadImage(file);
            if (imageId != null) {
              uploadedImageIds.add(imageId);
              print('Successfully uploaded file: $imageId');
            } else {
              print('Failed to upload file: ${file.name}');
            }
          }
          print('Total uploaded images: ${uploadedImageIds.length}');
        } else {
          print('No images selected for upload');
        }
        // Use uploaded image IDs or existing ones for editing
        final finalImageUrls = uploadedImageIds.isNotEmpty
            ? uploadedImageIds
            : (widget.propertyToEdit?.imageUrls ?? []);

        print('Final image URLs for property: $finalImageUrls');

        final property = Property(
          id: widget.propertyToEdit?.id ?? const Uuid().v4(),
          landlordId: landlordId,
          tenantIds: widget.propertyToEdit?.tenantIds ?? [],
          address: Address(
            street: _addressController.text,
            city: _cityController.text,
            postalCode: _postalCodeController.text,
            country: 'Switzerland',
          ),
          rentAmount: double.parse(_rentController.text),
          details: PropertyDetails(
            size: double.tryParse(_sizeController.text) ?? 0,
            rooms: int.tryParse(_roomsController.text) ?? 0,
            amenities: selectedAmenities,
          ),
          status: widget.propertyToEdit?.status ?? 'available',
          imageUrls: finalImageUrls,
          outstandingPayments:
              widget.propertyToEdit?.outstandingPayments ?? 0.0,
        );
        if (widget.propertyToEdit != null) {
          // Update existing property
          await ref.read(propertyServiceProvider).updateProperty(property);

          // Invalidate the property provider to refresh the data
          ref.invalidate(propertyProvider(property.id));
          ref.invalidate(landlordPropertiesProvider);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.propertyUpdatedSuccessfully),
              backgroundColor: colors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.all(16),
            ),
          );
        } else {
          // Create new property
          await ref.read(propertyServiceProvider).addProperty(property);

          // Invalidate the properties provider to refresh the list
          ref.invalidate(landlordPropertiesProvider);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.propertyCreatedSuccessfully),
              backgroundColor: colors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }

        context.pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('colors.error: $e'),
            backgroundColor: colors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int? _extractPropertyLimit(List<String> features) {
    // Look for patterns like "Up to 3 properties" or "Unlimited properties"
    for (String feature in features) {
      if (feature.toLowerCase().contains('unlimited properties')) {
        return null; // Unlimited
      }

      // Match patterns like "Up to X properties" or "X properties"
      final regex = RegExp(r'up to (\d+) properties|\b(\d+) properties',
          caseSensitive: false);
      final match = regex.firstMatch(feature);
      if (match != null) {
        final numberStr = match.group(1) ?? match.group(2);
        if (numberStr != null) {
          return int.tryParse(numberStr);
        }
      }
    }
    return 0; // Default to 0 if no limit found
  }

  void _showSubscriptionRequiredDialog() {
    final colors = ref.read(dynamicColorsProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceCards,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.lock_outlined, color: colors.warning, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Subscription Required',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To add properties, you need an active subscription plan.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primaryAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: colors.primaryAccent.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.star_outline,
                      color: colors.primaryAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Choose a plan that fits your needs and start managing your properties today!',
                      style: TextStyle(
                        color: colors.primaryAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.textTertiary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/subscription/landlord');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(AppLocalizations.of(context)!.viewPlans),
          ),
        ],
      ),
    );
  }

  void _showPropertyLimitReachedDialog(int maxProperties, String planName) {
    final colors = ref.read(dynamicColorsProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceCards,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.home_outlined, color: colors.warning, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Property Limit Reached',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'ve reached the maximum number of properties ($maxProperties) for your $planName plan.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.luxuryGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: colors.luxuryGold.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.upgrade_outlined,
                      color: colors.luxuryGold, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Upgrade to a higher plan to add more properties and unlock additional features.',
                      style: TextStyle(
                        color: colors.luxuryGold,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.textTertiary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/subscription/landlord');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.luxuryGold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(AppLocalizations.of(context)!.upgradePlan),
          ),
        ],
      ),
    );
  }
}
