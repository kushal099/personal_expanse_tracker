import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/navigation_models.dart';
import '../../core/navigation/navigation_provider.dart';

/// Desktop sidebar navigation widget
class DesktopSidebar extends ConsumerWidget {
  const DesktopSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(navigationProvider);
    final isCollapsed = navigationState.isSidebarCollapsed;
    final currentTab = navigationState.currentTab;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isCollapsed ? 80 : 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header with logo/title
          SizedBox(
            height: 80,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 8 : 24,
                vertical: 16,
              ),
              child: Row(
                children: [
                  // Logo/Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.wallet_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  if (!isCollapsed) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expanse',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Tracker',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Navigation items
          Expanded(
            child: ListView.builder(
              itemCount: navigationItems.length,
              itemBuilder: (context, index) {
                final item = navigationItems[index];
                final isActive = currentTab.name == item.id;

                return _SidebarNavigationItem(
                  item: item,
                  isActive: isActive,
                  isCollapsed: isCollapsed,
                  onTap: () {
                    ref
                        .read(navigationProvider.notifier)
                        .navigateTo(NavigationTabExtension.fromId(item.id));
                  },
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Footer with collapse button
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 8 : 16,
              vertical: 16,
            ),
            child: Tooltip(
              message: isCollapsed ? 'Expand' : 'Collapse',
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      ref.read(navigationProvider.notifier).toggleSidebar();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Center(
                      child: Icon(
                        isCollapsed
                            ? Icons.chevron_right_rounded
                            : Icons.chevron_left_rounded,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual sidebar navigation item
class _SidebarNavigationItem extends StatelessWidget {
  final NavigationItem item;
  final bool isActive;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarNavigationItem({
    required this.item,
    required this.isActive,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCollapsed ? 8 : 12,
        vertical: 8,
      ),
      child: Tooltip(
        message: isCollapsed ? item.label : '',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isActive
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  // Icon with active indicator
                  Stack(
                    children: [
                      Icon(
                        item.icon,
                        size: 24,
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      if (isActive && !isCollapsed)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (!isCollapsed) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        item.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: isActive ? FontWeight.w600 : null,
                          color: isActive
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
