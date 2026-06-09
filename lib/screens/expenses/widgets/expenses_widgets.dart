import 'package:flutter/material.dart';

import '../../../core/constants/category_styles.dart';

/// Expense item card
class ExpenseCard extends StatelessWidget {
  final String id;
  final String title;
  final String category;
  final String amount;
  final String date;
  final Color categoryColor;
  final IconData categoryIcon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ExpenseCard({
    super.key,
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.categoryColor,
    required this.categoryIcon,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(categoryIcon, color: categoryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: categoryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.error,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 32,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: onEdit,
                        padding: const EdgeInsets.all(0),
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          size: 18,
                          color: Colors.red,
                        ),
                        onPressed: onDelete,
                        padding: const EdgeInsets.all(0),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Filter chip for categories
class CategoryFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const CategoryFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final style = CategoryStyles.of(label);

    return FilterChip(
      label: Text(label),
      avatar: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: style.tint,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(style.icon, size: 12, color: style.color),
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: colorScheme.surface,
      side: BorderSide(
        color: isSelected
            ? style.color.withValues(alpha: 0.6)
            : colorScheme.outline.withValues(alpha: 0.3),
      ),
      selectedColor: style.chipTint,
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: isSelected ? style.color : colorScheme.onSurface,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

/// Search and filter bar
class ExpenseSearchBar extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final VoidCallback onFilterTapped;

  const ExpenseSearchBar({
    super.key,
    required this.onSearch,
    required this.onFilterTapped,
  });

  @override
  State<ExpenseSearchBar> createState() => _ExpenseSearchBarState();
}

class _ExpenseSearchBarState extends State<ExpenseSearchBar> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Search expenses...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        widget.onSearch('');
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
            ),
            onChanged: (value) {
              widget.onSearch(value);
              setState(() {});
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.tune),
          onPressed: widget.onFilterTapped,
        ),
      ],
    );
  }
}

/// Empty state for expenses
class EmptyExpensesState extends StatelessWidget {
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimaryPressed;

  const EmptyExpensesState({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimaryPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.receipt_long,
              size: 28,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onPrimaryPressed,
            icon: const Icon(Icons.add),
            label: Text(primaryLabel),
          ),
        ],
      ),
    );
  }
}
