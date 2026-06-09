import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/expense/expense_model.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/storage/storage_providers.dart';
import '../../utils/formatters/formatters.dart';
import '../expenses/utils/expense_helpers.dart';
import '../expenses/widgets/expense_details_sheet.dart';
import '../expenses/widgets/edit_expense_modal.dart';
import '../../core/constants/category_styles.dart';

// ---- Grouping mode ----
enum HistoryGroupMode { week, month }

// ---- Providers ----
final historyGroupModeProvider = StateProvider<HistoryGroupMode>(
  (_) => HistoryGroupMode.week,
);

class _WeekGroup {
  final String label;
  final DateTime weekStart;
  final DateTime weekEnd;
  final List<_DayGroup> days;
  final double total;

  const _WeekGroup({
    required this.label,
    required this.weekStart,
    required this.weekEnd,
    required this.days,
    required this.total,
  });
}

class _DayGroup {
  final DateTime date;
  final List<Expense> expenses;
  final double total;

  const _DayGroup({
    required this.date,
    required this.expenses,
    required this.total,
  });
}

class _MonthGroup {
  final String label;
  final int year;
  final int month;
  final List<_DayGroup> days;
  final double total;

  const _MonthGroup({
    required this.label,
    required this.year,
    required this.month,
    required this.days,
    required this.total,
  });
}

// ---- Build week-grouped data ----
List<_WeekGroup> _buildWeekGroups(List<Expense> expenses) {
  final byDay = <DateTime, List<Expense>>{};
  for (final e in expenses) {
    final day = DateTime(e.date.year, e.date.month, e.date.day);
    byDay.putIfAbsent(day, () => []).add(e);
  }

  final byWeek = <DateTime, List<DateTime>>{};
  for (final day in byDay.keys) {
    final monday = day.subtract(Duration(days: day.weekday - 1));
    final weekKey = DateTime(monday.year, monday.month, monday.day);
    byWeek.putIfAbsent(weekKey, () => []).add(day);
  }

  final sorted = byWeek.keys.toList()..sort((a, b) => b.compareTo(a));

  return sorted.map((weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final days = byWeek[weekStart]!..sort((a, b) => b.compareTo(a));
    final dayGroups = days.map((day) {
      final items = List<Expense>.from(byDay[day]!)
        ..sort((a, b) => b.date.compareTo(a.date));
      final total = items.fold(0.0, (s, e) => s + e.amount);
      return _DayGroup(date: day, expenses: items, total: total);
    }).toList();
    final total = dayGroups.fold(0.0, (s, g) => s + g.total);

    final startLabel = AppFormatters.formatDate(weekStart, format: 'MMM dd');
    final endLabel = AppFormatters.formatDate(weekEnd, format: 'MMM dd, yyyy');
    return _WeekGroup(
      label: '$startLabel – $endLabel',
      weekStart: weekStart,
      weekEnd: weekEnd,
      days: dayGroups,
      total: total,
    );
  }).toList();
}

// ---- Build month-grouped data ----
List<_MonthGroup> _buildMonthGroups(List<Expense> expenses) {
  final byDay = <DateTime, List<Expense>>{};
  for (final e in expenses) {
    final day = DateTime(e.date.year, e.date.month, e.date.day);
    byDay.putIfAbsent(day, () => []).add(e);
  }

  final byMonth = <DateTime, List<DateTime>>{};
  for (final day in byDay.keys) {
    final monthKey = DateTime(day.year, day.month);
    byMonth.putIfAbsent(monthKey, () => []).add(day);
  }

  final sorted = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));

  return sorted.map((monthKey) {
    final days = byMonth[monthKey]!..sort((a, b) => b.compareTo(a));
    final dayGroups = days.map((day) {
      final items = List<Expense>.from(byDay[day]!)
        ..sort((a, b) => b.date.compareTo(a.date));
      final total = items.fold(0.0, (s, e) => s + e.amount);
      return _DayGroup(date: day, expenses: items, total: total);
    }).toList();
    final total = dayGroups.fold(0.0, (s, g) => s + g.total);

    final label =
        AppFormatters.formatDate(monthKey, format: 'MMMM yyyy');
    return _MonthGroup(
      label: label,
      year: monthKey.year,
      month: monthKey.month,
      days: dayGroups,
      total: total,
    );
  }).toList();
}

// ---- Screen ----
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(currentUserIdProvider) ?? '';
      ref.read(expensesProvider.notifier).fetchExpenses(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(historyGroupModeProvider);
    final expensesState = ref.watch(expensesProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final hPad = isDesktop ? 24.0 : 16.0;

    // Sort all expenses newest first for grouping
    final allExpenses = List<Expense>.from(expensesState.expenses)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        elevation: 0,
        actions: [
          _GroupModeToggle(mode: mode),
          const SizedBox(width: 8),
        ],
      ),
      body: expensesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : allExpenses.isEmpty
          ? _EmptyHistory(onRefresh: () {
              final userId = ref.read(currentUserIdProvider) ?? '';
              ref.read(expensesProvider.notifier).fetchExpenses(userId);
            })
          : mode == HistoryGroupMode.week
          ? _WeekView(
              expenses: allExpenses,
              hPad: hPad,
              onTapExpense: _showDetails,
            )
          : _MonthView(
              expenses: allExpenses,
              hPad: hPad,
              onTapExpense: _showDetails,
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
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete expense?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
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
      ref.read(expensesProvider.notifier).deleteExpense(expense.id);
      return true;
    }
    return false;
  }
}

