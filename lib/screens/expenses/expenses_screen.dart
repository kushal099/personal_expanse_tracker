import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/expense/expense_model.dart';
import '../../models/recurring/recurring_expense_template.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/storage/storage_providers.dart';
import '../../utils/formatters/formatters.dart';
import '../settings/providers/settings_providers.dart';
import 'providers/expenses_providers.dart';
import 'providers/recurring_expenses_providers.dart';
import 'widgets/add_expense_modal.dart';
import 'widgets/edit_expense_modal.dart';
import 'widgets/expense_details_sheet.dart';
import 'widgets/expense_filters_sheet.dart';
import 'widgets/expense_list_item.dart';
import 'widgets/expense_section_header.dart';
import 'widgets/expense_stats_header.dart';
import 'widgets/expenses_widgets.dart';
import 'widgets/recurring_expense_modal.dart';
import 'widgets/recurring_expense_widgets.dart';

/// Expenses screen - manage and view expenses
class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider) ?? '';
    final expensesState = ref.watch(expensesProvider);
    final filterState = ref.watch(expensesListProvider);
    final groupedExpenses = ref.watch(groupedExpensesProvider);
    final categories = ref.watch(expenseCategoriesProvider);
    final stats = ref.watch(expenseStatsProvider);
    final recurringUiState = ref.watch(recurringTemplateUiProvider);
    final recurringTemplates = ref.watch(
      filteredRecurringTemplatesProvider(userId),
    );
    final dueTemplates = ref.watch(dueRecurringTemplatesProvider(userId));
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        elevation: 0,

      ),
      body: expensesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                final userId2 = ref.read(currentUserIdProvider) ?? '';
                ref.read(expensesProvider.notifier).refresh(userId2);
              },
              child: Scrollbar(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ExpenseStatsHeader(stats: stats),
                            const SizedBox(height: 16),
                            ExpenseSearchBar(
                              onSearch: (query) {
                                ref
                                    .read(expensesListProvider.notifier)
                                    .search(query);
                              },
                              onFilterTapped: () {
                                showExpenseFiltersSheet(
                                  context,
                                  categories: categories,
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: filterState.hasActiveFilters
                                  ? _ActiveFilters(
                                      key: const ValueKey('active-filters'),
                                      filterState: filterState,
                                      notifier: ref.read(
                                        expensesListProvider.notifier,
                                      ),
                                      onClearAll: () => ref
                                          .read(expensesListProvider.notifier)
                                          .clearAllFilters(),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 16),
                            RecurringExpensesSectionHeader(
                              onCreate: () =>
                                  showRecurringExpenseModal(context),
                            ),
                            const SizedBox(height: 10),
                            RecurringTemplateFilterBar(
                              selected: recurringUiState.filter,
                              onChange: (filter) => ref
                                  .read(recurringTemplateUiProvider.notifier)
                                  .setFilter(filter),
                            ),
                            const SizedBox(height: 10),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: recurringTemplates.isEmpty
                                  ? Container(
                                      key: const ValueKey('recurring-empty'),
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline
                                              .withValues(alpha: 0.18),
                                        ),
                                      ),
                                      child: Text(
                                        'No recurring templates in this view.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    )
                                  : LayoutBuilder(
                                      key: const ValueKey('recurring-list'),
                                      builder: (context, constraints) {
                                        final twoColumn =
                                            constraints.maxWidth >= 900;
                                        if (!twoColumn) {
                                          return Column(
                                            children: recurringTemplates.map((
                                              template,
                                            ) {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 10,
                                                ),
                                                child: RecurringTemplateCard(
                                                  template: template,
                                                  isDue: dueTemplates.any(
                                                    (item) =>
                                                        item.id == template.id,
                                                  ),
                                                  isOverdue:
                                                      DateTime(
                                                        template
                                                            .nextDueDate
                                                            .year,
                                                        template
                                                            .nextDueDate
                                                            .month,
                                                        template
                                                            .nextDueDate
                                                            .day,
                                                      ).isBefore(
                                                        DateTime(
                                                          DateTime.now().year,
                                                          DateTime.now().month,
                                                          DateTime.now().day,
                                                        ),
                                                      ),
                                                  onGenerate: () =>
                                                      _generateFromTemplate(
                                                        template,
                                                        settings
                                                            .recurringQuickGenerateEnabled,
                                                      ),
                                                  onEdit: () =>
                                                      showRecurringExpenseModal(
                                                        context,
                                                        template: template,
                                                      ),
                                                  onDelete: () =>
                                                      _confirmRecurringDelete(
                                                        template,
                                                      ),
                                                ),
                                              );
                                            }).toList(),
                                          );
                                        }
                                        return Wrap(
                                          spacing: 10,
                                          runSpacing: 10,
                                          children: recurringTemplates.map((
                                            template,
                                          ) {
                                            final width =
                                                (constraints.maxWidth - 10) / 2;
                                            return SizedBox(
                                              width: width,
                                              child: RecurringTemplateCard(
                                                template: template,
                                                isDue: dueTemplates.any(
                                                  (item) =>
                                                      item.id == template.id,
                                                ),
                                                isOverdue:
                                                    DateTime(
                                                      template.nextDueDate.year,
                                                      template
                                                          .nextDueDate
                                                          .month,
                                                      template.nextDueDate.day,
                                                    ).isBefore(
                                                      DateTime(
                                                        DateTime.now().year,
                                                        DateTime.now().month,
                                                        DateTime.now().day,
                                                      ),
                                                    ),
                                                onGenerate: () =>
                                                    _generateFromTemplate(
                                                      template,
                                                      settings
                                                          .recurringQuickGenerateEnabled,
                                                    ),
                                                onEdit: () =>
                                                    showRecurringExpenseModal(
                                                      context,
                                                      template: template,
                                                    ),
                                                onDelete: () =>
                                                    _confirmRecurringDelete(
                                                      template,
                                                    ),
                                              ),
                                            );
                                          }).toList(),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (groupedExpenses.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: EmptyExpensesState(
                            title: filterState.hasActiveFilters
                                ? 'No expenses match your filters'
                                : 'No expenses yet',
                            message: filterState.hasActiveFilters
                                ? 'Try clearing or adjusting your filters.'
                                : 'Start tracking your spending',
                            primaryLabel: filterState.hasActiveFilters
                                ? 'Clear Filters'
                                : 'Add Expense',
                            onPrimaryPressed: filterState.hasActiveFilters
                                ? () => ref
                                      .read(expensesListProvider.notifier)
                                      .clearAllFilters()
                                : () => showAddExpenseModal(context),
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final group = groupedExpenses[index];
                          return Padding(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              index == 0 ? 8 : 20,
                              16,
                              0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ExpenseSectionHeader(
                                  date: group.date,
                                  total: group.total,
                                  count: group.expenses.length,
                                ),
                                const SizedBox(height: 8),
                                ...group.expenses.map((expense) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 10.0,
                                    ),
                                    child: Dismissible(
                                      key: ValueKey(expense.id),
                                      direction: DismissDirection.endToStart,
                                      confirmDismiss: (_) =>
                                          _confirmDelete(expense),
                                      background: _DismissBackground(),
                                      child: ExpenseListItem(
                                        expense: expense,
                                        onTap: () => _showDetails(expense),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        }, childCount: groupedExpenses.length),
                      ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddExpenseModal(context);
        },
        tooltip: 'Add Expense',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDetails(Expense expense) {
    showExpenseDetailsSheet(
      context: context,
      expense: expense,
      onEdit: () => showEditExpenseModal(context, expense: expense),
      onDelete: () => _confirmDelete(expense),
    );
  }

  Future<bool> _confirmDelete(Expense expense) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteExpenseWithUndo(expense);
      return true;
    }
    return false;
  }

  void _deleteExpenseWithUndo(Expense expense) {
    final messenger = ScaffoldMessenger.of(context);
    ref.read(expensesProvider.notifier).deleteExpense(expense.id);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Expense deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref.read(expensesProvider.notifier).addExpense(expense);
          },
        ),
      ),
    );
  }

  Future<void> _generateFromTemplate(
    RecurringExpenseTemplate template,
    bool enabled,
  ) async {
    if (!enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recurring quick-generate is disabled in settings.'),
        ),
      );
      return;
    }
    await ref
        .read(recurringExpenseActionsProvider)
        .generateExpenseFromTemplate(template);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Generated ${template.category} expense from recurring template',
        ),
      ),
    );
  }

  Future<void> _confirmRecurringDelete(
    RecurringExpenseTemplate template,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete recurring template?'),
        content: const Text('This template will no longer generate expenses.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await ref
        .read(recurringTemplatesProvider.notifier)
        .deleteTemplate(template.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Recurring template deleted')));
  }
}

class _DismissBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerRight,
      child: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
    );
  }
}

