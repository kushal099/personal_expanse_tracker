import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/storage/hive_service.dart';
import '../../../services/supabase/supabase_service.dart';
import '../../../providers/storage/storage_providers.dart';
import '../../../providers/auth/auth_provider.dart';

class SettingsState {
  final bool isLoading;
  final String? error;
  final String currency;
  final bool analyticsInsightsEnabled;
  final String defaultExportFormat;
  final bool exportIncludeAnalyticsSummary;
  final bool remindersEnabled;
  final bool budgetWarningReminderEnabled;
  final bool overdueReceivableReminderEnabled;
  final bool recurringDueReminderEnabled;
  final bool monthlyBudgetReminderEnabled;
  final bool recurringQuickGenerateEnabled;
  final DateTime? salaryCycleStartDate;

  const SettingsState({
    this.isLoading = true,
    this.error,
    this.currency = 'INR',
    this.analyticsInsightsEnabled = true,
    this.defaultExportFormat = 'csv',
    this.exportIncludeAnalyticsSummary = true,
    this.remindersEnabled = true,
    this.budgetWarningReminderEnabled = true,
    this.overdueReceivableReminderEnabled = true,
    this.recurringDueReminderEnabled = true,
    this.monthlyBudgetReminderEnabled = true,
    this.recurringQuickGenerateEnabled = true,
    this.salaryCycleStartDate,
  });

