import 'package:flutter/material.dart';

import '../../../utils/formatters/formatters.dart';

class BudgetProgressCard extends StatelessWidget {
  final String title;
  final double spent;
  final double budget;
  final Color accentColor;
  final VoidCallback? onEditBudget;
  final VoidCallback? onResetBudget;

  const BudgetProgressCard({
    super.key,
    required this.title,
    required this.spent,
    required this.budget,
    required this.accentColor,
    this.onEditBudget,
    this.onResetBudget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = budget <= 0 ? 0.0 : (spent / budget).clamp(0.0, 1.0);
    final remaining = budget - spent;
    final hasBudget = budget > 0;
    final isOverBudget = hasBudget && remaining < 0;
    final progressColor = isOverBudget
        ? colorScheme.error
        : progress >= 0.8
        ? colorScheme.secondary
        : accentColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
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
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onEditBudget != null)
                IconButton(
                  onPressed: onEditBudget,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  tooltip: 'Edit budget',
                  visualDensity: VisualDensity.compact,
                )
              else
                Text(
                  hasBudget
                      ? '${(spent / budget * 100).toStringAsFixed(0)}% used'
                      : 'No budget set',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          if (onEditBudget != null) ...[
            const SizedBox(height: 4),
            Text(
              hasBudget
                  ? '${(spent / budget * 100).toStringAsFixed(0)}% used'
                  : 'No budget set',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _BudgetMetric(label: 'Spent', value: _formatCurrency(spent)),
              _BudgetMetric(
                label: isOverBudget ? 'Overspent' : 'Remaining',
                value: _formatCurrency(remaining.abs()),
                valueColor: isOverBudget ? colorScheme.error : null,
              ),
              _BudgetMetric(label: 'Budget', value: _formatCurrency(budget)),
            ],
          ),
          if (isOverBudget || (!hasBudget && onEditBudget != null)) ...[
            const SizedBox(height: 12),
            _BudgetAlert(
              message: isOverBudget
                  ? 'You are over your monthly budget.'
                  : 'Set a budget to unlock spending intelligence.',
              color: isOverBudget ? colorScheme.error : colorScheme.primary,
            ),
          ],
          if (onResetBudget != null && hasBudget) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onResetBudget,
                child: const Text('Reset budget'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    return AppFormatters.formatCurrency(value);
  }
}

class _BudgetMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _BudgetMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _BudgetAlert extends StatelessWidget {
  final String message;
  final Color color;

  const _BudgetAlert({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
