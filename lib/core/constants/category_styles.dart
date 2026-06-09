import 'package:flutter/material.dart';

class CategoryStyle {
  final IconData icon;
  final Color color;

  const CategoryStyle({required this.icon, required this.color});

  Color get tint => color.withValues(alpha: 0.12);
  Color get chipTint => color.withValues(alpha: 0.18);
}

class CategoryStyles {
  static const Map<String, CategoryStyle> _styles = {
    'Food': CategoryStyle(
      icon: Icons.restaurant_rounded,
      color: Color(0xFF6E8FA5),
    ),
    'Fuel': CategoryStyle(
      icon: Icons.local_gas_station_rounded,
      color: Color(0xFF7C6FAF),
    ),
    'Shopping': CategoryStyle(
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFF6EA39B),
    ),
    'Friends': CategoryStyle(
      icon: Icons.people_alt_rounded,
      color: Color(0xFF8A9B6E),
    ),
    'Subscriptions': CategoryStyle(
      icon: Icons.subscriptions_rounded,
      color: Color(0xFF9B7C7C),
    ),
    'Travel': CategoryStyle(
      icon: Icons.flight_rounded,
      color: Color(0xFF6E7F9C),
    ),
    'Health': CategoryStyle(
      icon: Icons.local_hospital_rounded,
      color: Color(0xFF9C7E6E),
    ),
    'Bills': CategoryStyle(
      icon: Icons.receipt_long_rounded,
      color: Color(0xFF7E9C85),
    ),
    'Entertainment': CategoryStyle(
      icon: Icons.movie_rounded,
      color: Color(0xFF7A9C8B),
    ),
    'Investment': CategoryStyle(
      icon: Icons.trending_up_rounded,
      color: Color(0xFF8E8A6D),
    ),
    'Luxury': CategoryStyle(
      icon: Icons.diamond_rounded,
      color: Color(0xFFB18AA8),
    ),
    'Miscellaneous': CategoryStyle(
      icon: Icons.category_rounded,
      color: Color(0xFF8A8A8A),
    ),
    'Rent': CategoryStyle(icon: Icons.home_rounded, color: Color(0xFF7FA8A8)),
    'Gifts': CategoryStyle(
      icon: Icons.card_giftcard_rounded,
      color: Color(0xFF8A7C9A),
    ),
    'Transport': CategoryStyle(
      icon: Icons.directions_car_rounded,
      color: Color(0xFF6D8AAE),
    ),
    'Utilities': CategoryStyle(
      icon: Icons.lightbulb_rounded,
      color: Color(0xFF9A8C6E),
    ),
    'Healthcare': CategoryStyle(
      icon: Icons.favorite_rounded,
      color: Color(0xFFB07A7A),
    ),
    'Other': CategoryStyle(
      icon: Icons.category_rounded,
      color: Color(0xFF8A8A8A),
    ),
  };

  static CategoryStyle of(String category) {
    return _styles[category] ??
        const CategoryStyle(
          icon: Icons.category_rounded,
          color: Color(0xFF8A8A8A),
        );
  }
}
