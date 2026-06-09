import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/budget/budget_providers.dart';

Future<void> showBudgetSettingsModal(BuildContext context) {
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
            constraints: const BoxConstraints(maxWidth: 460),
            child: const BudgetSettingsForm(isDialog: true),
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
        child: const SafeArea(top: false, child: BudgetSettingsForm()),
      );
    },
  );
}

class BudgetSettingsForm extends ConsumerStatefulWidget {
  final bool isDialog;

  const BudgetSettingsForm({super.key, this.isDialog = false});

  @override
  ConsumerState<BudgetSettingsForm> createState() => _BudgetSettingsFormState();
}

class _BudgetSettingsFormState extends ConsumerState<BudgetSettingsForm> {
  final _budgetController = TextEditingController();
  bool _showValidation = false;

  @override
  void initState() {
    super.initState();
    final amount = ref.read(monthlyBudgetProvider('userId')).amount;
    if (amount > 0) {
      _budgetController.text = amount.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final value = double.tryParse(_budgetController.text.trim());
    return value != null && value > 0;
  }

  Future<void> _save() async {
    if (!_isValid) {
      setState(() => _showValidation = true);
      return;
    }

    await ref
        .read(monthlyBudgetProvider('userId').notifier)
        .setBudget(double.parse(_budgetController.text.trim()));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Monthly budget updated')));
    Navigator.of(context).pop();
  }

  Future<void> _reset() async {
    await ref.read(monthlyBudgetProvider('userId').notifier).resetBudget();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Monthly budget reset')));
    Navigator.of(context).pop();
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
                        'Monthly Budget',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Set the spending target for this month',
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
            TextFormField(
              controller: _budgetController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Budget amount',
                hintText: '0.00',
                prefixText: 'Rs ',
                errorText: _showValidation && !_isValid
                    ? 'Enter a valid budget'
                    : null,
              ),
              onChanged: (_) {
                if (!_showValidation) {
                  setState(() => _showValidation = true);
                } else {
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 20),
            if (widget.isDialog)
              Row(
                children: [
                  TextButton(onPressed: _reset, child: const Text('Reset')),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isValid ? _save : null,
                    child: const Text('Save Budget'),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: _isValid ? _save : null,
                    child: const Text('Save Budget'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _reset,
                    child: const Text('Reset Budget'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
