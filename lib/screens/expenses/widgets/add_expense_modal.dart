import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../models/expense/expense_model.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/storage/storage_providers.dart';
import 'amount_input.dart';
import 'category_selector.dart';
import 'payment_method_selector.dart';
import 'expense_notes_field.dart';
import 'expense_date_picker.dart';
import 'save_expense_button.dart';

Future<void> showAddExpenseModal(BuildContext context) {
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
            child: const AddExpenseForm(isDialog: true),
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
        child: const SafeArea(
          top: false,
          child: AddExpenseForm(isDialog: false),
        ),
      );
    },
  );
}

class AddExpenseForm extends ConsumerStatefulWidget {
  final bool isDialog;

  const AddExpenseForm({super.key, required this.isDialog});

  @override
  ConsumerState<AddExpenseForm> createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends ConsumerState<AddExpenseForm> {
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

  static const List<String> _paymentMethods = [
    'Cash',
    'GPay',
    'PhonePe',
    'Paytm',
    'Bank Transfer',
    'Card',
  ];

  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedCategory;
  String? _selectedPaymentMethod;
  DateTime _selectedDate = DateTime.now();
  bool _showValidation = false;

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
    return _isAmountValid &&
        _selectedCategory != null &&
        _selectedPaymentMethod != null;
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

    final userId = ref.read(currentUserIdProvider) ?? localUserId;

    final expense = Expense(
      id: const Uuid().v4(),
      userId: userId,
      amount: double.parse(_amountController.text.trim()),
      category: _selectedCategory!,
      description: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      date: _selectedDate,
      createdAt: DateTime.now(),
      updatedAt: null,
    );

    try {
      await ref.read(expensesProvider.notifier).addExpense(expense);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense saved successfully'),
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
          content: Text('Error saving expense: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                        'Add Expense',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Capture the essentials of this transaction',
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
            PaymentMethodSelector(
              methods: _paymentMethods,
              selectedMethod: _selectedPaymentMethod,
              onSelected: (value) {
                _markInteracted();
                setState(() => _selectedPaymentMethod = value);
              },
              showError: _showValidation && _selectedPaymentMethod == null,
            ),
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
                      onPressed: _handleSave,
                      isEnabled: _isFormValid,
                    ),
                  ),
                ],
              )
            else
              SaveExpenseButton(
                onPressed: _handleSave,
                isEnabled: _isFormValid,
              ),
          ],
        ),
      ),
    );
  }
}
