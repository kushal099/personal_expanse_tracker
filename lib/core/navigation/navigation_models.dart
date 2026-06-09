import 'package:flutter/material.dart';

/// Get the string ID for a navigation tab
String getTabId(NavigationTab tab) {
  switch (tab) {
    case NavigationTab.dashboard:
      return 'dashboard';
    case NavigationTab.expenses:
      return 'expenses';
    case NavigationTab.analytics:
      return 'analytics';
    case NavigationTab.receivables:
      return 'receivables';
    case NavigationTab.payables:
      return 'payables';
    case NavigationTab.history:
      return 'history';
    case NavigationTab.settings:
      return 'settings';
  }
}

/// Navigation item model
class NavigationItem {
  final String id;
  final String label;
  final IconData icon;
  final String route;

  const NavigationItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
  });
}

/// Available navigation tabs
enum NavigationTab {
  dashboard,
  expenses,
  analytics,
  receivables,
  payables,
  history,
  settings,
}

/// Extension to get navigation item details
extension NavigationTabExtension on NavigationTab {
  String get label {
    switch (this) {
      case NavigationTab.dashboard:
        return 'Dashboard';
      case NavigationTab.expenses:
        return 'Expenses';
      case NavigationTab.analytics:
        return 'Analytics';
      case NavigationTab.receivables:
        return 'Receivables';
      case NavigationTab.payables:
        return 'Payables';
      case NavigationTab.history:
        return 'History';
      case NavigationTab.settings:
        return 'Settings';
    }
  }

  IconData get icon {
    switch (this) {
      case NavigationTab.dashboard:
        return Icons.dashboard_rounded;
      case NavigationTab.expenses:
        return Icons.receipt_long_rounded;
      case NavigationTab.analytics:
        return Icons.analytics_rounded;
      case NavigationTab.receivables:
        return Icons.handshake_rounded;
      case NavigationTab.payables:
        return Icons.payments_rounded;
      case NavigationTab.history:
        return Icons.history_rounded;
      case NavigationTab.settings:
        return Icons.settings_rounded;
    }
  }

  String get id => getTabId(this);

  String get route => '/$id';

  NavigationItem toItem() =>
      NavigationItem(id: id, label: label, icon: icon, route: route);

  static NavigationTab fromId(String id) {
    return NavigationTab.values.firstWhere(
      (tab) => getTabId(tab) == id,
      orElse: () => NavigationTab.dashboard,
    );
  }
}

/// List of all navigation items
final List<NavigationItem> navigationItems = [
  NavigationTab.dashboard,
  NavigationTab.expenses,
  NavigationTab.analytics,
  NavigationTab.receivables,
  NavigationTab.payables,
  NavigationTab.history,
  NavigationTab.settings,
].map((tab) => tab.toItem()).toList();
