import 'package:flutter/material.dart';

import '../../../core/constants/category_styles.dart';
import '../../../utils/formatters/formatters.dart';

/// Chart placeholder widget
class ChartPlaceholder extends StatelessWidget {
  final String title;
  final String type; // 'pie', 'bar', 'line'
  final double height;

  const ChartPlaceholder({
    super.key,
    required this.title,
    required this.type,
    this.height = 250,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final icon = switch (type) {
      'pie' => Icons.pie_chart_rounded,
      'bar' => Icons.bar_chart_rounded,
      'line' => Icons.show_chart_rounded,
      _ => Icons.insights_rounded,
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: height,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: colorScheme.onSurfaceVariant, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      'No data yet',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$type chart placeholder',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Category breakdown item
class CategoryBreakdownItem extends StatelessWidget {
  final String category;
  final double amount;
  final double percentage;
  final Color? color;

  const CategoryBreakdownItem({
    super.key,
    required this.category,
    required this.amount,
    required this.percentage,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = CategoryStyles.of(category);
    final resolvedColor = color ?? style.color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: resolvedColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(style.icon, size: 16, color: resolvedColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      AppFormatters.formatCurrency(amount),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 6,
                    backgroundColor: resolvedColor.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(resolvedColor),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Period selector
class PeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final List<String> periods;
  final ValueChanged<String> onPeriodChanged;

  const PeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.periods,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periods
            .map(
              (period) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ChoiceChip(
                  label: Text(period),
                  selected: selectedPeriod == period,
                  onSelected: (_) => onPeriodChanged(period),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// Summary stat card
class AnalyticsSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String? change;
  final bool isPositive;

  const AnalyticsSummaryCard({
    super.key,
    required this.label,
    required this.value,
    this.change,
    this.isPositive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (change != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (isPositive ? Colors.green : Colors.red)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      change!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isPositive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
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
