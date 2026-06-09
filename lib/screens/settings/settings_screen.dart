import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/onboarding/onboarding_provider.dart';
import '../../providers/sync/sync_providers.dart';
import 'providers/productivity_providers.dart';
import 'providers/reminder_providers.dart';
import 'providers/settings_providers.dart';
import 'widgets/export_modal.dart';
import 'widgets/productivity_widgets.dart';

/// Settings screen - app configuration and preferences
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final reminders = ref.watch(upcomingRemindersProvider);
    final backups = ref.watch(backupProvider);
    final backupNotifier = ref.read(backupProvider.notifier);
    final currencies = ref.watch(currenciesProvider);
    final exportFormats = ref.watch(exportFormatsProvider);
    final export = ref.watch(exportProvider);

    ref.listen(backupProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
      }
      if (previous?.isLoading == true &&
          next.isLoading == false &&
          next.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup operation completed')),
        );
      }
    });

    ref.listen(exportProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
      }
      if (previous?.isRunning == true &&
          next.isRunning == false &&
          next.error == null &&
          next.lastFile != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export generated: ${next.lastFile!.fileName}'),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: settings.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await settingsNotifier.loadSettings();
                await backupNotifier.loadBackups();
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final useTwoColumns = constraints.maxWidth >= 980;
                  final content = [
                    _SettingsSection(
                      title: 'Preferences',
                      children: [
                        DropdownButtonFormField<String>(
                          key: ValueKey('currency-${settings.currency}'),
                          initialValue: settings.currency,
                          decoration: const InputDecoration(
                            labelText: 'Default currency',
                          ),
                          items: currencies
                              .map(
                                (currency) => DropdownMenuItem(
                                  value: currency,
                                  child: Text(currency),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            settingsNotifier.setCurrency(value);
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                            'export-format-${settings.defaultExportFormat}',
                          ),
                          initialValue: settings.defaultExportFormat,
                          decoration: const InputDecoration(
                            labelText: 'Default export format',
                          ),
                          items: exportFormats
                              .map(
                                (format) => DropdownMenuItem(
                                  value: format,
                                  child: Text(format.toUpperCase()),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            settingsNotifier.setDefaultExportFormat(value);
                          },
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Analytics insights'),
                          subtitle: const Text(
                            'Show smart insight cards in analytics views',
                          ),
                          value: settings.analyticsInsightsEnabled,
                          onChanged:
                              settingsNotifier.setAnalyticsInsightsEnabled,
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Recurring quick-generate'),
                          subtitle: const Text(
                            'Enable one-tap generation from due templates',
                          ),
                          value: settings.recurringQuickGenerateEnabled,
                          onChanged:
                              settingsNotifier.setRecurringQuickGenerateEnabled,
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.restart_alt_rounded),
                          title: const Text('Salary cycle'),
                          subtitle: Text(
                            'Current cycle started ${_formatCycleDate(settings.currentCycleStartDate)}',
                          ),
                          trailing: TextButton(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Start new salary cycle?'),
                                  content: const Text(
                                    'Dashboard and budget tracking will restart from today. '
                                    'Previous records remain saved for history and analytics.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('Start'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed != true) return;
                              await settingsNotifier.resetSalaryCycle();
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                      ],
                    ),
                    _SettingsSection(
                      title: 'Reminders',
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Enable reminders'),
                          value: settings.remindersEnabled,
                          onChanged: settingsNotifier.setRemindersEnabled,
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Budget warnings'),
                          value: settings.budgetWarningReminderEnabled,
                          onChanged: settings.remindersEnabled
                              ? settingsNotifier.setBudgetWarningReminderEnabled
                              : null,
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Overdue receivable reminders'),
                          value: settings.overdueReceivableReminderEnabled,
                          onChanged: settings.remindersEnabled
                              ? settingsNotifier
                                    .setOverdueReceivableReminderEnabled
                              : null,
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Recurring due reminders'),
                          value: settings.recurringDueReminderEnabled,
                          onChanged: settings.remindersEnabled
                              ? settingsNotifier.setRecurringDueReminderEnabled
                              : null,
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Monthly budget reminders'),
                          value: settings.monthlyBudgetReminderEnabled,
                          onChanged: settings.remindersEnabled
                              ? settingsNotifier.setMonthlyBudgetReminderEnabled
                              : null,
                        ),
                        const SizedBox(height: 8),
                        if (reminders.isEmpty)
                          Text(
                            'No upcoming reminders right now.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          )
                        else
                          ...reminders.map(
                            (reminder) => ReminderCard(reminder: reminder),
                          ),
                      ],
                    ),
                    _SettingsSection(
                      title: 'Export & Backup',
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () => showExportModal(context),
                          icon: const Icon(Icons.file_download_rounded),
                          label: const Text('Open Export Center'),
                        ),
                        if (export.lastFile != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Last export: ${export.lastFile!.fileName}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        FilledButton.tonalIcon(
                          onPressed: backups.isLoading
                              ? null
                              : () => backupNotifier.createBackup(),
                          icon: const Icon(Icons.backup_rounded),
                          label: Text(
                            backups.isLoading
                                ? 'Creating backup...'
                                : 'Create Local Backup',
                          ),
                        ),
                        const SizedBox(height: 10),
                        FilledButton.tonalIcon(
                          onPressed: backups.isLoading
                              ? null
                              : () => backupNotifier.importBackupFromFile(),
                          icon: const Icon(Icons.file_open_rounded),
                          label: const Text('Import Backup File'),
                        ),
                        if (backups.error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            backups.error!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        if (backups.backups.isEmpty)
                          Text(
                            'No local backups yet.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          )
                        else
                          ...backups.backups
                              .take(4)
                              .map(
                                (item) => BackupCard(
                                  backup: item,
                                  onRestore: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Restore backup?'),
                                        content: Text(
                                          'This will replace your current local data with:\n'
                                          '${item.expenseCount} expenses, '
                                          '${item.receivableCount} receivables, '
                                          '${item.payableCount} payables, '
                                          '${item.recurringTemplateCount} recurring templates.\n\n'
                                          'This action cannot be undone (a safety snapshot is created automatically).\n\n'
                                          'Backup: ${item.backupId}',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(
                                              context,
                                            ).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: const Text('Restore'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed != true) return;
                                    await backupNotifier.restoreLocalBackup(
                                      item.backupId,
                                    );
                                  },
                                ),
                              ),
                      ],
                    ),
                    _SettingsSection(
                      title: 'Onboarding & Guidance',
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('First-time setup'),
                          subtitle: const Text(
                            'Replay onboarding and setup guidance screens.',
                          ),
                          trailing: TextButton(
                            onPressed: () async {
                              await ref
                                  .read(onboardingProvider.notifier)
                                  .reset();
                            },
                            child: const Text('Replay'),
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.analytics_rounded),
                          title: const Text('Analytics introduction'),
                          subtitle: const Text(
                            'Use trend, category, and budget insights together.',
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.flag_rounded),
                          title: const Text('Budgeting guidance'),
                          subtitle: const Text(
                            'Set a monthly budget and review health score weekly.',
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.repeat_rounded),
                          title: const Text('Recurring expense tips'),
                          subtitle: const Text(
                            'Create templates for rent, subscriptions, and routine spending.',
                          ),
                        ),
                      ],
                    ),
                    _DebugSection(),
                  ];

                  final bodyContent = useTwoColumns
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(children: [content[0], content[2]]),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                children: [content[1], content[3], content[4]],
                              ),
                            ),
                          ],
                        )
                      : Column(children: content);

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [bodyContent],
                  );
                },
              ),
            ),
    );
  }
}

