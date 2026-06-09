import 'package:flutter/material.dart';

import '../../utils/formatters/formatters.dart';

/// Extensions on BuildContext for responsive design
extension ResponsiveExtension on BuildContext {
  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Check if device is mobile (width < 600)
  bool get isMobile => screenWidth < 600;

  /// Check if device is tablet (width 600-900)
  bool get isTablet => screenWidth >= 600 && screenWidth < 900;

  /// Check if device is desktop (width >= 900)
  bool get isDesktop => screenWidth >= 900;

  /// Get safe area padding
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;
}

/// Extensions on String
extension StringExtension on String {
  /// Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  /// Check if string is numeric
  bool get isNumeric => double.tryParse(this) != null;
}

/// Extensions on DateTime
extension DateTimeExtension on DateTime {
  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Get formatted date string
  String toFormattedString() => '$year-$month-$day';
}

/// Extensions on double
extension DoubleExtension on double {
  /// Format as currency
  String toCurrency({String symbol = '₹'}) =>
      AppFormatters.formatCurrency(this, symbol: symbol);
}
