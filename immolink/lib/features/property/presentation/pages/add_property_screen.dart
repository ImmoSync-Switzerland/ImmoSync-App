import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:immosync/core/providers/dynamic_colors_provider.dart';
import 'package:immosync/features/property/domain/models/property.dart';

class AddPropertyScreen extends ConsumerStatefulWidget {
  const AddPropertyScreen({super.key, this.propertyToEdit});

  final Property? propertyToEdit;

  @override
  ConsumerState<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends ConsumerState<AddPropertyScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _rentController = TextEditingController();
  final _sizeController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _nameFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _rentFocus = FocusNode();
  final _sizeFocus = FocusNode();
  final _descriptionFocus = FocusNode();

  final List<String> _amenityOptions = const [
    'Wifi',
    'Parking',
    'Balcony',
    'Elevator',
    'Furnished',
    'Pet Friendly',
    'AC',
  ];

  final List<String> _selectedAmenities = [];

  int _rooms = 1;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.propertyToEdit != null;
    if (widget.propertyToEdit != null) {
      _prefillFromProperty(widget.propertyToEdit!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _rentController.dispose();
    _sizeController.dispose();
    _descriptionController.dispose();

    _nameFocus.dispose();
    _addressFocus.dispose();
    _rentFocus.dispose();
    _sizeFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(dynamicColorsProvider);
    final title = _isEditing ? 'Edit Property' : 'Add Property';
    final ctaLabel = _isEditing ? 'Update Property' : 'Save Property';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _BentoBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _SectionTitle('Basic Info'),
                  const SizedBox(height: 12),
                  _BentoTextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    label: 'Property Name',
                    hint: 'e.g., Lakeview Apartment',
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 12),
                  _BentoTextField(
                    controller: _addressController,
                    focusNode: _addressFocus,
                    label: 'Address',
                    hint: 'Street, City, Postal Code',
                    keyboardType: TextInputType.streetAddress,
                    prefixIcon: Icons.place_rounded,
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('Details'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _BentoTextField(
                          controller: _rentController,
                          focusNode: _rentFocus,
                          label: 'Monthly Rent (CHF)',
                          hint: '0.00',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _BentoTextField(
                          controller: _sizeController,
                          focusNode: _sizeFocus,
                          label: 'Size (m²)',
                          hint: '0',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _RoomsCounter(
                    rooms: _rooms,
                    onChanged: (value) => setState(() => _rooms = value),
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('Amenities'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _amenityOptions.map((amenity) {
                      final isSelected = _selectedAmenities.contains(amenity);
                      return FilterChip(
                        selected: isSelected,
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _selectedAmenities.add(amenity);
                            } else {
                              _selectedAmenities.remove(amenity);
                            }
                          });
                        },
                        label: Text(
                          amenity,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        backgroundColor: const Color(0xFF1C1C1E),
                        selectedColor: Colors.blue,
                        checkmarkColor: Colors.white,
                        side: BorderSide(
                          color: isSelected
                              ? Colors.blue.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.18),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('Image Upload'),
                  const SizedBox(height: 12),
                  _DashedUploadBox(
                    onTap: () {
                      // TODO: integrate image picker
                    },
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('Description'),
                  const SizedBox(height: 12),
                  _BentoTextField(
                    controller: _descriptionController,
                    focusNode: _descriptionFocus,
                    label: 'Description',
                    hint: 'Add a short description...',
                    keyboardType: TextInputType.multiline,
                    minLines: 4,
                    maxLines: 6,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: _PrimaryButton(
              label: ctaLabel,
              colors: colors,
              onPressed: () {
                // TODO: save action
              },
            ),
          ),
        ],
      ),
    );
  }

  void _prefillFromProperty(Property property) {
    _nameController.text = property.address.street;
    final addressParts = [
      property.address.street,
      property.address.city,
      property.address.postalCode,
      property.address.country,
    ].where((value) => value.trim().isNotEmpty).toList();
    _addressController.text = addressParts.join(', ');

    if (property.rentAmount > 0) {
      _rentController.text = property.rentAmount.toStringAsFixed(2);
    }
    if (property.details.size > 0) {
      _sizeController.text = property.details.size.toStringAsFixed(1);
    }

    _rooms = property.details.rooms > 0 ? property.details.rooms : _rooms;
    _selectedAmenities
      ..clear()
      ..addAll(property.details.amenities);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _BentoTextField extends StatefulWidget {
  const _BentoTextField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.keyboardType,
    this.prefixIcon,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final int minLines;
  final int maxLines;

  @override
  State<_BentoTextField> createState() => _BentoTextFieldState();
}

class _BentoTextFieldState extends State<_BentoTextField> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          keyboardType: widget.keyboardType,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          cursorColor: Colors.blue,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1C1C1E),
            hintText: widget.hint,
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: widget.prefixIcon == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(left: 12, right: 6),
                    child: Icon(
                      widget.prefixIcon,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 32, minHeight: 32),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoomsCounter extends StatelessWidget {
  const _RoomsCounter({required this.rooms, required this.onChanged});

  final int rooms;
  final ValueChanged<int> onChanged;

  void _change(int delta) {
    final next = (rooms + delta).clamp(0, 99);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF151821),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const Text(
            'Rooms',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          _CounterButton(
            icon: Icons.remove_rounded,
            onTap: () => _change(-1),
          ),
          Container(
            width: 46,
            alignment: Alignment.center,
            child: Text(
              rooms.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _CounterButton(
            icon: Icons.add_rounded,
            onTap: () => _change(1),
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF1F2534),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _DashedUploadBox extends StatelessWidget {
  const _DashedUploadBox({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(),
        child: Container(
          height: 160,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF121421),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                color: Colors.white,
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload photos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Tap to select images or drag & drop',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 6.0;
    const dashSpace = 6.0;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(14),
    );

    final path = Path()..addRRect(rect);
    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.colors,
    required this.onPressed,
  });

  final String label;
  final DynamicAppColors colors;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              colors.primaryAccent,
              colors.primaryAccent.withValues(alpha: 0.75),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: colors.primaryAccent.withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: colors.textOnAccent,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _BentoBackground extends StatelessWidget {
  const _BentoBackground();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: Color(0xFF0B1220)),
        ),
        _GlowOrb(
          color: Color(0xFF0EA5E9),
          size: 320,
          alignment: Alignment(-0.8, -0.6),
          opacity: 0.18,
        ),
        _GlowOrb(
          color: Color(0xFF6366F1),
          size: 360,
          alignment: Alignment(0.9, -0.4),
          opacity: 0.16,
        ),
        _GlowOrb(
          color: Color(0xFFFFA94D),
          size: 400,
          alignment: Alignment(-0.6, 0.9),
          opacity: 0.12,
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.color,
    required this.size,
    required this.alignment,
    this.opacity = 0.14,
  });

  final Color color;
  final double size;
  final Alignment alignment;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0.02),
              Colors.transparent,
            ],
            stops: const [0, 0.45, 1],
          ),
        ),
      ),
    );
  }
}
