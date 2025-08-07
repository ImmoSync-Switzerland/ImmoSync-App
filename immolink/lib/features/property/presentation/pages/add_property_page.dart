import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:immolink/features/auth/presentation/providers/auth_provider.dart';
import 'package:immolink/features/property/domain/models/property.dart';
import 'package:immolink/features/property/presentation/providers/property_providers.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/currency_provider.dart';

class AddPropertyPage extends ConsumerStatefulWidget {
  final Property? propertyToEdit;
  
  const AddPropertyPage({super.key, this.propertyToEdit});

  @override
  ConsumerState<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends ConsumerState<AddPropertyPage> with TickerProviderStateMixin {
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
    'Parking', 'Elevator', 'Balcony', 'Garden', 'Furnished', 
    'Pet Friendly', 'Storage', 'Laundry', 'Swimming Pool', 
    'Gym', 'Air Conditioning', 'Heating', 'Dishwasher', 
    'Internet', 'Security System'
  ];

  // Modern design system colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF2F2F2);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color accent = Color(0xFF007AFF);
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF212121);
  static const Color textCaption = Color(0xFF8E8E93);
  static const Color success = Color(0xFF34C759);
  static const Color error = Color(0xFFFF3B30);
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
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),        title: Text(
          widget.propertyToEdit != null ? 'Edit Property' : 'Add Property',
          style: const TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoadingWidget()
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
                          _buildHeaderSection(),
                          const SizedBox(height: 32),
                          _buildLocationCard(),
                          const SizedBox(height: 24),
                          _buildDetailsCard(),
                          const SizedBox(height: 24),
                          _buildAmenitiesCard(),
                          const SizedBox(height: 24),
                          _buildImagesCard(),
                          const SizedBox(height: 40),
                          _buildSubmitButton(),
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

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(accent),
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.propertyToEdit != null ? 'Updating property...' : 'Creating property...',
            style: const TextStyle(
              color: textCaption,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    final isEditing = widget.propertyToEdit != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEditing ? 'Edit Property' : 'New Property',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.8,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isEditing ? 'Update your property details' : 'Add property details to get started',
          style: const TextStyle(
            fontSize: 16,
            color: textCaption,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    return _buildCard(
      title: 'Location',
      children: [
        _buildTextField(
          controller: _addressController,
          label: 'Street Address',
          validator: (value) => value?.isEmpty ?? true ? 'Address is required' : null,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildTextField(
                controller: _cityController,
                label: 'City',
                validator: (value) => value?.isEmpty ?? true ? 'City is required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _postalCodeController,
                label: 'Postal Code',
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return _buildCard(
      title: 'Property Details',
      children: [
        _buildTextField(
          controller: _rentController,
          label: 'Monthly Rent (${ref.read(currencyProvider.notifier).getSymbol()})',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Rent amount is required';
            if (double.tryParse(value!) == null) return 'Invalid amount';
            return null;
          },
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _sizeController,
                label: 'Size (m²)',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _roomsController,
                label: 'Rooms',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmenitiesCard() {
    return _buildCard(
      title: 'Amenities',
      children: [
        Text(
          'Select available amenities',
          style: TextStyle(
            fontSize: 14,
            color: textCaption,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? accent : surface,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected ? null : Border.all(color: divider, width: 1),
                ),
                child: Text(
                  amenity,
                  style: TextStyle(
                    color: isSelected ? Colors.white : textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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

  Widget _buildImagesCard() {
    return _buildCard(
      title: 'Images',      children: [
        GestureDetector(
          onTap: _pickImages,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 120,
            decoration: BoxDecoration(
              color: selectedImages.isEmpty ? surface : accent.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedImages.isEmpty ? divider : accent.withValues(alpha: 0.3), 
                width: 1.5,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selectedImages.isEmpty ? Icons.cloud_upload_outlined : Icons.check_circle_outline,
                    size: 28,
                    color: selectedImages.isEmpty ? textCaption : accent,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedImages.isEmpty 
                        ? 'Tap to upload images' 
                        : '${selectedImages.length} image(s) selected',
                    style: TextStyle(
                      color: selectedImages.isEmpty ? textCaption : accent,
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
                    border: Border.all(color: divider),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildImagePreview(imagePath),
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
                              color: error.withValues(alpha: 0.9),
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

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textCaption,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: TextStyle(
              color: textCaption,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: accent, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: error, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: SizedBox(
        width: double.infinity,
        height: 56, // Minimum touch target height
        child: ElevatedButton(
          onPressed: _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            widget.propertyToEdit != null ? 'Update Property' : 'Create Property',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }  Future<void> _pickImages() async {
    try {
      HapticFeedback.lightImpact();
      FilePickerResult? result = await FilePicker.platform.pickFiles(
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
            content: Text('${result.files.length} image(s) selected'),
            backgroundColor: success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No images selected'),
            backgroundColor: textSecondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      print('Error selecting images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting images: ${e.toString()}'),
          backgroundColor: error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
  Widget _buildImagePreview(String imagePath) {
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
            color: surface,
            child: Icon(
              Icons.broken_image_outlined,
              color: textCaption,
              size: 32,
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 100,
            height: 100,
            color: surface,
            child: Center(
              child: CircularProgressIndicator(
                color: accent,
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
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
                color: surface,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: textCaption,
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
        color: surface,
        child: Icon(
          Icons.image_outlined,
          color: textCaption,
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
            color: surface,
            child: Icon(
              Icons.broken_image_outlined,
              color: textCaption,
              size: 32,
            ),
          );
        },
      );
    }
  }

  void _removeImage(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      if (index >= 0 && index < selectedImages.length) {
        selectedImages.removeAt(index);
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Image removed'),
        backgroundColor: textSecondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      HapticFeedback.mediumImpact();
      setState(() {
        _isLoading = true;
      });

      try {
        final currentUser = ref.read(currentUserProvider);
        final landlordId = currentUser?.id.toString() ?? '';
          // Upload images to MongoDB if any are selected
        List<String> uploadedImageIds = [];
        if (_pickerResult != null && _pickerResult!.files.isNotEmpty) {
          print('Found ${_pickerResult!.files.length} files to upload');
          final propertyService = ref.read(propertyServiceProvider);
          
          for (int i = 0; i < _pickerResult!.files.length; i++) {
            final file = _pickerResult!.files[i];
            print('Uploading file ${i + 1}/${_pickerResult!.files.length}: ${file.name}');
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
          outstandingPayments: widget.propertyToEdit?.outstandingPayments ?? 0.0,
        );        if (widget.propertyToEdit != null) {
          // Update existing property
          await ref.read(propertyServiceProvider).updateProperty(property);
          
          // Invalidate the property provider to refresh the data
          ref.invalidate(propertyProvider(property.id));
          ref.invalidate(landlordPropertiesProvider);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Property updated successfully!'),
              backgroundColor: success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
              content: const Text('Property created successfully!'),
              backgroundColor: success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        
        context.pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
}

