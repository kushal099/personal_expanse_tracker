import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/receivable/receivable_model.dart';
import '../../providers/storage/storage_providers.dart';
import '../../providers/auth/auth_provider.dart';
import 'providers/receivables_providers.dart';
import 'widgets/receivable_modal.dart';
import 'widgets/receivables_widgets.dart';

/// Receivables screen - track money owed to user
class ReceivablesScreen extends ConsumerStatefulWidget {
  const ReceivablesScreen({super.key});

  @override
  ConsumerState<ReceivablesScreen> createState() => _ReceivablesScreenState();
}

class _ReceivablesScreenState extends ConsumerState<ReceivablesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(currentUserIdProvider) ?? '';
      ref.read(receivablesProvider.notifier).fetchReceivables(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider) ?? '';
    final receivablesState = ref.watch(receivablesProvider);
    final listState = ref.watch(receivablesListProvider);
    final receivables = ref.watch(filteredReceivablesProvider(userId));
    final stats = ref.watch(receivablesStatsProvider(userId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receivables'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(receivablesProvider.notifier).fetchReceivables(userId),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: receivablesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref
                  .read(receivablesProvider.notifier)
                  .fetchReceivables(userId),
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
                              'Money Owed to You',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Track pending, overdue, and collected money',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ReceivablesStatsHeader(stats: stats),
                            const SizedBox(height: 16),
                            ReceivablesFilterBar(
                              selectedFilter: listState.filter,
                              onChanged: (filter) => ref
                                  .read(receivablesListProvider.notifier)
                                  .setFilter(filter),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (receivables.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 24 : 16,
                          ),
                          child: EmptyReceivablesState(
                            title:
                                listState.filter == ReceivableStatusFilter.all
                                ? 'No receivables yet'
                                : 'No receivables match this filter',
                            message:
                                listState.filter == ReceivableStatusFilter.all
                                ? 'Track money owed to you with due dates.'
                                : 'Try another status or add a new receivable.',
                            onAddPressed: () => showAddReceivableModal(context),
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
                                  final receivable = receivables[index];
                                  return ReceivableCard(
                                    receivable: receivable,
                                    status: receivableStatus(receivable),
                                    onMarkPaid: () => _markPaid(receivable),
                                    onEdit: () => showEditReceivableModal(
                                      context,
                                      receivable: receivable,
                                    ),
                                    onDelete: () => _confirmDelete(receivable),
                                  );
                                }, childCount: receivables.length),
                              );
                            }

                            return SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final receivable = receivables[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: ReceivableCard(
                                    receivable: receivable,
                                    status: receivableStatus(receivable),
                                    onMarkPaid: () => _markPaid(receivable),
                                    onEdit: () => showEditReceivableModal(
                                      context,
                                      receivable: receivable,
                                    ),
                                    onDelete: () => _confirmDelete(receivable),
                                  ),
                                );
                              }, childCount: receivables.length),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddReceivableModal(context),
        tooltip: 'Add Receivable',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Future<void> _markPaid(Receivable receivable) async {
    await ref
        .read(receivablesProvider.notifier)
        .markReceivablePaid(receivable.id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${receivable.fromPerson} marked as paid')),
    );
  }

  Future<void> _confirmDelete(Receivable receivable) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete receivable?'),
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

    if (confirmed != true) {
      return;
    }

    await ref
        .read(receivablesProvider.notifier)
        .deleteReceivable(receivable.id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Receivable deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref.read(receivablesProvider.notifier).addReceivable(receivable);
          },
        ),
      ),
    );
  }
}