  DateTime get currentCycleStartDate {
    final date = salaryCycleStartDate;
    if (date != null) {
      return DateTime(date.year, date.month, date.day);
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  SettingsState copyWith({
    bool? isLoading,
    String? error,
    String? currency,
    bool? analyticsInsightsEnabled,
    String? defaultExportFormat,
    bool? exportIncludeAnalyticsSummary,
    bool? remindersEnabled,
    bool? budgetWarningReminderEnabled,
    bool? overdueReceivableReminderEnabled,
    bool? recurringDueReminderEnabled,
    bool? monthlyBudgetReminderEnabled,
    bool? recurringQuickGenerateEnabled,
    DateTime? salaryCycleStartDate,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currency: currency ?? this.currency,
      analyticsInsightsEnabled:
          analyticsInsightsEnabled ?? this.analyticsInsightsEnabled,
      defaultExportFormat: defaultExportFormat ?? this.defaultExportFormat,
      exportIncludeAnalyticsSummary:
          exportIncludeAnalyticsSummary ?? this.exportIncludeAnalyticsSummary,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      budgetWarningReminderEnabled:
          budgetWarningReminderEnabled ?? this.budgetWarningReminderEnabled,
      overdueReceivableReminderEnabled:
          overdueReceivableReminderEnabled ??
          this.overdueReceivableReminderEnabled,
      recurringDueReminderEnabled:
          recurringDueReminderEnabled ?? this.recurringDueReminderEnabled,
      monthlyBudgetReminderEnabled:
          monthlyBudgetReminderEnabled ?? this.monthlyBudgetReminderEnabled,
      recurringQuickGenerateEnabled:
          recurringQuickGenerateEnabled ?? this.recurringQuickGenerateEnabled,
      salaryCycleStartDate: salaryCycleStartDate ?? this.salaryCycleStartDate,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final HiveService _hiveService;
  final String _userId;

  SettingsNotifier(this._hiveService, this._userId)
    : super(const SettingsState()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true);
    try {
      final raw = _hiveService.getSettings(_userId);
      final rawCycleStart = raw['salaryCycleStartDate'] as String?;
      final parsedCycleStart = rawCycleStart == null
          ? null
          : DateTime.tryParse(rawCycleStart);
      final now = DateTime.now();
      state = SettingsState(
        isLoading: false,
        currency: raw['currency'] as String? ?? 'INR',
        analyticsInsightsEnabled:
            raw['analyticsInsightsEnabled'] as bool? ?? true,
        defaultExportFormat: raw['defaultExportFormat'] as String? ?? 'csv',
        exportIncludeAnalyticsSummary:
            raw['exportIncludeAnalyticsSummary'] as bool? ?? true,
        remindersEnabled: raw['remindersEnabled'] as bool? ?? true,
        budgetWarningReminderEnabled:
            raw['budgetWarningReminderEnabled'] as bool? ?? true,
        overdueReceivableReminderEnabled:
            raw['overdueReceivableReminderEnabled'] as bool? ?? true,
        recurringDueReminderEnabled:
            raw['recurringDueReminderEnabled'] as bool? ?? true,
        monthlyBudgetReminderEnabled:
            raw['monthlyBudgetReminderEnabled'] as bool? ?? true,
        recurringQuickGenerateEnabled:
            raw['recurringQuickGenerateEnabled'] as bool? ?? true,
        salaryCycleStartDate:
            parsedCycleStart ?? DateTime(now.year, now.month, 1),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _persist(SettingsState next) async {
    state = next.copyWith(error: null);
    await _hiveService.saveSettings(_userId, {
      'currency': next.currency,
      'analyticsInsightsEnabled': next.analyticsInsightsEnabled,
      'defaultExportFormat': next.defaultExportFormat,
      'exportIncludeAnalyticsSummary': next.exportIncludeAnalyticsSummary,
      'remindersEnabled': next.remindersEnabled,
      'budgetWarningReminderEnabled': next.budgetWarningReminderEnabled,
      'overdueReceivableReminderEnabled': next.overdueReceivableReminderEnabled,
      'recurringDueReminderEnabled': next.recurringDueReminderEnabled,
      'monthlyBudgetReminderEnabled': next.monthlyBudgetReminderEnabled,
      'recurringQuickGenerateEnabled': next.recurringQuickGenerateEnabled,
      'salaryCycleStartDate': next.currentCycleStartDate.toIso8601String(),
    });
  }

  Future<void> setCurrency(String value) async {
    await _persist(state.copyWith(currency: value));
  }

  Future<void> setAnalyticsInsightsEnabled(bool value) async {
    await _persist(state.copyWith(analyticsInsightsEnabled: value));
  }

  Future<void> setDefaultExportFormat(String value) async {
    await _persist(state.copyWith(defaultExportFormat: value));
  }

  Future<void> setExportIncludeAnalyticsSummary(bool value) async {
    await _persist(state.copyWith(exportIncludeAnalyticsSummary: value));
  }

  Future<void> setRemindersEnabled(bool value) async {
    await _persist(state.copyWith(remindersEnabled: value));
  }

  Future<void> setBudgetWarningReminderEnabled(bool value) async {
    await _persist(state.copyWith(budgetWarningReminderEnabled: value));
  }

  Future<void> setOverdueReceivableReminderEnabled(bool value) async {
    await _persist(state.copyWith(overdueReceivableReminderEnabled: value));
  }

  Future<void> setRecurringDueReminderEnabled(bool value) async {
    await _persist(state.copyWith(recurringDueReminderEnabled: value));
  }

  Future<void> setMonthlyBudgetReminderEnabled(bool value) async {
    await _persist(state.copyWith(monthlyBudgetReminderEnabled: value));
  }

  Future<void> setRecurringQuickGenerateEnabled(bool value) async {
    await _persist(state.copyWith(recurringQuickGenerateEnabled: value));
  }

  Future<void> resetSalaryCycle({DateTime? startDate}) async {
    final date = startDate ?? DateTime.now();
    await _persist(
      state.copyWith(
        salaryCycleStartDate: DateTime(date.year, date.month, date.day),
      ),
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    final hiveService = ref.watch(hiveServiceProvider);
    final userId = ref.watch(currentUserIdProvider) ?? '';
    return SettingsNotifier(hiveService, userId);
  },
);

final currenciesProvider = Provider<List<String>>((ref) {
  return ['INR', 'USD', 'EUR', 'GBP', 'AUD', 'CAD'];
});

final exportFormatsProvider = Provider<List<String>>((ref) {
  return ['csv', 'excel', 'pdf'];
});

/// Debug provider for Supabase connection testing
class SupabaseDebugState {
  final bool isLoading;
  final String? message;
  final bool isError;

  const SupabaseDebugState({
    this.isLoading = false,
    this.message,
    this.isError = false,
  });

  SupabaseDebugState copyWith({
    bool? isLoading,
    String? message,
    bool? isError,
  }) {
    return SupabaseDebugState(
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
      isError: isError ?? this.isError,
    );
  }
}

class SupabaseDebugNotifier extends StateNotifier<SupabaseDebugState> {
  SupabaseDebugNotifier() : super(const SupabaseDebugState());

  Future<String> testConnection() async {
    state = state.copyWith(isLoading: true, message: null, isError: false);
    try {
      final message = await SupabaseService.testConnection();
      state = state.copyWith(
        isLoading: false,
        message: message,
        isError: false,
      );
      return message;
    } catch (e) {
      final message = e.toString();
      state = state.copyWith(isLoading: false, message: message, isError: true);
      throw message;
    }
  }
}

final supabaseDebugProvider =
    StateNotifierProvider<SupabaseDebugNotifier, SupabaseDebugState>(
      (ref) => SupabaseDebugNotifier(),
    );
