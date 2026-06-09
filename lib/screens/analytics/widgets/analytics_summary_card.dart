import 'package:flutter/material.dart';

class AnalyticsSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subLabel;
  final String? change;
  final bool isPositive;
  final Color? accentColor;

  const AnalyticsSummaryCard({
    super.key,
    required this.label,
    required this.value,
    this.subLabel,
    this.change,
    this.isPositive = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final resolvedAccent = accentColor ?? colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (change != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (isPositive ? Colors.green : Colors.red).withValues(
                      alpha: 0.2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    change!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          if (subLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              subLabel!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: resolvedAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
