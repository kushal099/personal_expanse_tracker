import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/payable/payable_model.dart';
import '../../providers/storage/storage_providers.dart';
import '../../providers/auth/auth_provider.dart';
import 'providers/payables_providers.dart';
import 'widgets/payable_history_sheet.dart';
import 'widgets/payable_modal.dart';
import 'widgets/payable_settlement_modal.dart';
import 'widgets/payables_widgets.dart';

class PayablesScreen extends ConsumerStatefulWidget {
  const PayablesScreen({super.key});

  @override
  ConsumerState<PayablesScreen> createState() => _PayablesScreenState();
}

class _PayablesScreenState extends ConsumerState<PayablesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(currentUserIdProvider) ?? '';
      ref.read(payablesProvider.notifier).fetchPayables(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider) ?? '';
    final payablesState = ref.watch(payablesProvider);
    final listState = ref.watch(payablesListProvider);
    final payables = ref.watch(filteredPayablesProvider(userId));
    final stats = ref.watch(payablesStatsProvider(userId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payables'),
        elevation: 0,

      ),
      body: payablesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(payablesProvider.notifier).fetchPayables(userId),
              child: Scrollbar(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          isDesktop ? 24 : 16,
                          16,
                          isDesktop ? 24 : 16,
                          8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Money You Owe',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Track due dates, partial payments, and settlements',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 20),
                            PayablesStatsHeader(stats: stats),
                            const SizedBox(height: 16),
                            PayablesFilterBar(
                              selectedFilter: listState.filter,
                              onChanged: (filter) => ref
                                  .read(payablesListProvider.notifier)
                                  .setFilter(filter),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (payables.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 24 : 16,
                          ),
                          child: _EmptyPayablesState(
                            title: listState.filter == PayableStatusFilter.all
                                ? 'No payables yet'
                                : 'No payables match this filter',
                            message: listState.filter == PayableStatusFilter.all
                                ? 'Add payables to track what you owe.'
                                : 'Try another status or add a new payable.',
                            onAddPressed: () => showAddPayableModal(context),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          isDesktop ? 24 : 16,
                          8,
                          isDesktop ? 24 : 16,
                          96,
                        ),
                        sliver: SliverLayoutBuilder(
                          builder: (context, constraints) {
                            final useGrid = constraints.crossAxisExtent >= 980;

                            if (useGrid) {
                              return SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      childAspectRatio: 3.2,
                                    ),
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final payable = payables[index];
                                  return PayableCard(
                                    payable: payable,
                                    status: payableDisplayStatus(payable),
                                    onSettle: () => showPayableSettlementModal(
                                      context,
                                      payable: payable,
                                    ),
                                    onMarkPaid: () => _markPaid(payable),
                                    onEdit: () => showEditPayableModal(
                                      context,
                                      payable: payable,
                                    ),
                                    onDelete: () => _confirmDelete(payable),
                                    onHistory: () => showPayableHistorySheet(
                                      context,
                                      payable: payable,
                                    ),
                                  );
                                }, childCount: payables.length),
                              );
                            }

                            return SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final payable = payables[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: PayableCard(
                                    payable: payable,
                                    status: payableDisplayStatus(payable),
                                    onSettle: () => showPayableSettlementModal(
                                      context,
                                      payable: payable,
                                    ),
                                    onMarkPaid: () => _markPaid(payable),
                                    onEdit: () => showEditPayableModal(
                                      context,
                                      payable: payable,
                                    ),
                                    onDelete: () => _confirmDelete(payable),
                                    onHistory: () => showPayableHistorySheet(
                                      context,
                                      payable: payable,
                                    ),
                                  ),
                                );
                              }, childCount: payables.length),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddPayableModal(context),
        tooltip: 'Add Payable',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Future<void> _markPaid(Payable payable) async {
    await ref.read(payablesProvider.notifier).markPayablePaid(payable.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${payable.toPerson} marked as paid')),
    );
  }

  Future<void> _confirmDelete(Payable payable) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete payable?'),
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

    if (confirmed != true) return;

    await ref.read(payablesProvider.notifier).deletePayable(payable.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Payable deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref.read(payablesProvider.notifier).addPayable(payable);
          },
        ),
      ),
    );
  }
}

class _EmptyPayablesState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onAddPressed;

  const _EmptyPayablesState({
    required this.title,
    required this.message,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card_rounded,
              size: 64,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onAddPressed,
              child: const Text('Add Payable'),
            ),
          ],
        ),
      ),
    );
  }
}
