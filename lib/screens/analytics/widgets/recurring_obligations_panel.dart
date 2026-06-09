import 'package:flutter/material.dart';

import '../../../utils/formatters/formatters.dart';
import '../models/analytics_models.dart';

class RecurringObligationsPanel extends StatelessWidget {
  final RecurringObligationSummary summary;
  final BurnRateForecast forecast;
  final List<CategoryStat> topCategories;

  const RecurringObligationsPanel({
    super.key,
    required this.summary,
    required this.forecast,
    required this.topCategories,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 10,
          children: [
            _Metric(
              label: 'Monthly fixed',
              value: AppFormatters.formatCurrency(summary.monthlyTotal),
            ),
            _Metric(
              label: 'Annualized',
              value: AppFormatters.formatCurrency(summary.annualTotal),
            ),
            _Metric(
              label: 'Upcoming (7d)',
              value: summary.upcomingCount == 0
                  ? 'None'
                  : AppFormatters.formatCurrency(summary.upcomingTotal),
            ),
            _Metric(
              label: 'Daily fixed',
              value: AppFormatters.formatCurrency(summary.averageDaily),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Burn-rate forecast',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 10,
          children: [
            _Metric(
              label: 'Daily spend',
              value: AppFormatters.formatCurrency(forecast.actualDaily),
            ),
            _Metric(
              label: 'Daily fixed',
              value: AppFormatters.formatCurrency(forecast.recurringDaily),
            ),
            _Metric(
              label: 'Projected month end',
              value: AppFormatters.formatCurrency(forecast.projectedMonthEnd),
            ),
            _Metric(
              label: 'Budget remaining',
              value: forecast.budget > 0
                  ? AppFormatters.formatCurrency(forecast.remainingBudget)
                  : 'Set budget',
              valueColor:
                  forecast.budget > 0 && forecast.remainingBudget < 0
                      ? colorScheme.error
                      : null,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (topCategories.isNotEmpty) ...[
          Text(
            'Top fixed categories',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: topCategories
                .take(3)
                .map(
                  (stat) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CategoryRow(stat: stat),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _Metric({required this.label, required this.value, this.valueColor});

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

class _CategoryRow extends StatelessWidget {
  final CategoryStat stat;

  const _CategoryRow({required this.stat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            stat.category,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          AppFormatters.formatCurrency(stat.amount),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
