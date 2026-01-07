import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import '../../l10n/app_localizations.dart';

class PropertyType {
  final String label;
  final IconData icon;
  final bool isSelected;

  const PropertyType({
    required this.label,
    required this.icon,
    this.isSelected = false,
  });
}

class FilterPanel extends StatefulWidget {
  final List<PropertyType> propertyTypes;
  final RangeValues priceRange;
  final double minPrice;
  final double maxPrice;
  final int bedrooms;
  final int beds;
  final List<String> selectedAmenities;
  final List<String> availableAmenities;
  final ValueChanged<List<PropertyType>>? onPropertyTypesChanged;
  final ValueChanged<RangeValues>? onPriceRangeChanged;
  final ValueChanged<int>? onBedroomsChanged;
  final ValueChanged<int>? onBedsChanged;
  final ValueChanged<List<String>>? onAmenitiesChanged;
  final VoidCallback? onReset;
  final VoidCallback? onSave;

  const FilterPanel({
    super.key,
    required this.propertyTypes,
    required this.priceRange,
    required this.minPrice,
    required this.maxPrice,
    required this.bedrooms,
    required this.beds,
    required this.selectedAmenities,
    required this.availableAmenities,
    this.onPropertyTypesChanged,
    this.onPriceRangeChanged,
    this.onBedroomsChanged,
    this.onBedsChanged,
    this.onAmenitiesChanged,
    this.onReset,
    this.onSave,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late List<PropertyType> _propertyTypes;
  late RangeValues _priceRange;
  late int _bedrooms;
  late int _beds;
  late List<String> _selectedAmenities;

  @override
  void initState() {
    super.initState();
    _propertyTypes = List.from(widget.propertyTypes);
    _priceRange = widget.priceRange;
    _bedrooms = widget.bedrooms;
    _beds = widget.beds;
    _selectedAmenities = List.from(widget.selectedAmenities);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * AppSizes.filterPanelHeight,
      decoration: const BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.modalsOverlays),
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPropertyTypeSection(),
                  const SizedBox(height: AppSpacing.sectionSeparation),
                  _buildPriceRangeSection(),
                  const SizedBox(height: AppSpacing.sectionSeparation),
                  _buildBedroomsSection(),
                  const SizedBox(height: AppSpacing.sectionSeparation),
                  _buildBedsSection(),
                  const SizedBox(height: AppSpacing.sectionSeparation),
                  _buildAmenitiesSection(),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ),

          // Save button
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.horizontalPadding),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.dividerSeparator),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
          ),
          Expanded(
            child: Center(
              child: Text(
                l10n.filter,
                style: AppTypography.heading2,
              ),
            ),
          ),
          IconButton(
            onPressed: _handleReset,
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyTypeSection() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.propertyType, style: AppTypography.subhead),
        const SizedBox(height: AppSpacing.itemSeparation),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: _propertyTypes.map(_buildPropertyTypeChip).toList(),
        ),
      ],
    );
  }

  Widget _buildPropertyTypeChip(PropertyType type) {
    return GestureDetector(
      onTap: () => _togglePropertyType(type),
      child: Container(
        width: AppSizes.propertyTypeIconSize + AppSpacing.lg * 2,
        height: AppSizes.propertyTypeIconSize + AppSpacing.lg * 2,
        decoration: BoxDecoration(
          color:
              type.isSelected ? AppColors.accentLight : AppColors.surfaceCards,
          borderRadius: BorderRadius.circular(AppBorderRadius.cardsButtons),
          border: type.isSelected
              ? Border.all(color: AppColors.primaryAccent)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type.icon,
              size: AppSizes.iconMedium,
              color: type.isSelected
                  ? AppColors.primaryAccent
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              type.label,
              style: AppTypography.caption.copyWith(
                color: type.isSelected
                    ? AppColors.primaryAccent
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRangeSection() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.priceRange, style: AppTypography.subhead),
        const SizedBox(height: AppSpacing.itemSeparation),
        _buildPriceHistogram(),
        const SizedBox(height: AppSpacing.md),
        RangeSlider(
          values: _priceRange,
          min: widget.minPrice,
          max: widget.maxPrice,
          divisions: 20,
          activeColor: AppColors.primaryAccent,
          inactiveColor: AppColors.dividerSeparator,
          onChanged: (values) {
            setState(() {
              _priceRange = values;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '€${_priceRange.start.round()}',
              style: AppTypography.caption,
            ),
            Text(
              '€${_priceRange.end.round()}',
              style: AppTypography.caption,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceHistogram() {
    // Simplified histogram representation
    return Container(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(10, (index) {
          final isInRange = index >= 3 && index <= 7; // Mock data
          final height = 20.0 + (index % 3) * 15; // Mock heights

          return Container(
            width: AppSizes.histogramBarWidth,
            height: height,
            decoration: BoxDecoration(
              color: isInRange
                  ? AppColors.primaryAccent
                  : AppColors.dividerSeparator,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBedroomsSection() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.bedrooms, style: AppTypography.subhead),
        const SizedBox(height: AppSpacing.itemSeparation),
        Row(
          children: List.generate(5, (index) {
            final value = index + 1;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: _buildNumericChip(
                value.toString(),
                _bedrooms == value,
                () => setState(() => _bedrooms = value),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBedsSection() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.beds, style: AppTypography.subhead),
        const SizedBox(height: AppSpacing.itemSeparation),
        Row(
          children: List.generate(5, (index) {
            final value = index + 1;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: _buildNumericChip(
                value.toString(),
                _beds == value,
                () => setState(() => _beds = value),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildNumericChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppSizes.numericChipSize,
        height: AppSizes.numericChipSize,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryAccent : AppColors.surfaceCards,
          borderRadius: BorderRadius.circular(AppSizes.numericChipSize / 2),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.body.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmenitiesSection() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.amenities, style: AppTypography.subhead),
        const SizedBox(height: AppSpacing.itemSeparation),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: widget.availableAmenities.map((amenity) {
            final isSelected = _selectedAmenities.contains(amenity);
            return _buildAmenityChip(amenity, isSelected);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAmenityChip(String amenity, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleAmenity(amenity),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryAccent : AppColors.surfaceCards,
          borderRadius: BorderRadius.circular(AppBorderRadius.cardsButtons),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              const Icon(
                Icons.check,
                size: AppSizes.iconSmall,
                color: Colors.white,
              ),
            if (isSelected) const SizedBox(width: AppSpacing.xs),
            Text(
              amenity,
              style: AppTypography.body.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.horizontalPadding),
      child: AppButton.primary(
        text: l10n.saveFilter,
        onPressed: _handleSave,
      ),
    );
  }

  void _togglePropertyType(PropertyType type) {
    setState(() {
      final index = _propertyTypes.indexWhere((t) => t.label == type.label);
      if (index != -1) {
        _propertyTypes[index] = PropertyType(
          label: type.label,
          icon: type.icon,
          isSelected: !type.isSelected,
        );
      }
    });
  }

  void _toggleAmenity(String amenity) {
    setState(() {
      if (_selectedAmenities.contains(amenity)) {
        _selectedAmenities.remove(amenity);
      } else {
        _selectedAmenities.add(amenity);
      }
    });
  }

  void _handleReset() {
    setState(() {
      _propertyTypes = widget.propertyTypes
          .map((type) => PropertyType(
                label: type.label,
                icon: type.icon,
                isSelected: false,
              ))
          .toList();
      _priceRange = RangeValues(widget.minPrice, widget.maxPrice);
      _bedrooms = 1;
      _beds = 1;
      _selectedAmenities.clear();
    });
    widget.onReset?.call();
  }

  void _handleSave() {
    widget.onPropertyTypesChanged?.call(_propertyTypes);
    widget.onPriceRangeChanged?.call(_priceRange);
    widget.onBedroomsChanged?.call(_bedrooms);
    widget.onBedsChanged?.call(_beds);
    widget.onAmenitiesChanged?.call(_selectedAmenities);
    widget.onSave?.call();
    Navigator.of(context).pop();
  }
}
