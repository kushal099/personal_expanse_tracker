import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/expense/expense_model.dart';
import '../../models/payable/payable_model.dart';
import '../../models/recurring/recurring_expense_template.dart';
import '../../models/receivable/receivable_model.dart';
import '../../models/sync/sync_models.dart';
import '../storage/hive_service.dart';
import '../supabase/supabase_service.dart';

class SupabaseSyncService {
  static const String _expenseTable = 'expenses';
  static const String _receivableTable = 'receivables';
  static const String _payableTable = 'payables';
  static const String _recurringTable = 'recurring_templates';

  final HiveService _hiveService;
  final SupabaseClient _client;

  SupabaseSyncService({HiveService? hiveService, SupabaseClient? client})
    : _hiveService = hiveService ?? HiveService(),
      _client = client ?? SupabaseService.client;

  Future<SyncResult> syncUser(String userId) async {
    final startedAt = DateTime.now();
    final initialState = _hiveService.getSyncState(userId);
    final pendingCount = _countPending(userId);
    await _hiveService.saveSyncState(
      userId,
      initialState.copyWith(
        isSyncing: true,
        lastAttemptAt: startedAt,
        pendingCount: pendingCount,
        status: 'Syncing...',
        error: null,
      ),
    );

    var uploadCount = 0;
    var downloadCount = 0;

    try {
      final expenseRemote = await _fetchRemoteRows(_expenseTable, userId);
      final receivableRemote = await _fetchRemoteRows(_receivableTable, userId);
      final payableRemote = await _fetchRemoteRows(_payableTable, userId);
      final recurringRemote = await _fetchRemoteRows(_recurringTable, userId);

      final expenseResult = await _syncExpenses(userId, expenseRemote);
      final receivableResult = await _syncReceivables(userId, receivableRemote);
      final payableResult = await _syncPayables(userId, payableRemote);
      final recurringResult = await _syncRecurring(userId, recurringRemote);

      uploadCount +=
          expenseResult.uploads +
          receivableResult.uploads +
          payableResult.uploads +
          recurringResult.uploads;
      downloadCount +=
          expenseResult.downloads +
          receivableResult.downloads +
          payableResult.downloads +
          recurringResult.downloads;

      final completedAt = DateTime.now();
      final nextState = SyncState(
        isSyncing: false,
        lastSyncedAt: completedAt,
        lastAttemptAt: startedAt,
        uploadCount: uploadCount,
        downloadCount: downloadCount,
        pendingCount: _countPending(userId),
        status: 'Synced',
      );
      await _hiveService.saveSyncState(userId, nextState);

      return SyncResult(
        uploadCount: uploadCount,
        downloadCount: downloadCount,
        completedAt: completedAt,
        status: 'Synced',
      );
    } catch (e) {
      final errorState = initialState.copyWith(
        isSyncing: false,
        lastAttemptAt: startedAt,
        pendingCount: _countPending(userId),
        status: 'Sync failed',
        error: e.toString(),
      );
      await _hiveService.saveSyncState(userId, errorState);
      return SyncResult(
        uploadCount: uploadCount,
        downloadCount: downloadCount,
        completedAt: DateTime.now(),
        status: 'Sync failed',
        error: e.toString(),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRemoteRows(
    String table,
    String userId,
  ) async {
    final rows = await _client.from(table).select().eq('user_id', userId);
    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<_SyncCounts> _syncExpenses(
    String userId,
    List<Map<String, dynamic>> remoteRows,
  ) async {
    final local = {
      for (final item in _hiveService.getAllExpenses(userId)) item.id: item,
    };
    final tombstones = _hiveService
        .getSyncMetadataForUser(userId)
        .where(
          (entry) =>
              entry.entityType == SyncEntityType.expense && entry.isDeleted,
        )
        .toList();
    return _syncCollection<Expense>(
      table: _expenseTable,
      userId: userId,
      localRecords: local,
      remoteRows: _indexRemoteRows(remoteRows),
      tombstones: tombstones,
      buildRow: _expenseToCloudRow,
      parseRemote: _expenseFromCloudRow,
      idOf: (value) => value.id,
      userIdOf: (value) => value.userId,
      updatedAtOf: (value) => value.updatedAt ?? value.createdAt,
      applyRemoteUpsert: _hiveService.applyExpenseFromSync,
      applyRemoteDelete: (id, userId, updatedAt) =>
          _hiveService.applyExpenseDeletionFromSync(
            id: id,
            userId: userId,
            updatedAt: updatedAt,
          ),
    );
  }

  Future<_SyncCounts> _syncReceivables(
    String userId,
    List<Map<String, dynamic>> remoteRows,
  ) async {
    final local = {
      for (final item in _hiveService.getAllReceivables(userId)) item.id: item,
    };
    final tombstones = _hiveService
        .getSyncMetadataForUser(userId)
        .where(
          (entry) =>
              entry.entityType == SyncEntityType.receivable && entry.isDeleted,
        )
        .toList();
    return _syncCollection<Receivable>(
      table: _receivableTable,
      userId: userId,
      localRecords: local,
      remoteRows: _indexRemoteRows(remoteRows),
      tombstones: tombstones,
      buildRow: _receivableToCloudRow,
      parseRemote: _receivableFromCloudRow,
      idOf: (value) => value.id,
      userIdOf: (value) => value.userId,
      updatedAtOf: (value) => value.updatedAt ?? value.createdAt,
      applyRemoteUpsert: _hiveService.applyReceivableFromSync,
      applyRemoteDelete: (id, userId, updatedAt) =>
          _hiveService.applyReceivableDeletionFromSync(
            id: id,
            userId: userId,
            updatedAt: updatedAt,
          ),
    );
  }

  Future<_SyncCounts> _syncPayables(
    String userId,
    List<Map<String, dynamic>> remoteRows,
  ) async {
    final local = {
      for (final item in _hiveService.getAllPayables(userId)) item.id: item,
    };
    final tombstones = _hiveService
        .getSyncMetadataForUser(userId)
        .where(
          (entry) =>
              entry.entityType == SyncEntityType.payable && entry.isDeleted,
        )
        .toList();
    final indexedRemoteRows = _indexRemoteRows(remoteRows);
    var uploads = 0;
    var downloads = 0;

    for (final localPayable in local.values) {
      final id = localPayable.id;
      final remote = indexedRemoteRows[id];
      final localUpdatedAt = localPayable.updatedAt ?? localPayable.createdAt;
      final remoteUpdatedAt = _rowUpdatedAt(remote);

      if (remote == null) {
        await _uploadRow(
          table: _payableTable,
          row: _payableToCloudRow(localPayable),
          userId: localPayable.userId,
          entityId: id,
          updatedAt: localUpdatedAt,
          isDeleted: false,
        );
        uploads += 1;
        continue;
      }

      if (_rowIsDeleted(remote)) {
        if (localUpdatedAt.isAfter(remoteUpdatedAt)) {
          await _uploadRow(
            table: _payableTable,
            row: _payableToCloudRow(localPayable),
            userId: localPayable.userId,
            entityId: id,
            updatedAt: localUpdatedAt,
            isDeleted: false,
          );
          uploads += 1;
        } else if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
          await _hiveService.applyPayableDeletionFromSync(
            id: id,
            userId: localPayable.userId,
            updatedAt: remoteUpdatedAt,
          );
          downloads += 1;
        }
        continue;
      }

      final remotePayable = _payableFromCloudRow(remote);
      if (_payableSettlementsDiffer(localPayable, remotePayable)) {
        final merged = _mergePayables(localPayable, remotePayable);
        final mergedUpdatedAt =
            merged.updatedAt ??
            (localUpdatedAt.isAfter(remoteUpdatedAt)
                ? localUpdatedAt
                : remoteUpdatedAt);

        await _uploadRow(
          table: _payableTable,
          row: _payableToCloudRow(merged),
          userId: merged.userId,
          entityId: id,
          updatedAt: mergedUpdatedAt,
          isDeleted: false,
        );
        await _hiveService.applyPayableFromSync(merged);
        uploads += 1;
        downloads += 1;
        continue;
      }

      if (localUpdatedAt.isAfter(remoteUpdatedAt)) {
        await _uploadRow(
          table: _payableTable,
          row: _payableToCloudRow(localPayable),
          userId: localPayable.userId,
          entityId: id,
          updatedAt: localUpdatedAt,
          isDeleted: false,
        );
        uploads += 1;
        continue;
      }

      if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
        await _hiveService.applyPayableFromSync(remotePayable);
        downloads += 1;
        continue;
      }

      await _hiveService.saveSyncMetadata(
        SyncMetadata(
          entityId: id,
          entityType: SyncEntityType.payable,
          userId: localPayable.userId,
          updatedAt: localUpdatedAt,
          syncedAt: DateTime.now(),
          isDeleted: false,
          deviceId: _hiveService.getDeviceId(),
        ),
      );
    }

    for (final tombstone in tombstones) {
      final remote = indexedRemoteRows[tombstone.entityId];
      final remoteUpdatedAt = _rowUpdatedAt(remote);
      if (remote == null || tombstone.updatedAt.isAfter(remoteUpdatedAt)) {
        await _uploadRow(
          table: _payableTable,
          row: {
            'id': tombstone.entityId,
            'user_id': tombstone.userId,
            'updated_at': tombstone.updatedAt.toIso8601String(),
            'synced_at': DateTime.now().toIso8601String(),
            'is_deleted': true,
            'device_id': tombstone.deviceId,
          },
          userId: tombstone.userId,
          entityId: tombstone.entityId,
          updatedAt: tombstone.updatedAt,
          isDeleted: true,
        );
        uploads += 1;
        continue;
      }

      if (remoteUpdatedAt.isAfter(tombstone.updatedAt)) {
        if (_rowIsDeleted(remote)) {
          await _hiveService.saveSyncMetadata(
            tombstone.copyWith(
              updatedAt: remoteUpdatedAt,
              syncedAt: DateTime.now(),
            ),
          );
        } else {
          await _hiveService.applyPayableFromSync(_payableFromCloudRow(remote));
        }
        downloads += 1;
      } else {
        await _hiveService.saveSyncMetadata(
          tombstone.copyWith(syncedAt: DateTime.now()),
        );
      }
    }

    return _SyncCounts(uploads: uploads, downloads: downloads);
  }

  Future<_SyncCounts> _syncRecurring(
    String userId,
    List<Map<String, dynamic>> remoteRows,
  ) async {
    final local = {
      for (final item in _hiveService.getRecurringTemplates(userId))
        item.id: item,
    };
    final tombstones = _hiveService
        .getSyncMetadataForUser(userId)
        .where(
          (entry) =>
              entry.entityType == SyncEntityType.recurringTemplate &&
              entry.isDeleted,
        )
        .toList();
    return _syncCollection<RecurringExpenseTemplate>(
      table: _recurringTable,
      userId: userId,
      localRecords: local,
      remoteRows: _indexRemoteRows(remoteRows),
      tombstones: tombstones,
      buildRow: _recurringToCloudRow,
      parseRemote: _recurringFromCloudRow,
      idOf: (value) => value.id,
      userIdOf: (value) => value.userId,
      updatedAtOf: (value) => value.updatedAt ?? value.createdAt,
      applyRemoteUpsert: _hiveService.applyRecurringTemplateFromSync,
      applyRemoteDelete: (id, userId, updatedAt) =>
          _hiveService.applyRecurringTemplateDeletionFromSync(
            id: id,
            userId: userId,
            updatedAt: updatedAt,
          ),
    );
  }

  Future<_SyncCounts> _syncCollection<T>({
    required String table,
    required String userId,
    required Map<String, T> localRecords,
    required Map<String, Map<String, dynamic>> remoteRows,
    required List<SyncMetadata> tombstones,
    required Map<String, dynamic> Function(T value) buildRow,
    required T Function(Map<String, dynamic> row) parseRemote,
    required String Function(T value) idOf,
    required String Function(T value) userIdOf,
    required DateTime Function(T value) updatedAtOf,
    required Future<void> Function(T value) applyRemoteUpsert,
    required Future<void> Function(String id, String userId, DateTime updatedAt)
    applyRemoteDelete,
  }) async {
    var uploads = 0;
    var downloads = 0;

    for (final local in localRecords.values) {
      final id = idOf(local);
      final remote = remoteRows[id];
      final localUpdatedAt = updatedAtOf(local);
      final remoteUpdatedAt = _rowUpdatedAt(remote);

      if (remote == null || localUpdatedAt.isAfter(remoteUpdatedAt)) {
        await _uploadRow(
          table: table,
          row: buildRow(local),
          userId: userIdOf(local),
          entityId: id,
          updatedAt: localUpdatedAt,
          isDeleted: false,
        );
        uploads += 1;
        continue;
      }

      if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
        if (_rowIsDeleted(remote)) {
          await applyRemoteDelete(id, userIdOf(local), remoteUpdatedAt);
        } else {
          await applyRemoteUpsert(parseRemote(remote));
        }
        downloads += 1;
        continue;
      }

      await _hiveService.saveSyncMetadata(
        SyncMetadata(
          entityId: id,
          entityType: _entityTypeForTable(table),
          userId: userIdOf(local),
          updatedAt: localUpdatedAt,
          syncedAt: DateTime.now(),
          isDeleted: false,
          deviceId: _hiveService.getDeviceId(),
        ),
      );
    }

    for (final tombstone in tombstones) {
      final remote = remoteRows[tombstone.entityId];
      final remoteUpdatedAt = _rowUpdatedAt(remote);
      if (remote == null || tombstone.updatedAt.isAfter(remoteUpdatedAt)) {
        await _uploadRow(
          table: table,
          row: {
            'id': tombstone.entityId,
            'user_id': tombstone.userId,
            'updated_at': tombstone.updatedAt.toIso8601String(),
            'synced_at': DateTime.now().toIso8601String(),
            'is_deleted': true,
            'device_id': tombstone.deviceId,
          },
          userId: tombstone.userId,
          entityId: tombstone.entityId,
          updatedAt: tombstone.updatedAt,
          isDeleted: true,
        );
        uploads += 1;
        continue;
      }

      if (remoteUpdatedAt.isAfter(tombstone.updatedAt)) {
        if (_rowIsDeleted(remote)) {
          await _hiveService.saveSyncMetadata(
            tombstone.copyWith(
              updatedAt: remoteUpdatedAt,
              syncedAt: DateTime.now(),
            ),
          );
        } else {
          await applyRemoteUpsert(parseRemote(remote));
        }
        downloads += 1;
      } else {
        await _hiveService.saveSyncMetadata(
          tombstone.copyWith(syncedAt: DateTime.now()),
        );
      }
    }

    return _SyncCounts(uploads: uploads, downloads: downloads);
  }

  Future<void> _uploadRow({
    required String table,
    required Map<String, dynamic> row,
    required String userId,
    required String entityId,
    required DateTime updatedAt,
    required bool isDeleted,
  }) async {
    final payload = <String, dynamic>{
      ...row,
      'user_id': userId,
      'updated_at': updatedAt.toIso8601String(),
      'synced_at': DateTime.now().toIso8601String(),
      'is_deleted': isDeleted,
      'device_id': _hiveService.getDeviceId(),
    };

    await _client.from(table).upsert(payload);
    await _hiveService.saveSyncMetadata(
      SyncMetadata(
        entityId: entityId,
        entityType: _entityTypeForTable(table),
        userId: userId,
        updatedAt: updatedAt,
        syncedAt: DateTime.now(),
        isDeleted: isDeleted,
        deviceId: _hiveService.getDeviceId(),
      ),
    );
  }

  Map<String, Map<String, dynamic>> _indexRemoteRows(
    List<Map<String, dynamic>> rows,
  ) {
    final indexed = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final id = (row['id'] ?? row['entity_id']) as String?;
      if (id == null || id.isEmpty) continue;
      indexed[id] = row;
    }
    return indexed;
  }

