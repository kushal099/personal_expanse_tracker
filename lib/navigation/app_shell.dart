import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/navigation_models.dart';
import '../../core/navigation/navigation_provider.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/expenses/expenses_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/receivables/receivables_screen.dart';
import '../screens/payables/payables_screen.dart';
import '../screens/settings/settings_screen.dart';
import 'desktop_sidebar.dart';
import 'mobile_bottom_navigation.dart';

/// Responsive app shell that handles navigation layout
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(navigationProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      body: Row(
        children: [
          // Desktop sidebar (visible only on desktop)
          if (isDesktop) const DesktopSidebar(),

          // Main content area
          Expanded(
            child: Column(
              children: [
                // Main content
                Expanded(
                  child: _buildScreenContent(navigationState.currentTab),
                ),

                // Mobile bottom navigation (visible only on mobile)
                if (!isDesktop) const MobileBottomNavigation(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build screen content based on current tab
  Widget _buildScreenContent(NavigationTab currentTab) {
    switch (currentTab.name) {
      case 'dashboard':
        return const DashboardScreen();
      case 'expenses':
        return const ExpensesScreen();
      case 'analytics':
        return const AnalyticsScreen();
      case 'receivables':
        return const ReceivablesScreen();
      case 'payables':
        return const PayablesScreen();
      case 'settings':
        return const SettingsScreen();
      default:
        return const DashboardScreen();
    }
  }
}
