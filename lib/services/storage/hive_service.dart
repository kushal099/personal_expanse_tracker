import 'package:hive_flutter/hive_flutter.dart';

import '../../models/expense/expense_hive_model.dart';
import '../../models/expense/expense_model.dart';
import '../../models/payable/payable_model.dart';
import '../../models/recurring/recurring_expense_template.dart';
import '../../models/receivable/receivable_hive_model.dart';
import '../../models/receivable/receivable_model.dart';
import '../../models/sync/sync_models.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();

  late Box<ExpenseHive> _expensesBox;
  late Box<ReceivableHive> _receivablesBox;
  late Box<double> _monthlyBudgetsBox;
  late Box<Map> _recurringTemplatesBox;
  late Box<Map> _payablesBox;
  late Box<Map> _settingsBox;
  late Box<Map> _backupsBox;
  late Box<Map> _syncMetadataBox;
  late Box<Map> _syncStateBox;
  late Box<bool> _onboardingBox;
  bool _initialized = false;
  static const _syncDeviceIdKey = 'syncDeviceId';
  static const _localUserId = 'local_android_user';

  factory HiveService() {
    return _instance;
  }

  HiveService._internal();

  bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ExpenseHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ReceivableHiveAdapter());
    }

    _instance._expensesBox = await Hive.openBox<ExpenseHive>('expenses');
    _instance._receivablesBox = await Hive.openBox<ReceivableHive>(
      'receivables',
    );
    _instance._monthlyBudgetsBox = await Hive.openBox<double>(
      'monthly_budgets',
    );
    _instance._recurringTemplatesBox = await Hive.openBox<Map>(
      'recurring_templates',
    );
    _instance._payablesBox = await Hive.openBox<Map>('payables');
    _instance._settingsBox = await Hive.openBox<Map>('app_settings');
    _instance._backupsBox = await Hive.openBox<Map>('local_backups');
    _instance._syncMetadataBox = await Hive.openBox<Map>('sync_metadata');
    _instance._syncStateBox = await Hive.openBox<Map>('sync_state');
    _instance._onboardingBox = await Hive.openBox<bool>('onboarding');
    _instance._initialized = true;
  }

  String _budgetKey(String userId, DateTime month) {
    final normalizedMonth = DateTime(month.year, month.month);
    return '$userId-${normalizedMonth.year}-${normalizedMonth.month}';
  }

  // Expense methods
  List<Expense> getAllExpenses(String userId) {
    if (!_initialized) return [];
    return _expensesBox.values
        .where((e) => _belongsToUser(e.userId, userId))
        .map(_hiveToExpense)
        .map((expense) => _normalizeLocalExpense(expense, userId))
        .toList();
  }

  List<Expense> getRecentExpenses(String userId, {int limit = 10}) {
    if (!_initialized) return [];
    final expenses = getAllExpenses(userId);
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses.take(limit).toList();
  }

  Future<void> addExpense(Expense expense) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    final hiveExpense = _expenseToHive(expense);
    await _expensesBox.put(expense.id, hiveExpense);
    await _markSyncPending(
      entityType: SyncEntityType.expense,
      entityId: expense.id,
      userId: expense.userId,
      updatedAt: expense.updatedAt ?? expense.createdAt,
      isDeleted: false,
    );
  }

  Future<void> updateExpense(String id, Expense expense) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    final hiveExpense = _expenseToHive(expense);
    await _expensesBox.put(id, hiveExpense);
    await _markSyncPending(
      entityType: SyncEntityType.expense,
      entityId: id,
      userId: expense.userId,
      updatedAt: expense.updatedAt ?? DateTime.now(),
      isDeleted: false,
    );
  }

  Future<void> deleteExpense(String id) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    final existing = _expensesBox.get(id);
    await _expensesBox.delete(id);
    if (existing != null) {
      await _markSyncPending(
        entityType: SyncEntityType.expense,
        entityId: id,
        userId: existing.userId,
        updatedAt: existing.updatedAt ?? existing.createdAt,
        isDeleted: true,
      );
    }
  }

  // Receivable methods
  List<Receivable> getAllReceivables(String userId) {
    if (!_initialized) return [];
    return _receivablesBox.values
        .where((r) => _belongsToUser(r.userId, userId))
        .map(_hiveToReceivable)
        .map((receivable) => _normalizeLocalReceivable(receivable, userId))
        .toList();
  }

  List<Receivable> getRecentReceivables(String userId, {int limit = 10}) {
    if (!_initialized) return [];
    final receivables = getAllReceivables(userId);
    receivables.sort((a, b) => b.dueDate.compareTo(a.dueDate));
    return receivables.take(limit).toList();
  }

  Future<void> addReceivable(Receivable receivable) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    final hiveReceivable = _receivableToHive(receivable);
    await _receivablesBox.put(receivable.id, hiveReceivable);
    await _markSyncPending(
      entityType: SyncEntityType.receivable,
      entityId: receivable.id,
      userId: receivable.userId,
      updatedAt: receivable.updatedAt ?? receivable.createdAt,
      isDeleted: false,
    );
  }

  Future<void> updateReceivable(String id, Receivable receivable) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    final hiveReceivable = _receivableToHive(receivable);
    await _receivablesBox.put(id, hiveReceivable);
    await _markSyncPending(
      entityType: SyncEntityType.receivable,
      entityId: id,
      userId: receivable.userId,
      updatedAt: receivable.updatedAt ?? DateTime.now(),
      isDeleted: false,
    );
  }

  Future<void> deleteReceivable(String id) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    final existing = _receivablesBox.get(id);
    await _receivablesBox.delete(id);
    if (existing != null) {
      await _markSyncPending(
        entityType: SyncEntityType.receivable,
        entityId: id,
        userId: existing.userId,
        updatedAt: existing.updatedAt ?? existing.createdAt,
        isDeleted: true,
      );
    }
  }

  // Payable methods
  List<Payable> getAllPayables(String userId) {
    if (!_initialized) return [];
    return _payablesBox.values
        .where(
          (entry) => _belongsToUser(entry['userId'] as String? ?? '', userId),
        )
        .map(Payable.fromJson)
        .map((payable) => _normalizeLocalPayable(payable, userId))
        .toList();
  }

  List<Payable> getRecentPayables(String userId, {int limit = 10}) {
    if (!_initialized) return [];
    final payables = getAllPayables(userId);
    payables.sort((a, b) => b.dueDate.compareTo(a.dueDate));
    return payables.take(limit).toList();
  }

  Future<void> addPayable(Payable payable) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    await _payablesBox.put(payable.id, payable.toJson());
    await _markSyncPending(
      entityType: SyncEntityType.payable,
      entityId: payable.id,
      userId: payable.userId,
      updatedAt: payable.updatedAt ?? payable.createdAt,
      isDeleted: false,
    );
  }

  Future<void> updatePayable(String id, Payable payable) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    await _payablesBox.put(id, payable.toJson());
    await _markSyncPending(
      entityType: SyncEntityType.payable,
      entityId: id,
      userId: payable.userId,
      updatedAt: payable.updatedAt ?? DateTime.now(),
      isDeleted: false,
    );
  }

  Future<void> deletePayable(String id) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    final existing = _payablesBox.get(id);
    await _payablesBox.delete(id);
    if (existing != null) {
      final existingPayable = Payable.fromJson(existing);
      await _markSyncPending(
        entityType: SyncEntityType.payable,
        entityId: id,
        userId: existingPayable.userId,
        updatedAt: existingPayable.updatedAt ?? existingPayable.createdAt,
        isDeleted: true,
      );
    }
  }

  // Monthly budget methods
  double getMonthlyBudget(String userId, DateTime month) {
    if (!_initialized) return 0.0;
    return _monthlyBudgetsBox.get(_budgetKey(userId, month)) ?? 0.0;
  }

  Future<void> setMonthlyBudget(
    String userId,
    DateTime month,
    double amount,
  ) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    await _monthlyBudgetsBox.put(_budgetKey(userId, month), amount);
  }

  Future<void> resetMonthlyBudget(String userId, DateTime month) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    await _monthlyBudgetsBox.delete(_budgetKey(userId, month));
  }

  // Recurring expense templates
  List<RecurringExpenseTemplate> getRecurringTemplates(String userId) {
    if (!_initialized) return [];

    return _recurringTemplatesBox.values
        .where(
          (template) =>
              _belongsToUser(template['userId'] as String? ?? '', userId),
        )
        .map(RecurringExpenseTemplate.fromJson)
        .map((template) => _normalizeLocalTemplate(template, userId))
        .toList();
  }

  Future<void> addRecurringTemplate(RecurringExpenseTemplate template) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    await _recurringTemplatesBox.put(template.id, template.toJson());
    await _markSyncPending(
      entityType: SyncEntityType.recurringTemplate,
      entityId: template.id,
      userId: template.userId,
      updatedAt: template.updatedAt ?? template.createdAt,
      isDeleted: false,
    );
  }

  Future<void> updateRecurringTemplate(
    String id,
    RecurringExpenseTemplate template,
  ) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    await _recurringTemplatesBox.put(id, template.toJson());
    await _markSyncPending(
      entityType: SyncEntityType.recurringTemplate,
      entityId: id,
      userId: template.userId,
      updatedAt: template.updatedAt ?? DateTime.now(),
      isDeleted: false,
    );
  }

  Future<void> deleteRecurringTemplate(String id) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    final existing = _recurringTemplatesBox.get(id);
    await _recurringTemplatesBox.delete(id);
    if (existing != null) {
      final template = RecurringExpenseTemplate.fromJson(
        Map<dynamic, dynamic>.from(existing),
      );
      await _markSyncPending(
        entityType: SyncEntityType.recurringTemplate,
        entityId: id,
        userId: template.userId,
        updatedAt: template.updatedAt ?? template.createdAt,
        isDeleted: true,
      );
    }
  }

  Future<void> applyExpenseFromSync(Expense expense) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    await _expensesBox.put(expense.id, _expenseToHive(expense));
    await saveSyncMetadata(
      SyncMetadata(
        entityId: expense.id,
        entityType: SyncEntityType.expense,
        userId: expense.userId,
        updatedAt: expense.updatedAt ?? expense.createdAt,
        syncedAt: DateTime.now(),
        isDeleted: false,
        deviceId: getDeviceId(),
      ),
    );
  }

  Future<void> applyExpenseDeletionFromSync({
    required String id,
    required String userId,
    required DateTime updatedAt,
  }) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    await _expensesBox.delete(id);
    await saveSyncMetadata(
      SyncMetadata(
        entityId: id,
        entityType: SyncEntityType.expense,
        userId: userId,
        updatedAt: updatedAt,
        syncedAt: DateTime.now(),
        isDeleted: true,
        deviceId: getDeviceId(),
      ),
    );
  }

  Future<void> applyReceivableFromSync(Receivable receivable) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    await _receivablesBox.put(receivable.id, _receivableToHive(receivable));
    await saveSyncMetadata(
      SyncMetadata(
        entityId: receivable.id,
        entityType: SyncEntityType.receivable,
        userId: receivable.userId,
        updatedAt: receivable.updatedAt ?? receivable.createdAt,
        syncedAt: DateTime.now(),
        isDeleted: false,
        deviceId: getDeviceId(),
      ),
    );
  }

  Future<void> applyReceivableDeletionFromSync({
    required String id,
    required String userId,
    required DateTime updatedAt,
  }) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    await _receivablesBox.delete(id);
    await saveSyncMetadata(
      SyncMetadata(
        entityId: id,
        entityType: SyncEntityType.receivable,
        userId: userId,
        updatedAt: updatedAt,
        syncedAt: DateTime.now(),
        isDeleted: true,
        deviceId: getDeviceId(),
      ),
    );
  }

  Future<void> applyPayableFromSync(Payable payable) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    await _payablesBox.put(payable.id, payable.toJson());
    await saveSyncMetadata(
      SyncMetadata(
        entityId: payable.id,
        entityType: SyncEntityType.payable,
        userId: payable.userId,
        updatedAt: payable.updatedAt ?? payable.createdAt,
        syncedAt: DateTime.now(),
        isDeleted: false,
        deviceId: getDeviceId(),
      ),
    );
  }

  Future<void> applyPayableDeletionFromSync({
    required String id,
    required String userId,
    required DateTime updatedAt,
  }) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    await _payablesBox.delete(id);
    await saveSyncMetadata(
      SyncMetadata(
        entityId: id,
        entityType: SyncEntityType.payable,
        userId: userId,
        updatedAt: updatedAt,
        syncedAt: DateTime.now(),
        isDeleted: true,
        deviceId: getDeviceId(),
      ),
    );
  }

  Future<void> applyRecurringTemplateFromSync(
    RecurringExpenseTemplate template,
  ) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    await _recurringTemplatesBox.put(template.id, template.toJson());
    await saveSyncMetadata(
      SyncMetadata(
        entityId: template.id,
        entityType: SyncEntityType.recurringTemplate,
        userId: template.userId,
        updatedAt: template.updatedAt ?? template.createdAt,
        syncedAt: DateTime.now(),
        isDeleted: false,
        deviceId: getDeviceId(),
      ),
    );
  }

  Future<void> applyRecurringTemplateDeletionFromSync({
    required String id,
    required String userId,
    required DateTime updatedAt,
  }) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    await _recurringTemplatesBox.delete(id);
    await saveSyncMetadata(
      SyncMetadata(
        entityId: id,
        entityType: SyncEntityType.recurringTemplate,
        userId: userId,
        updatedAt: updatedAt,
        syncedAt: DateTime.now(),
        isDeleted: true,
        deviceId: getDeviceId(),
      ),
    );
  }

  // Settings
  Map<String, dynamic> getSettings(String userId) {
    if (!_initialized) return <String, dynamic>{};
    final data = _settingsBox.get(userId);
    if (data == null) return <String, dynamic>{};
    return Map<String, dynamic>.from(data);
  }

  Future<void> saveSettings(String userId, Map<String, dynamic> values) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    await _settingsBox.put(userId, values);
  }

  String getDeviceId() {
    if (!_initialized) return 'uninitialized-device';
    final existing = _settingsBox.get(_syncDeviceIdKey);
    if (existing != null) {
      final deviceId = existing['value'] as String?;
      if (deviceId != null && deviceId.isNotEmpty) {
        return deviceId;
      }
    }
    final deviceId = 'device_${DateTime.now().microsecondsSinceEpoch}';
    _settingsBox.put(_syncDeviceIdKey, {'value': deviceId});
    return deviceId;
  }

  List<Map<String, dynamic>> getExportHistory(String userId) {
    final settings = getSettings(userId);
    final raw = settings['exportHistory'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> addExportHistoryEntry(
    String userId,
    Map<String, dynamic> entry,
  ) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    final settings = getSettings(userId);
    final existing = getExportHistory(userId);
    final next = [entry, ...existing].take(12).toList();
    settings['exportHistory'] = next;
    await saveSettings(userId, settings);
  }

  List<SyncMetadata> getSyncMetadataForUser(String userId) {
    if (!_initialized) return [];
    return _syncMetadataBox.values
        .where((entry) => entry['userId'] == userId)
        .map(SyncMetadata.fromJson)
        .toList();
  }

  Future<void> saveSyncMetadata(SyncMetadata metadata) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    final key = _syncKey(
      metadata.userId,
      metadata.entityType,
      metadata.entityId,
    );
    await _syncMetadataBox.put(key, metadata.toJson());
  }

  Future<void> deleteSyncMetadata({
    required String userId,
    required SyncEntityType entityType,
    required String entityId,
  }) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    await _syncMetadataBox.delete(_syncKey(userId, entityType, entityId));
  }

  Future<void> markSyncCompleted({
    required SyncMetadata metadata,
    required DateTime syncedAt,
  }) async {
    await saveSyncMetadata(metadata.copyWith(syncedAt: syncedAt));
  }

  SyncState getSyncState(String userId) {
    if (!_initialized) return const SyncState();
    final raw = _syncStateBox.get(userId);
    if (raw == null) return const SyncState();
    return SyncState.fromJson(raw);
  }

  Future<void> saveSyncState(String userId, SyncState state) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    await _syncStateBox.put(userId, state.toJson());
  }

  // Onboarding
  bool isOnboardingCompleted() {
    if (!_initialized) return false;
    return _onboardingBox.get('completed') ?? false;
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    await _onboardingBox.put('completed', completed);
  }

  // Backup foundation
  Map<String, dynamic> createLocalBackupSnapshot(String userId) {
    final now = DateTime.now();
    final expenses = getAllExpenses(userId).map(_expenseToMap).toList();
    final receivables = getAllReceivables(
      userId,
    ).map(_receivableToMap).toList();
    final payables = getAllPayables(userId).map(_payableToMap).toList();
    final recurring = getRecurringTemplates(
      userId,
    ).map((template) => template.toJson()).toList();
    final settings = getSettings(userId);
    final monthBudget = getMonthlyBudget(userId, now);

    return {
      'backupId': 'backup_${now.millisecondsSinceEpoch}',
      'createdAt': now.toIso8601String(),
      'userId': userId,
      'monthlyBudget': monthBudget,
      'settings': settings,
      'expenses': expenses,
      'receivables': receivables,
      'payables': payables,
      'recurringTemplates': recurring,
    };
  }

  Future<void> saveLocalBackup(Map<String, dynamic> snapshot) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    final backupId = snapshot['backupId'] as String;
    await _backupsBox.put(backupId, snapshot);
  }

  List<Map<String, dynamic>> getLocalBackups() {
    if (!_initialized) return [];
    return _backupsBox.values
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList()
      ..sort(
        (a, b) =>
            (b['createdAt'] as String).compareTo(a['createdAt'] as String),
      );
  }

  Map<String, dynamic>? getLocalBackupById(String backupId) {
    if (!_initialized) return null;
    final raw = _backupsBox.get(backupId);
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw);
  }

  Future<void> restoreFromBackup(Map<String, dynamic> snapshot) async {
    if (!_initialized) throw Exception('HiveService not initialized');
    final userId = snapshot['userId'] as String?;
    if (userId == null || userId.isEmpty) {
      throw Exception('Invalid backup payload');
    }

    final currentSafetySnapshot = createLocalBackupSnapshot(userId);
    try {
      await _restoreFromBackupUnsafe(snapshot, userId: userId);
    } catch (e) {
      // Best-effort rollback to reduce corruption risk.
      try {
        await _restoreFromBackupUnsafe(currentSafetySnapshot, userId: userId);
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> _restoreFromBackupUnsafe(
    Map<String, dynamic> snapshot, {
    required String userId,
  }) async {
    final expensesRaw = snapshot['expenses'];
    final receivablesRaw = snapshot['receivables'];
    final recurringRaw = snapshot['recurringTemplates'];
    final payablesRaw = snapshot['payables'];
    if (expensesRaw is! List ||
        receivablesRaw is! List ||
        recurringRaw is! List) {
      throw Exception('Invalid backup payload: missing lists');
    }

    final expenses = expensesRaw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .map(_expenseFromMap)
        .toList();
    final receivables = receivablesRaw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .map(_receivableFromMap)
        .toList();
    final recurringTemplates = recurringRaw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .map((m) => RecurringExpenseTemplate.fromJson(m))
        .toList();
    final payablesList = payablesRaw is List ? payablesRaw : <dynamic>[];
    final payables = payablesList
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .map((m) => Payable.fromJson(m))
        .toList();

    final settingsRaw = snapshot['settings'];
    final settings = settingsRaw is Map
        ? Map<String, dynamic>.from(settingsRaw)
        : <String, dynamic>{};

    final monthlyBudget = snapshot['monthlyBudget'];
    final monthlyBudgetValue = monthlyBudget is num
        ? monthlyBudget.toDouble()
        : 0.0;

    // Clear existing data before restore (single-user app today).
    await _expensesBox.clear();
    await _receivablesBox.clear();
    await _recurringTemplatesBox.clear();
    await _payablesBox.clear();
    await _settingsBox.delete(userId);
    await _monthlyBudgetsBox.clear();

    for (final expense in expenses) {
      await _expensesBox.put(expense.id, _expenseToHive(expense));
    }
    for (final receivable in receivables) {
      await _receivablesBox.put(receivable.id, _receivableToHive(receivable));
    }
    for (final template in recurringTemplates) {
      await _recurringTemplatesBox.put(template.id, template.toJson());
    }
    for (final payable in payables) {
      await _payablesBox.put(payable.id, payable.toJson());
    }
    if (settings.isNotEmpty) {
      await _settingsBox.put(userId, settings);
    }
    if (monthlyBudgetValue > 0) {
      await setMonthlyBudget(userId, DateTime.now(), monthlyBudgetValue);
    }
  }

  Expense _expenseFromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      userId: map['userId'] as String? ?? '',
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String? ?? 'Other',
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
      recurringTemplateId: map['recurringTemplateId'] as String?,
      recurringDueDate: map['recurringDueDate'] == null
          ? null
          : DateTime.tryParse(map['recurringDueDate'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] == null
          ? null
          : DateTime.tryParse(map['updatedAt'] as String),
    );
  }

  Receivable _receivableFromMap(Map<String, dynamic> map) {
    return Receivable(
      id: map['id'] as String,
      userId: map['userId'] as String? ?? '',
      fromPerson: map['fromPerson'] as String? ?? 'Unknown',
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String?,
      dueDate: DateTime.parse(map['dueDate'] as String),
      isPaid: map['isPaid'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] == null
          ? null
          : DateTime.tryParse(map['updatedAt'] as String),
    );
  }

  // Conversion methods
  Expense _hiveToExpense(ExpenseHive hive) {
    return Expense(
      id: hive.id,
      userId: hive.userId,
      amount: hive.amount,
      category: hive.category,
      description: hive.description,
      date: hive.date,
      recurringTemplateId: hive.recurringTemplateId,
      recurringDueDate: hive.recurringDueDate,
      createdAt: hive.createdAt,
      updatedAt: hive.updatedAt,
    );
  }

  ExpenseHive _expenseToHive(Expense expense) {
    return ExpenseHive(
      id: expense.id,
      userId: expense.userId,
      amount: expense.amount,
      category: expense.category,
      description: expense.description,
      date: expense.date,
      recurringTemplateId: expense.recurringTemplateId,
      recurringDueDate: expense.recurringDueDate,
      createdAt: expense.createdAt,
      updatedAt: expense.updatedAt,
    );
  }

  Map<String, dynamic> _payableToMap(Payable payable) {
    return payable.toJson();
  }

  String _syncKey(String userId, SyncEntityType entityType, String entityId) {
    return '$userId::${entityType.name}::$entityId';
  }

  Future<void> _markSyncPending({
    required SyncEntityType entityType,
    required String entityId,
    required String userId,
    required DateTime updatedAt,
    required bool isDeleted,
  }) async {
    if (!_initialized) return;
    final metadata = SyncMetadata(
      entityId: entityId,
      entityType: entityType,
      userId: userId,
      updatedAt: updatedAt,
      syncedAt: null,
      isDeleted: isDeleted,
      deviceId: getDeviceId(),
    );
    await saveSyncMetadata(metadata);
  }

  Receivable _hiveToReceivable(ReceivableHive hive) {
    return Receivable(
      id: hive.id,
      userId: hive.userId,
      fromPerson: hive.fromPerson,
      amount: hive.amount,
      description: hive.description,
      dueDate: hive.dueDate,
      isPaid: hive.isPaid,
      createdAt: hive.createdAt,
      updatedAt: hive.updatedAt,
    );
  }

  ReceivableHive _receivableToHive(Receivable receivable) {
    return ReceivableHive(
      id: receivable.id,
      userId: receivable.userId,
      fromPerson: receivable.fromPerson,
      amount: receivable.amount,
      description: receivable.description,
      dueDate: receivable.dueDate,
      isPaid: receivable.isPaid,
      createdAt: receivable.createdAt,
      updatedAt: receivable.updatedAt,
    );
  }

  Map<String, dynamic> _expenseToMap(Expense expense) {
    return {
      'id': expense.id,
      'userId': expense.userId,
      'amount': expense.amount,
      'category': expense.category,
      'description': expense.description,
      'date': expense.date.toIso8601String(),
      'recurringTemplateId': expense.recurringTemplateId,
      'recurringDueDate': expense.recurringDueDate?.toIso8601String(),
      'createdAt': expense.createdAt.toIso8601String(),
      'updatedAt': expense.updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> _receivableToMap(Receivable receivable) {
    return {
      'id': receivable.id,
      'userId': receivable.userId,
      'fromPerson': receivable.fromPerson,
      'amount': receivable.amount,
      'description': receivable.description,
      'dueDate': receivable.dueDate.toIso8601String(),
      'isPaid': receivable.isPaid,
      'createdAt': receivable.createdAt.toIso8601String(),
      'updatedAt': receivable.updatedAt?.toIso8601String(),
    };
  }

  bool _belongsToUser(String recordUserId, String userId) {
    return recordUserId == userId ||
        (userId == _localUserId && recordUserId.isEmpty);
  }

  Expense _normalizeLocalExpense(Expense expense, String userId) {
    if (userId == _localUserId && expense.userId.isEmpty) {
      return expense.copyWith(userId: userId);
    }
    return expense;
  }

  Receivable _normalizeLocalReceivable(Receivable receivable, String userId) {
    if (userId == _localUserId && receivable.userId.isEmpty) {
      return receivable.copyWith(userId: userId);
    }
    return receivable;
  }

  Payable _normalizeLocalPayable(Payable payable, String userId) {
    if (userId == _localUserId && payable.userId.isEmpty) {
      return payable.copyWith(userId: userId);
    }
    return payable;
  }

  RecurringExpenseTemplate _normalizeLocalTemplate(
    RecurringExpenseTemplate template,
    String userId,
  ) {
    if (userId == _localUserId && template.userId.isEmpty) {
      return template.copyWith(userId: userId);
    }
    return template;
  }
}
