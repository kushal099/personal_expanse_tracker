import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'navigation_models.dart';

/// Navigation state
class NavigationState {
  final NavigationTab currentTab;
  final bool isSidebarCollapsed;

  const NavigationState({
    this.currentTab = NavigationTab.dashboard,
    this.isSidebarCollapsed = false,
  });

  NavigationState copyWith({
    NavigationTab? currentTab,
    bool? isSidebarCollapsed,
  }) {
    return NavigationState(
      currentTab: currentTab ?? this.currentTab,
      isSidebarCollapsed: isSidebarCollapsed ?? this.isSidebarCollapsed,
    );
  }
}

/// Navigation provider for managing current tab and sidebar state
final navigationProvider =
    StateNotifierProvider<NavigationNotifier, NavigationState>(
      (ref) => NavigationNotifier(),
    );

/// Navigation notifier for handling navigation changes
class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier() : super(const NavigationState());

  /// Navigate to a specific tab
  void navigateTo(NavigationTab tab) {
    state = state.copyWith(currentTab: tab);
  }

  /// Navigate using route string
  void navigateToRoute(String route) {
    final tab = NavigationTabExtension.fromId(route.replaceFirst('/', ''));
    navigateTo(tab);
  }

  /// Toggle sidebar collapse state
  void toggleSidebar() {
    state = state.copyWith(isSidebarCollapsed: !state.isSidebarCollapsed);
  }

  /// Collapse sidebar
  void collapseSidebar() {
    state = state.copyWith(isSidebarCollapsed: true);
  }

  /// Expand sidebar
  void expandSidebar() {
    state = state.copyWith(isSidebarCollapsed: false);
  }

  /// Reset to default state
  void reset() {
    state = const NavigationState();
  }
}

/// Provider to get current navigation item
final currentNavigationItemProvider = Provider<NavigationItem>((ref) {
  final tab = ref.watch(navigationProvider).currentTab;
  return tab.toItem();
});

/// Provider to check if sidebar is collapsed
final isSidebarCollapsedProvider = Provider<bool>((ref) {
  return ref.watch(navigationProvider).isSidebarCollapsed;
});

/// Provider to get all navigation items
final navigationItemsProvider = Provider<List<NavigationItem>>((ref) {
  return navigationItems;
});
