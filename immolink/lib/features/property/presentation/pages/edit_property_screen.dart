import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditPropertyScreen extends StatefulWidget {
  const EditPropertyScreen({super.key});

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  final _titleCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  final _rentCtrl = TextEditingController();
  final _roomsCtrl = TextEditingController(text: '3.5');
  final _descriptionCtrl = TextEditingController();
  final Set<String> _amenities = {'Balcony', 'Parking'};

  @override
  void dispose() {
    _titleCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _zipCtrl.dispose();
    _rentCtrl.dispose();
    _roomsCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Edit Property',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          const _BentoBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BentoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Basics', style: _sectionTitle),
                        const SizedBox(height: 14),
                        _DarkField(
                            controller: _titleCtrl,
                            label: 'Title',
                            hint: 'Cozy 2.5 Zimmer Wohnung'),
                        const SizedBox(height: 12),
                        _DarkField(
                            controller: _addressCtrl,
                            label: 'Address',
                            hint: 'Musterstrasse 12'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _DarkField(
                                  controller: _cityCtrl,
                                  label: 'City',
                                  hint: 'Zürich'),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 110,
                              child: _DarkField(
                                  controller: _zipCtrl,
                                  label: 'ZIP',
                                  hint: '8000',
                                  keyboardType: TextInputType.number),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _DarkField(
                                controller: _rentCtrl,
                                label: 'Rent (CHF)',
                                hint: '2450',
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DarkField(
                                  controller: _roomsCtrl,
                                  label: 'Rooms',
                                  hint: '3.5'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _DarkMultiline(
                            controller: _descriptionCtrl,
                            label: 'Description',
                            hint:
                                'Describe the unit, light, layout, and any recent upgrades.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _BentoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Amenities', style: _sectionTitle),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 10,
                          children: _amenityOptions.map((amenity) {
                            final selected = _amenities.contains(amenity);
                            return FilterChip(
                              label: Text(amenity),
                              selected: selected,
                              onSelected: (value) {
                                setState(() {
                                  if (value) {
                                    _amenities.add(amenity);
                                  } else {
                                    _amenities.remove(amenity);
                                  }
                                });
                              },
                              backgroundColor: const Color(0xFF2A2A2C),
                              selectedColor: const Color(0xFF2563EB),
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                color: selected ? Colors.white : Colors.white70,
                                fontWeight: FontWeight.w700,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: selected
                                      ? const Color(0xFF2563EB)
                                      : Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {},
                      child: const Text('Save Changes',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111113), Color(0xFF0C0C0E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(1),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _DarkField extends StatelessWidget {
  const _DarkField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          decoration: _darkInputDecoration(hint),
        ),
      ],
    );
  }
}

class _DarkMultiline extends StatelessWidget {
  const _DarkMultiline(
      {required this.controller, required this.label, required this.hint});

  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 4,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          decoration: _darkInputDecoration(hint),
        ),
      ],
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
          decoration: BoxDecoration(color: Color(0xFF050505)),
        ),
        _GlowOrb(
          color: Color(0xFF2563EB),
          size: 320,
          alignment: Alignment(-0.8, -0.6),
          opacity: 0.16,
        ),
        _GlowOrb(
          color: Color(0xFF6366F1),
          size: 360,
          alignment: Alignment(0.7, 0.1),
          opacity: 0.12,
        ),
        _GlowOrb(
          color: Color(0xFFF97316),
          size: 380,
          alignment: Alignment(-0.3, 0.9),
          opacity: 0.10,
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
    this.opacity = 0.16,
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

InputDecoration _darkInputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.52),
        fontWeight: FontWeight.w600),
    filled: true,
    fillColor: const Color(0xFF1C1C1E),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
    ),
  );
}

const _sectionTitle = TextStyle(
  color: Colors.white,
  fontSize: 16,
  fontWeight: FontWeight.w800,
);

const List<String> _amenityOptions = [
  'Balcony',
  'Parking',
  'Washer',
  'Dryer',
  'Dishwasher',
  'Elevator',
  'Garden',
  'Pets Allowed',
  'Storage',
  'Gym',
];
