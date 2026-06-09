import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/receivable/receivable_model.dart';
import '../../../providers/storage/storage_providers.dart';
import '../../../utils/formatters/formatters.dart';
import '../../expenses/widgets/amount_input.dart';
import '../../expenses/widgets/expense_notes_field.dart';
import '../../expenses/widgets/save_expense_button.dart';

Future<void> showReceivableSettlementModal(
  BuildContext context, {
  required Receivable receivable,
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
            constraints: const BoxConstraints(maxWidth: 520),
            child: ReceivableSettlementForm(
              receivable: receivable,
              isDialog: true,
            ),
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
          child: ReceivableSettlementForm(
            receivable: receivable,
            isDialog: false,
          ),
        ),
      );
    },
  );
}

class ReceivableSettlementForm extends ConsumerStatefulWidget {
  final Receivable receivable;
  final bool isDialog;

  const ReceivableSettlementForm({
    super.key,
    required this.receivable,
    required this.isDialog,
  });

  @override
  ConsumerState<ReceivableSettlementForm> createState() =>
      _ReceivableSettlementFormState();
}

class _ReceivableSettlementFormState
    extends ConsumerState<ReceivableSettlementForm> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _showValidation = false;

  @override
  void initState() {
    super.initState();
    _amountController.text =
        widget.receivable.remainingAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isAmountValid {
    final value = double.tryParse(_amountController.text.trim());
    return value != null &&
        value > 0 &&
        value <= widget.receivable.remainingAmount;
  }

  void _markInteracted() {
    if (!_showValidation) {
      setState(() => _showValidation = true);
    }
  }

  Future<void> _handleSave() async {
    if (!_isAmountValid) {
      setState(() => _showValidation = true);
      return;
    }

    final amount = double.parse(_amountController.text.trim());
    final note = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    await ref
        .read(receivablesProvider.notifier)
        .addReceivableSettlement(widget.receivable.id, amount, note: note);

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settlement recorded')));
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
                        'Record Collection',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Remaining ${AppFormatters.formatCurrency(widget.receivable.remainingAmount)}',
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
            AmountInput(
              controller: _amountController,
              onChanged: (_) {
                _markInteracted();
                setState(() {});
              },
              showError: _showValidation && !_isAmountValid,
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
                      label: 'Record Collection',
                      onPressed: _handleSave,
                      isEnabled: _isAmountValid,
                    ),
                  ),
                ],
              )
            else
              SaveExpenseButton(
                label: 'Record Collection',
                onPressed: _handleSave,
                isEnabled: _isAmountValid,
              ),
          ],
        ),
      ),
    );
  }
}
