import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/expense/expense_model.dart';
import '../../../providers/storage/storage_providers.dart';
import '../utils/expense_helpers.dart';
import 'amount_input.dart';
import 'category_selector.dart';
import 'expense_date_picker.dart';
import 'expense_notes_field.dart';
import 'save_expense_button.dart';

Future<void> showEditExpenseModal(
  BuildContext context, {
  required Expense expense,
}) {
  final isDesktop = MediaQuery.of(context).size.width >= 900;

  if (isDesktop) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: EditExpenseForm(expense: expense, isDialog: true),
          ),
        );
      },
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: EditExpenseForm(expense: expense, isDialog: false),
        ),
      );
    },
  );
}

class EditExpenseForm extends ConsumerStatefulWidget {
  final Expense expense;
  final bool isDialog;

  const EditExpenseForm({
    super.key,
    required this.expense,
    required this.isDialog,
  });

  @override
  ConsumerState<EditExpenseForm> createState() => _EditExpenseFormState();
}

class _EditExpenseFormState extends ConsumerState<EditExpenseForm> {
  static const List<String> _categories = [
    'Food',
    'Friends',
    'Fuel',
    'Shopping',
    'Luxury',
    'Rent',
    'Bills',
    'Subscriptions',
    'Travel',
    'Health',
    'Gifts',
    'Entertainment',
    'Investment',
    'Miscellaneous',
  ];

  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _showValidation = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.expense.amount.toStringAsFixed(2),
    );
    _notesController = TextEditingController(
      text: widget.expense.description ?? '',
    );
    _selectedCategory = widget.expense.category;
    _selectedDate = widget.expense.date;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isAmountValid {
    final text = _amountController.text.trim();
    final value = double.tryParse(text);
    return value != null && value > 0;
  }

  bool get _isFormValid {
    return _isAmountValid && _selectedCategory != null;
  }

  void _markInteracted() {
    if (!_showValidation) {
      setState(() => _showValidation = true);
    }
  }

  void _handleSave() async {
    if (!_isFormValid) {
      setState(() => _showValidation = true);
      return;
    }

    final updated = widget.expense.copyWith(
      amount: double.parse(_amountController.text.trim()),
      category: _selectedCategory,
      description: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      date: _selectedDate,
      updatedAt: DateTime.now(),
    );

    try {
      await ref
          .read(expensesProvider.notifier)
          .updateExpense(widget.expense.id, updated);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense updated successfully'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating expense: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final paymentMethod = formatPaymentMethod(_notesController.text);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, widget.isDialog ? 20 : 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.isDialog)
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Expense',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Update the details of this transaction',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final isTwoColumn = constraints.maxWidth >= 520;
                final amountField = AmountInput(
                  controller: _amountController,
                  onChanged: (_) {
                    _markInteracted();
                    setState(() {});
                  },
                  showError: _showValidation && !_isAmountValid,
                );
                final dateField = ExpenseDatePicker(
                  selectedDate: _selectedDate,
                  onChanged: (date) {
                    _markInteracted();
                    setState(() => _selectedDate = date);
                  },
                );

                if (isTwoColumn) {
                  return Row(
                    children: [
                      Expanded(child: amountField),
                      const SizedBox(width: 12),
                      Expanded(child: dateField),
                    ],
                  );
                }

                return Column(
                  children: [
                    amountField,
                    const SizedBox(height: 12),
                    dateField,
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            CategorySelector(
              categories: _categories,
              selectedCategory: _selectedCategory,
              onSelected: (value) {
                _markInteracted();
                setState(() => _selectedCategory = value);
              },
              showError: _showValidation && _selectedCategory == null,
            ),
            const SizedBox(height: 16),
            _InfoRow(label: 'Payment method', value: paymentMethod),
            const SizedBox(height: 16),
            ExpenseNotesField(
              controller: _notesController,
              onChanged: (_) => _markInteracted(),
            ),
            const SizedBox(height: 20),
            if (widget.isDialog)
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SaveExpenseButton(
                      label: 'Save Changes',
                      onPressed: _handleSave,
                      isEnabled: _isFormValid,
                    ),
                  ),
                ],
              )
            else
              SaveExpenseButton(
                label: 'Save Changes',
                onPressed: _handleSave,
                isEnabled: _isFormValid,
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
