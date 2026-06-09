import 'package:flutter/material.dart';

class AppConstants {
  // Padding & Margins
  static const double paddingXs = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXl = 32.0;

  // Border radius
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;

  // Responsive breakpoints
  static const double mobileWidth = 600;
  static const double tabletWidth = 900;
  static const double desktopWidth = 1200;

  // Animation durations
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration longDuration = Duration(milliseconds: 500);

  // Shadows
  static const BoxShadow cardShadow = BoxShadow(
    color: Colors.black12,
    blurRadius: 4,
    offset: Offset(0, 2),
  );
}

class ExpenseCategories {
  static const List<String> categories = [
    'Food',
    'Transport',
    'Entertainment',
    'Shopping',
    'Utilities',
    'Healthcare',
    'Other',
  ];
}

class CurrencyConstants {
  static const String defaultCurrency = 'INR';
  static const String currencySymbol = '₹';
}