class _ActiveFilters extends StatelessWidget {
  final ExpensesListState filterState;
  final ExpensesListNotifier notifier;
  final VoidCallback onClearAll;

  const _ActiveFilters({
    super.key,
    required this.filterState,
    required this.notifier,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final chips = <Widget>[
      ...filterState.selectedFilters.map(
        (category) => CategoryFilterChip(
          label: category,
          isSelected: true,
          onSelected: () => notifier.filterByCategory(category),
        ),
      ),
    ];

    if (filterState.dateRange != null) {
      final range = filterState.dateRange!;
      final startLabel = AppFormatters.formatDate(
        range.start,
        format: 'MMM dd',
      );
      final endLabel = AppFormatters.formatDate(range.end, format: 'MMM dd');
      chips.add(
        Chip(
          label: Text('Date: $startLabel - $endLabel'),
          onDeleted: () => notifier.setDateRange(null),
        ),
      );
    }

    if (filterState.minAmount != null || filterState.maxAmount != null) {
      final minLabel = filterState.minAmount != null
          ? AppFormatters.formatCurrency(filterState.minAmount!)
          : '';
      final maxLabel = filterState.maxAmount != null
          ? AppFormatters.formatCurrency(filterState.maxAmount!)
          : '';
      final label =
          filterState.minAmount != null && filterState.maxAmount != null
          ? '$minLabel - $maxLabel'
          : filterState.minAmount != null
          ? 'From $minLabel'
          : 'Up to $maxLabel';
      chips.add(
        Chip(
          label: Text('Amount: $label'),
          onDeleted: () => notifier.setAmountRange(null, null),
        ),
      );
    }

    if (filterState.sortBy != 'newest') {
      chips.add(
        Chip(
          label: Text('Sort: ${_sortLabel(filterState.sortBy)}'),
          onDeleted: () => notifier.setSortBy('newest'),
        ),
      );
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: chips),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onClearAll,
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.onSurfaceVariant,
          ),
          child: const Text('Clear all filters'),
        ),
      ],
    );
  }
}

String _sortLabel(String sortBy) {
  switch (sortBy) {
    case 'oldest':
      return 'Oldest';
    case 'highest':
      return 'Highest amount';
    case 'lowest':
      return 'Lowest amount';
    default:
      return 'Newest';
  }
}
