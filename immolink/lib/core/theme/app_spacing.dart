class AppSpacing {
  // Grid: 4 pt base, 8 pt increment
  static const double base = 4.0;
  static const double xs = 4.0; // 1 * base
  static const double sm = 8.0; // 2 * base
  static const double md = 12.0; // 3 * base
  static const double lg = 16.0; // 4 * base
  static const double xl = 20.0; // 5 * base
  static const double xxl = 24.0; // 6 * base
  static const double xxxl = 32.0; // 8 * base

  // Specific spacing from design specifications
  static const double horizontalPadding = 16.0; // Screen inset
  static const double sectionSeparation = 24.0; // Sections separated by 24pt
  static const double itemSeparation =
      16.0; // Items within section separated by 16pt

  // Component specific spacing
  static const double cardPadding = 16.0;
  static const double buttonPadding = 12.0;
  static const double searchBarPadding = 12.0;
  static const double tabVerticalPadding = 12.0;
}

class AppBorderRadius {
  // Border Radius specifications
  static const double cardsButtons = 12.0; // Cards & Buttons: 12 pt
  static const double modalsOverlays = 16.0; // Modals & Overlays: 16 pt
  static const double searchBar = 8.0; // Search bar: 8 pt radius pill
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
}

class AppSizes {
  // Component heights from design specifications
  static const double topAppBarHeight = 64.0;
  static const double searchBarHeight = 40.0;
  static const double buttonHeight = 48.0;
  static const double propertyCardImageHeight = 120.0;
  static const double propertyCardHeight = 200.0;
  static const double heroImageHeight = 260.0;
  static const double bottomNavHeight = 80.0;

  // Icon sizes
  static const double iconSmall = 20.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;

  // Touch targets (minimum 44x44 pt for accessibility)
  static const double minTouchTarget = 44.0;

  // Filter panel specific
  static const double filterPanelHeight = 0.8; // 80% of screen height
  static const double numericChipSize = 40.0;
  static const double propertyTypeIconSize = 48.0;
  static const double rangeSliderHandleSize = 24.0;
  static const double histogramBarWidth = 6.0;
  static const double histogramBarSpacing = 12.0;
}