// ---- Group mode toggle ----
class _GroupModeToggle extends ConsumerWidget {
  final HistoryGroupMode mode;

  const _GroupModeToggle({required this.mode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleChip(
            label: 'Week',
            isActive: mode == HistoryGroupMode.week,
            onTap: () => ref
                .read(historyGroupModeProvider.notifier)
                .state = HistoryGroupMode.week,
          ),
          _ToggleChip(
            label: 'Month',
            isActive: mode == HistoryGroupMode.month,
            onTap: () => ref
                .read(historyGroupModeProvider.notifier)
                .state = HistoryGroupMode.month,
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isActive
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ---- Week View ----
class _WeekView extends StatelessWidget {
  final List<Expense> expenses;
  final double hPad;
  final void Function(Expense) onTapExpense;

  const _WeekView({
    required this.expenses,
    required this.hPad,
    required this.onTapExpense,
  });

  @override
  Widget build(BuildContext context) {
    final groups = _buildWeekGroups(expenses);

    return Scrollbar(
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 96),
        itemCount: groups.length,
        itemBuilder: (context, i) {
          final group = groups[i];
          return _WeekSection(
            group: group,
            onTapExpense: onTapExpense,
          );
        },
      ),
    );
  }
}

class _WeekSection extends StatefulWidget {
  final _WeekGroup group;
  final void Function(Expense) onTapExpense;

  const _WeekSection({
    required this.group,
    required this.onTapExpense,
  });

  @override
  State<_WeekSection> createState() => _WeekSectionState();
}

class _WeekSectionState extends State<_WeekSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Week header
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.group.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppFormatters.formatCurrency(widget.group.total),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            ...widget.group.days.map(
              (day) => _DaySection(
                day: day,
                onTapExpense: widget.onTapExpense,
              ),
            ),
        ],
      ),
    );
  }
}

// ---- Month View ----
class _MonthView extends StatelessWidget {
  final List<Expense> expenses;
  final double hPad;
  final void Function(Expense) onTapExpense;

  const _MonthView({
    required this.expenses,
    required this.hPad,
    required this.onTapExpense,
  });

  @override
  Widget build(BuildContext context) {
    final groups = _buildMonthGroups(expenses);

    return Scrollbar(
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 96),
        itemCount: groups.length,
        itemBuilder: (context, i) {
          final group = groups[i];
          return _MonthSection(
            group: group,
            onTapExpense: onTapExpense,
          );
        },
      ),
    );
  }
}

class _MonthSection extends StatefulWidget {
  final _MonthGroup group;
  final void Function(Expense) onTapExpense;

  const _MonthSection({
    required this.group,
    required this.onTapExpense,
  });

  @override
  State<_MonthSection> createState() => _MonthSectionState();
}

class _MonthSectionState extends State<_MonthSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month header
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.group.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppFormatters.formatCurrency(widget.group.total),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                  Text(
                    '${widget.group.days.fold<int>(0, (s, d) => s + d.expenses.length)} txns',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            ...widget.group.days.map(
              (day) => _DaySection(
                day: day,
                onTapExpense: widget.onTapExpense,
              ),
            ),
        ],
      ),
    );
  }
}

// ---- Shared Day Section ----
class _DaySection extends StatelessWidget {
  final _DayGroup day;
  final void Function(Expense) onTapExpense;

  const _DaySection({required this.day, required this.onTapExpense});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header row
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Text(
                  AppFormatters.formatDate(day.date, format: 'EEE, MMM dd'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  AppFormatters.formatCurrency(day.total),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ...day.expenses.map(
            (expense) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _HistoryExpenseTile(
                expense: expense,
                onTap: () => onTapExpense(expense),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Expense tile for history ----
class _HistoryExpenseTile extends StatefulWidget {
  final Expense expense;
  final VoidCallback onTap;

  const _HistoryExpenseTile({required this.expense, required this.onTap});

  @override
  State<_HistoryExpenseTile> createState() => _HistoryExpenseTileState();
}

class _HistoryExpenseTileState extends State<_HistoryExpenseTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final style = CategoryStyles.of(widget.expense.category);
    final notes = formatNotes(widget.expense.description);
    final timeLabel = AppFormatters.formatTime(
      widget.expense.date,
      format: 'HH:mm',
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _hovered
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered
                ? colorScheme.outline.withValues(alpha: 0.35)
                : colorScheme.outline.withValues(alpha: 0.18),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: style.tint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(style.icon, color: style.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.expense.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: style.color,
                          ),
                        ),
                        if (notes.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            notes,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppFormatters.formatCurrency(widget.expense.amount),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.error,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        timeLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---- Empty state ----
class _EmptyHistory extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyHistory({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.history_rounded,
              size: 32,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No expense history yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your expenses will appear here grouped by week and month.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.tonal(
            onPressed: onRefresh,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