  DateTime _rowUpdatedAt(Map<String, dynamic>? row) {
    if (row == null) return DateTime.fromMillisecondsSinceEpoch(0);
    final value = row['updated_at'] ?? row['updatedAt'];
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.tryParse(value.toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  bool _rowIsDeleted(Map<String, dynamic>? row) {
    if (row == null) return false;
    final value = row['is_deleted'] ?? row['isDeleted'];
    return value as bool? ?? false;
  }

  SyncEntityType _entityTypeForTable(String table) {
    switch (table) {
      case _expenseTable:
        return SyncEntityType.expense;
      case _receivableTable:
        return SyncEntityType.receivable;
      case _payableTable:
        return SyncEntityType.payable;
      case _recurringTable:
      default:
        return SyncEntityType.recurringTemplate;
    }
  }

  int _countPending(String userId) {
    return _hiveService.getSyncMetadataForUser(userId).where((entry) {
      if (entry.syncedAt == null) return true;
      return entry.syncedAt!.isBefore(entry.updatedAt);
    }).length;
  }

  Map<String, dynamic> _expenseToCloudRow(Expense expense) {
    return {
      'id': expense.id,
      'user_id': expense.userId,
      'amount': expense.amount,
      'category': expense.category,
      'description': expense.description,
      'date': expense.date.toIso8601String(),
      'recurring_template_id': expense.recurringTemplateId,
      'recurring_due_date': expense.recurringDueDate?.toIso8601String(),
      'created_at': expense.createdAt.toIso8601String(),
      'updated_at': (expense.updatedAt ?? expense.createdAt).toIso8601String(),
    };
  }

  Expense _expenseFromCloudRow(Map<String, dynamic> row) {
    return Expense(
      id: row['id'] as String,
      userId: row['user_id'] as String? ?? '',
      amount: (row['amount'] as num).toDouble(),
      category: row['category'] as String? ?? 'Other',
      description: row['description'] as String?,
      date: DateTime.parse(row['date'] as String),
      recurringTemplateId: row['recurring_template_id'] as String?,
      recurringDueDate: row['recurring_due_date'] == null
          ? null
          : DateTime.parse(row['recurring_due_date'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: row['updated_at'] == null
          ? null
          : DateTime.parse(row['updated_at'] as String),
    );
  }

  Map<String, dynamic> _receivableToCloudRow(Receivable receivable) {
    return {
      'id': receivable.id,
      'user_id': receivable.userId,
      'from_person': receivable.fromPerson,
      'amount': receivable.amount,
      'description': receivable.description,
      'due_date': receivable.dueDate.toIso8601String(),
      'is_paid': receivable.isPaid,
      'created_at': receivable.createdAt.toIso8601String(),
      'updated_at': (receivable.updatedAt ?? receivable.createdAt)
          .toIso8601String(),
    };
  }

  Receivable _receivableFromCloudRow(Map<String, dynamic> row) {
    return Receivable(
      id: row['id'] as String,
      userId: row['user_id'] as String? ?? '',
      fromPerson: row['from_person'] as String? ?? 'Unknown',
      amount: (row['amount'] as num).toDouble(),
      description: row['description'] as String?,
      dueDate: DateTime.parse(row['due_date'] as String),
      isPaid: row['is_paid'] as bool? ?? false,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: row['updated_at'] == null
          ? null
          : DateTime.parse(row['updated_at'] as String),
    );
  }

  Map<String, dynamic> _payableToCloudRow(Payable payable) {
    return {
      'id': payable.id,
      'user_id': payable.userId,
      'to_person': payable.toPerson,
      'amount': payable.amount,
      'remaining_amount': payable.remainingAmount,
      'category': payable.category,
      'notes': payable.notes,
      'created_at': payable.createdAt.toIso8601String(),
      'due_date': payable.dueDate.toIso8601String(),
      'status': payable.status.name,
      'settlements': payable.settlements
          .map((entry) => entry.toJson())
          .toList(),
      'updated_at': (payable.updatedAt ?? payable.createdAt).toIso8601String(),
    };
  }

  Payable _payableFromCloudRow(Map<String, dynamic> row) {
    final settlementsRaw = row['settlements'];
    final settlements = settlementsRaw is List
        ? settlementsRaw
              .whereType<Map>()
              .map((entry) => PayableSettlement.fromJson(entry))
              .toList()
        : <PayableSettlement>[];
    return Payable(
      id: row['id'] as String,
      userId: row['user_id'] as String? ?? '',
      toPerson: row['to_person'] as String? ?? 'Unknown',
      amount: (row['amount'] as num).toDouble(),
      remainingAmount: (row['remaining_amount'] as num).toDouble(),
      category: row['category'] as String? ?? 'Miscellaneous',
      notes: row['notes'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      dueDate: DateTime.parse(row['due_date'] as String),
      status: PayableStatus.values.firstWhere(
        (value) => value.name == row['status'],
        orElse: () => PayableStatus.pending,
      ),
      settlements: settlements,
      updatedAt: row['updated_at'] == null
          ? null
          : DateTime.parse(row['updated_at'] as String),
    );
  }

  bool _payableSettlementsDiffer(Payable local, Payable remote) {
    if (local.settlements.length != remote.settlements.length) {
      return true;
    }

    final localById = {
      for (final settlement in local.settlements) settlement.id: settlement,
    };

    for (final settlement in remote.settlements) {
      final localSettlement = localById[settlement.id];
      if (localSettlement == null) {
        return true;
      }
      if (!_settlementEquals(localSettlement, settlement)) {
        return true;
      }
    }

    return false;
  }

  bool _settlementEquals(PayableSettlement first, PayableSettlement second) {
    return first.id == second.id &&
        first.amount == second.amount &&
        first.remainingAfter == second.remainingAfter &&
        first.note == second.note &&
        first.settledAt.isAtSameMomentAs(second.settledAt);
  }

  Payable _mergePayables(Payable local, Payable remote) {
    final localUpdatedAt = local.updatedAt ?? local.createdAt;
    final remoteUpdatedAt = remote.updatedAt ?? remote.createdAt;
    final newer = localUpdatedAt.isAfter(remoteUpdatedAt)
        ? local
        : remoteUpdatedAt.isAfter(localUpdatedAt)
        ? remote
        : local;

    final mergedSettlementsById = <String, PayableSettlement>{};
    for (final settlement in [...local.settlements, ...remote.settlements]) {
      final existing = mergedSettlementsById[settlement.id];
      if (existing == null ||
          settlement.settledAt.isAfter(existing.settledAt)) {
        mergedSettlementsById[settlement.id] = settlement;
      }
    }

    final mergedSettlements = mergedSettlementsById.values.toList()
      ..sort((first, second) {
        final settledComparison = first.settledAt.compareTo(second.settledAt);
        if (settledComparison != 0) return settledComparison;
        return first.id.compareTo(second.id);
      });

    final settledTotal = mergedSettlements.fold<double>(
      0,
      (sum, settlement) => sum + settlement.amount,
    );
    final remainingAmount = (newer.amount - settledTotal).clamp(
      0.0,
      newer.amount,
    );
    final status = remainingAmount <= 0
        ? PayableStatus.paid
        : mergedSettlements.isEmpty
        ? PayableStatus.pending
        : PayableStatus.partial;

    return newer.copyWith(
      remainingAmount: remainingAmount,
      status: status,
      settlements: mergedSettlements,
      updatedAt: localUpdatedAt.isAfter(remoteUpdatedAt)
          ? localUpdatedAt
          : remoteUpdatedAt,
    );
  }

  Map<String, dynamic> _recurringToCloudRow(RecurringExpenseTemplate template) {
    return {
      'id': template.id,
      'user_id': template.userId,
      'amount': template.amount,
      'category': template.category,
      'payment_method': template.paymentMethod,
      'notes': template.notes,
      'frequency': template.frequency.name,
      'next_due_date': template.nextDueDate.toIso8601String(),
      'is_active': template.isActive,
      'last_generated_at': template.lastGeneratedAt?.toIso8601String(),
      'last_generated_expense_id': template.lastGeneratedExpenseId,
      'created_at': template.createdAt.toIso8601String(),
      'updated_at': (template.updatedAt ?? template.createdAt)
          .toIso8601String(),
    };
  }

  RecurringExpenseTemplate _recurringFromCloudRow(Map<String, dynamic> row) {
    return RecurringExpenseTemplate(
      id: row['id'] as String,
      userId: row['user_id'] as String? ?? '',
      amount: (row['amount'] as num).toDouble(),
      category: row['category'] as String? ?? 'Miscellaneous',
      paymentMethod: row['payment_method'] as String? ?? 'Cash',
      notes: row['notes'] as String?,
      frequency: RecurringFrequency.values.firstWhere(
        (value) => value.name == row['frequency'],
        orElse: () => RecurringFrequency.monthly,
      ),
      nextDueDate: DateTime.parse(row['next_due_date'] as String),
      isActive: row['is_active'] as bool? ?? true,
      lastGeneratedAt: row['last_generated_at'] == null
          ? null
          : DateTime.parse(row['last_generated_at'] as String),
      lastGeneratedExpenseId: row['last_generated_expense_id'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: row['updated_at'] == null
          ? null
          : DateTime.parse(row['updated_at'] as String),
    );
  }
}

class _SyncCounts {
  final int uploads;
  final int downloads;

  const _SyncCounts({required this.uploads, required this.downloads});
}
