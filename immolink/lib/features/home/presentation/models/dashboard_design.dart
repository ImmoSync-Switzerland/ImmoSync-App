import '../../../../l10n/app_localizations.dart';

enum DashboardDesign {
  glass,
  classic;
}

DashboardDesign dashboardDesignFromId(String? id) {
  if (id == null) return DashboardDesign.glass;
  return DashboardDesign.values.firstWhere(
    (design) => design.id == id,
    orElse: () => DashboardDesign.glass,
  );
}

extension DashboardDesignX on DashboardDesign {
  String get id => name;

  String localizedName(AppLocalizations l10n) {
    switch (this) {
      case DashboardDesign.glass:
        return l10n.dashboardDesignGlass;
      case DashboardDesign.classic:
        return l10n.dashboardDesignClassic;
    }
  }
}
