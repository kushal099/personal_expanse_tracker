import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/category_styles.dart';
import '../../models/reminder/reminder_model.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/budget/budget_providers.dart';
import '../../providers/debt/debt_providers.dart';
import '../../providers/storage/storage_providers.dart'
    show totalPayablesProvider;
import '../../providers/sync/sync_providers.dart';
import '../../utils/formatters/formatters.dart';
import '../expenses/widgets/add_expense_modal.dart';
import '../expenses/providers/recurring_expenses_providers.dart';
import '../receivables/widgets/receivable_modal.dart';
import '../settings/providers/reminder_providers.dart';
import '../settings/providers/settings_providers.dart';
import 'providers/dashboard_providers.dart';
import 'widgets/dashboard_widgets.dart';
import '../../widgets/common/financial_insight_widgets.dart';

/// Dashboard screen - main screen showing overview
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly.year == today.year &&
        dateOnly.month == today.month &&
        dateOnly.day == today.day) {
      return 'Today';
    } else if (dateOnly.year == yesterday.year &&
        dateOnly.month == yesterday.month &&
        dateOnly.day == yesterday.day) {
      return 'Yesterday';
    }
    return DateFormat('MMM dd').format(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final userId = ref.watch(currentUserIdProvider) ?? '';
    final recentExpenses = ref.watch(recentExpensesProvider(userId));

    final monthlySpend = ref.watch(monthlySpendProvider(userId));
    final transactionCount = ref.watch(transactionCountProvider(userId));
    final dailyAverage = ref.watch(dailyAverageProvider(userId));
    final receivablesTotal = ref.watch(receivablesTotalProvider(userId));
    final payablesTotal = ref.watch(totalPayablesProvider(userId));
    final netBalance = ref.watch(netBalanceProvider(userId));
    final overdueDebtCount = ref.watch(overdueDebtCountProvider(userId));
    final debtInsights = ref.watch(debtInsightsProvider(userId));
    final budgetMetrics = ref.watch(budgetMetricsProvider(userId));
    final budgetIntelligence = ref.watch(budgetIntelligenceProvider(userId));
    final reminders = ref.watch(upcomingRemindersProvider);
    final settings = ref.watch(settingsProvider);
    final upcomingRecurring = ref.watch(
      upcomingRecurringTemplatesProvider(userId),
    );
    final dueRecurring = ref.watch(dueRecurringTemplatesProvider(userId));
    final recurringItems = [
      ...dueRecurring,
      ...upcomingRecurring.where(
        (template) => !dueRecurring.any((item) => item.id == template.id),
      ),
    ];

    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final summaryCards = [
      SummaryCard(
        title: 'Cycle Spend',
        value: AppFormatters.formatCurrency(monthlySpend),
        subtitle: 'Since salary reset',
        icon: Icons.trending_down_rounded,
        accentColor: colorScheme.error,
      ),
      SummaryCard(
        title: 'Receivables',
        value: AppFormatters.formatCurrency(receivablesTotal),
        subtitle: 'Outstanding',
        icon: Icons.handshake_rounded,
        accentColor: colorScheme.primary,
      ),
      SummaryCard(
        title: 'Transactions',
        value: transactionCount.toString(),
        subtitle: 'Current cycle',
        icon: Icons.receipt_long_rounded,
        accentColor: colorScheme.secondary,
      ),
      SummaryCard(
        title: 'Daily Average',
        value: AppFormatters.formatCurrency(dailyAverage),
        subtitle: 'Last 30 days',
        icon: Icons.calendar_month_rounded,
        accentColor: colorScheme.tertiary,
      ),
    ];

    final debtCards = [
      SummaryCard(
        title: 'Payables',
        value: AppFormatters.formatCurrency(payablesTotal),
        subtitle: 'You owe',
        icon: Icons.payments_rounded,
        accentColor: colorScheme.error,
      ),
      SummaryCard(
        title: 'Overdue Debts',
        value: overdueDebtCount.toString(),
        subtitle: overdueDebtCount == 0 ? 'All caught up' : 'Needs attention',
        icon: Icons.warning_amber_rounded,
        accentColor: overdueDebtCount == 0
            ? colorScheme.tertiary
            : colorScheme.error,
      ),
      SummaryCard(
        title: 'Net Balance',
        value: AppFormatters.formatCurrency(netBalance),
        subtitle: overdueDebtCount == 0
            ? 'No overdue debts'
            : '$overdueDebtCount overdue items',
        icon: Icons.account_balance_rounded,
        accentColor: netBalance >= 0 ? colorScheme.tertiary : colorScheme.error,
      ),
    ];

    final recentTransactions = recentExpenses.take(5).map((e) {
      final style = CategoryStyles.of(e.category);
      return (
        title: e.description ?? e.category,
        category: e.category,
        amount: '-${AppFormatters.formatCurrency(e.amount)}',
        date: _formatDate(e.date),
        icon: style.icon,
        color: style.color,
        expense: e,
      );
    }).toList();

    final transactions = recentTransactions;
    final quickActions = [
      _QuickAction(
        label: 'Add Expense',
        icon: Icons.add_rounded,
        onPressed: () => showAddExpenseModal(context),
      ),
      _QuickAction(
        label: 'Add Receivable',
        icon: Icons.handshake_rounded,
        onPressed: () => showAddReceivableModal(context),
      ),
      _QuickAction(
        label: 'Set Budget',
        icon: Icons.flag_rounded,
        onPressed: () => showBudgetSettingsModal(context),
      ),
      _QuickAction(
        label: 'Reset Cycle',
        icon: Icons.restart_alt_rounded,
        onPressed: () => _confirmSalaryCycleReset(context, ref),
      ),
      _QuickAction(
        label: 'View Analytics',
        icon: Icons.analytics_rounded,
        onPressed: () {},
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(syncProvider.notifier).syncNow(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: dashboardState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(syncProvider.notifier).syncNow(),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 1100;
                    final summaryColumns = constraints.maxWidth >= 1200
                        ? 4
                        : constraints.maxWidth >= 900
                        ? 3
                        : constraints.maxWidth >= 600
                        ? 2
                        : 1;
                    final summaryAspectRatio = constraints.maxWidth >= 1200
                        ? 2.9
                        : constraints.maxWidth >= 900
                        ? 2.6
                        : constraints.maxWidth >= 600
                        ? 2.4
                        : 2.7;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your financial position at a glance',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),

                        SectionHeader(
                          title: 'Financial Overview',
                          subtitle:
                              'Key signals from your current salary cycle',
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          itemCount: summaryCards.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: summaryColumns,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: summaryAspectRatio,
                              ),
                          itemBuilder: (context, index) => summaryCards[index],
                        ),
                        const SizedBox(height: 24),

                        SectionHeader(
                          title: 'Debt Snapshot',
                          subtitle: 'Receivables, payables, and net position',
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          itemCount: debtCards.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: constraints.maxWidth >= 900
                                    ? 3
                                    : constraints.maxWidth >= 600
                                    ? 2
                                    : 1,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: constraints.maxWidth >= 900
                                    ? 2.7
                                    : 2.6,
                              ),
                          itemBuilder: (context, index) => debtCards[index],
                        ),
                        if (debtInsights.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          ...debtInsights
                              .take(2)
                              .map(
                                (insight) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: InsightBanner(insight: insight),
                                ),
                              ),
                        ],
                        const SizedBox(height: 24),

                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SectionHeader(
                                      title: 'Budget Progress',
                                      subtitle: 'Monthly targets and pacing',
                                    ),
                                    const SizedBox(height: 12),
                                    BudgetProgressCard(
                                      title: 'Monthly Budget',
                                      spent: budgetMetrics.spent,
                                      budget: budgetMetrics.budget,
                                      accentColor: colorScheme.primary,
                                      onEditBudget: () =>
                                          showBudgetSettingsModal(context),
                                      onResetBudget: () => ref
                                          .read(
                                            monthlyBudgetProvider(
                                              userId,
                                            ).notifier,
                                          )
                                          .resetBudget(),
                                    ),
                                    if (budgetIntelligence
                                        .insights
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      InsightBanner(
                                        insight:
                                            budgetIntelligence.insights.first,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SectionHeader(
                                      title: 'Quick Actions',
                                      subtitle: 'Move faster with shortcuts',
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: _sectionCardDecoration(
                                        context,
                                      ),
                                      child: Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: quickActions
                                            .map(
                                              (action) => QuickActionButton(
                                                label: action.label,
                                                icon: action.icon,
                                                onPressed: action.onPressed,
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeader(
                                title: 'Budget Progress',
                                subtitle: 'Monthly targets and pacing',
                              ),
                              const SizedBox(height: 12),
                              BudgetProgressCard(
                                title: 'Monthly Budget',
                                spent: budgetMetrics.spent,
                                budget: budgetMetrics.budget,
                                accentColor: colorScheme.primary,
                                onEditBudget: () =>
                                    showBudgetSettingsModal(context),
                                onResetBudget: () => ref
                                    .read(
                                      monthlyBudgetProvider(userId).notifier,
                                    )
                                    .resetBudget(),
                              ),
                              if (budgetIntelligence.insights.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                InsightBanner(
                                  insight: budgetIntelligence.insights.first,
                                ),
                              ],
                              const SizedBox(height: 24),
                              SectionHeader(
                                title: 'Quick Actions',
                                subtitle: 'Move faster with shortcuts',
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: _sectionCardDecoration(context),
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: quickActions
                                      .map(
                                        (action) => QuickActionButton(
                                          label: action.label,
                                          icon: action.icon,
                                          onPressed: action.onPressed,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ],
                          ),

                        if (reminders.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          SectionHeader(
                            title: 'Upcoming Reminders',
                            subtitle:
                                'Automated nudges from your finance signals',
                          ),
                          const SizedBox(height: 12),
                          ...reminders
                              .take(3)
                              .map(
                                (reminder) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: InsightBanner(
                                    insight: SmartFinancialInsight(
                                      title: reminder.title,
                                      message: reminder.message,
                                      icon: _reminderIcon(reminder.type),
                                      severity: _severity(reminder.severity),
                                    ),
                                  ),
                                ),
                              ),
                        ],

                        if (upcomingRecurring.isNotEmpty ||
                            dueRecurring.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          SectionHeader(
                            title: 'Upcoming Recurring',
                            subtitle: 'Fixed obligations and due templates',
                            actionLabel: dueRecurring.isNotEmpty
                                ? 'Generate due'
                                : null,
                            onAction: dueRecurring.isNotEmpty
                                ? () async {
                                    if (!settings
                                        .recurringQuickGenerateEnabled) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Recurring quick-generate is disabled in settings.',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    final generated = await ref
                                        .read(recurringExpenseActionsProvider)
                                        .generateDueExpenses(userId);
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          generated == 0
                                              ? 'No due recurring expenses to generate.'
                                              : 'Generated $generated recurring expenses.',
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: _sectionCardDecoration(context),
                            child: Column(
                              children: [
                                ...recurringItems
                                    .take(3)
                                    .map(
                                      (template) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: UpcomingRecurringTile(
                                          template: template,
                                          isDue: dueRecurring.any(
                                            (item) => item.id == template.id,
                                          ),
                                          isOverdue:
                                              DateTime(
                                                template.nextDueDate.year,
                                                template.nextDueDate.month,
                                                template.nextDueDate.day,
                                              ).isBefore(
                                                DateTime(
                                                  DateTime.now().year,
                                                  DateTime.now().month,
                                                  DateTime.now().day,
                                                ),
                                              ),
                                          onGenerate: () async {
                                            if (!settings
                                                .recurringQuickGenerateEnabled) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Recurring quick-generate is disabled in settings.',
                                                  ),
                                                ),
                                              );
                                              return;
                                            }
                                            await ref
                                                .read(
                                                  recurringExpenseActionsProvider,
                                                )
                                                .generateExpenseFromTemplate(
                                                  template,
                                                );
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Generated ${template.category} expense.',
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                        SectionHeader(
                          title: 'Recent Transactions',
                          subtitle: transactions.isNotEmpty
                              ? 'Latest activity from your accounts'
                              : 'No transactions yet',
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: _sectionCardDecoration(context),
                          child: transactions.isEmpty
                              ? const _DashboardEmptyState()
                              : Column(
                                  children: List.generate(transactions.length, (
                                    index,
                                  ) {
                                    final transaction = transactions[index];
                                    return Column(
                                      children: [
                                        TransactionTile(
                                          title: transaction.title,
                                          category: transaction.category,
                                          amount: transaction.amount,
                                          date: transaction.date,
                                          icon: transaction.icon,
                                          accentColor: transaction.color,
                                        ),
                                        if (index != transactions.length - 1)
                                          Divider(
                                            height: 1,
                                            indent: 8,
                                            endIndent: 8,
                                            color: colorScheme.outline
                                                .withValues(alpha: 0.12),
                                          ),
                                      ],
                                    );
                                  }),
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
    );
  }
}

Future<void> _confirmSalaryCycleReset(
  BuildContext context,
  WidgetRef ref,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Start new salary cycle?'),
      content: const Text(
        'This resets dashboard and budget tracking from today. '
        'Your older expenses, receivables, payables, and analytics history stay saved.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Start Cycle'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  await ref.read(settingsProvider.notifier).resetSalaryCycle();
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('New salary cycle started')));
}

IconData _reminderIcon(ReminderType type) {
  switch (type) {
    case ReminderType.budgetWarning:
      return Icons.warning_amber_rounded;
    case ReminderType.overdueReceivable:
      return Icons.priority_high_rounded;
    case ReminderType.upcomingRecurringExpense:
      return Icons.repeat_rounded;
    case ReminderType.monthlyBudgetPrompt:
      return Icons.flag_rounded;
  }
}

InsightSeverity _severity(ReminderSeverity severity) {
  switch (severity) {
    case ReminderSeverity.danger:
      return InsightSeverity.danger;
    case ReminderSeverity.warning:
      return InsightSeverity.warning;
    case ReminderSeverity.success:
      return InsightSeverity.healthy;
    case ReminderSeverity.info:
      return InsightSeverity.info;
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
}

BoxDecoration _sectionCardDecoration(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: colorScheme.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: colorScheme.outline.withValues(alpha: 0.18)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 14,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

class _DashboardEmptyState extends StatelessWidget {
  const _DashboardEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start adding expenses to see them here.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
