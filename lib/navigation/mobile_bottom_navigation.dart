import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/navigation_models.dart';
import '../../core/navigation/navigation_provider.dart';

/// Mobile bottom navigation bar widget
class MobileBottomNavigation extends ConsumerWidget {
  const MobileBottomNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(navigationProvider);
    final currentTab = navigationState.currentTab;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: navigationItems.map((item) {
            final isActive = currentTab.name == item.id;

            return _MobileNavigationItem(
              item: item,
              isActive: isActive,
              onTap: () {
                ref
                    .read(navigationProvider.notifier)
                    .navigateTo(NavigationTabExtension.fromId(item.id));
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Individual mobile navigation item
class _MobileNavigationItem extends StatelessWidget {
  final NavigationItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _MobileNavigationItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: 24,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).textTheme.bodySmall?.color,
                  fontWeight: isActive ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
