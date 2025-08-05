import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CategoryUtils {
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'plumbing':
        return Colors.blue;
      case 'electrical':
        return Colors.orange;
      case 'heating/cooling':
      case 'heating':
      case 'cooling':
        return Colors.red;
      case 'appliance':
      case 'appliances':
        return Colors.purple;
      case 'structural':
        return Colors.brown;
      case 'cleaning':
        return Colors.green;
      case 'pest control':
      case 'pest_control':
        return Colors.amber;
      case 'other':
        return Colors.teal;
      default:
        return AppColors.textTertiary;
    }
  }

  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical':
        return Icons.electrical_services;
      case 'heating/cooling':
      case 'heating':
      case 'cooling':
        return Icons.thermostat;
      case 'appliance':
      case 'appliances':
        return Icons.kitchen;
      case 'structural':
        return Icons.foundation;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'pest control':
      case 'pest_control':
        return Icons.bug_report;
      case 'other':
        return Icons.build;
      default:
        return Icons.handyman;
    }
  }
}