String _formatCycleDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

/// Debug section for testing Supabase connection
class _DebugSection extends ConsumerWidget {
  const _DebugSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debugState = ref.watch(supabaseDebugProvider);
    final debugNotifier = ref.read(supabaseDebugProvider.notifier);
    final syncState = ref.watch(syncProvider);
    final syncNotifier = ref.read(syncProvider.notifier);

    return _SettingsSection(
      title: 'Debug & Cloud Sync',
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Supabase Connection'),
          subtitle: const Text(
            'Test cloud sync connectivity (temporary debug button)',
          ),
          trailing: FilledButton.tonalIcon(
            onPressed: debugState.isLoading
                ? null
                : () async {
                    try {
                      final message = await debugNotifier.testConnection();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          backgroundColor: Colors.green.shade700,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error.toString()),
                          backgroundColor: Colors.red.shade700,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  },
            icon: debugState.isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )
                : const Icon(Icons.cloud_outlined),
            label: Text(
              debugState.isLoading ? 'Testing...' : 'Test Connection',
            ),
          ),
        ),
        const SizedBox(height: 10),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Manual Sync'),
          subtitle: const Text(
            'Push local changes and pull the latest cloud data.',
          ),
          trailing: FilledButton.tonalIcon(
            onPressed: syncState.isSyncing
                ? null
                : () async {
                    final result = await syncNotifier.syncNow();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result.error ??
                              '${result.status}: ${result.uploadCount} uploaded, ${result.downloadCount} downloaded',
                        ),
                        backgroundColor: result.error == null
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  },
            icon: syncState.isSyncing
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )
                : const Icon(Icons.sync_rounded),
            label: Text(syncState.isSyncing ? 'Syncing...' : 'Sync Now'),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              label: Text(syncState.status),
              avatar: Icon(
                syncState.isSyncing
                    ? Icons.sync_rounded
                    : syncState.error == null
                    ? Icons.cloud_done_rounded
                    : Icons.cloud_off_rounded,
                size: 18,
              ),
            ),
            Chip(
              label: Text(
                'Last sync: ${syncState.lastSyncedAt == null ? 'Never' : syncState.lastSyncedAt!.toLocal().toString()}',
              ),
            ),
            Chip(label: Text('Uploads: ${syncState.uploadCount}')),
            Chip(label: Text('Downloads: ${syncState.downloadCount}')),
            Chip(label: Text('Pending: ${syncState.pendingCount}')),
          ],
        ),
        if (syncState.error != null) ...[
          const SizedBox(height: 8),
          Text(
            syncState.error!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
