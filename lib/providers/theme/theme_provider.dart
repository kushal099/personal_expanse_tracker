import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod provider for theme mode
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});

/// Riverpod provider to toggle theme
final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(),
);

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system);

  void toggleTheme() {
    if (state == ThemeMode.light) {
      state = ThemeMode.dark;
    } else if (state == ThemeMode.dark) {
      state = ThemeMode.light;
    } else {
      state = ThemeMode.light;
    }
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}
