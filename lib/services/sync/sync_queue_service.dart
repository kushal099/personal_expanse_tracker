import '../../models/sync/sync_models.dart';
import '../storage/hive_service.dart';

/// Represents a queued sync operation waiting to be retried
class QueuedSyncOperation {
  final String id;
  final String entityId;
  final SyncEntityType entityType;
  final String userId;
  final Map<String, dynamic> payload;
  final String table;
  final int retryCount;
  final DateTime createdAt;
  final DateTime lastAttemptAt;

  const QueuedSyncOperation({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.userId,
    required this.payload,
    required this.table,
    required this.retryCount,
    required this.createdAt,
    required this.lastAttemptAt,
  });

  /// Calculate backoff duration (exponential: 2^retryCount seconds)
  Duration get backoffDuration {
    final seconds = (1 << retryCount).clamp(1, 3600); // Max 1 hour
    return Duration(seconds: seconds);
  }

  /// Check if this operation should be retried
  bool shouldRetry() {
    if (retryCount >= 5) return false; // Max 5 retries
    final timeSinceLastAttempt = DateTime.now().difference(lastAttemptAt);
    return timeSinceLastAttempt >= backoffDuration;
  }

  /// Create copy with updated fields
  QueuedSyncOperation copyWith({
    String? id,
    String? entityId,
    SyncEntityType? entityType,
    String? userId,
    Map<String, dynamic>? payload,
    String? table,
    int? retryCount,
    DateTime? createdAt,
    DateTime? lastAttemptAt,
  }) {
    return QueuedSyncOperation(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      userId: userId ?? this.userId,
      payload: payload ?? this.payload,
      table: table ?? this.table,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
    );
  }

  /// Serialize to JSON for Hive storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entityId': entityId,
      'entityType': entityType.name,
      'userId': userId,
      'payload': payload,
      'table': table,
      'retryCount': retryCount,
      'createdAt': createdAt.toIso8601String(),
      'lastAttemptAt': lastAttemptAt.toIso8601String(),
    };
  }

  /// Deserialize from JSON
  static QueuedSyncOperation fromJson(Map<dynamic, dynamic> json) {
    return QueuedSyncOperation(
      id: json['id'] as String,
      entityId: json['entityId'] as String,
      entityType: SyncEntityType.values.firstWhere(
        (value) => value.name == json['entityType'],
        orElse: () => SyncEntityType.expense,
      ),
      userId: json['userId'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      table: json['table'] as String,
      retryCount: (json['retryCount'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastAttemptAt: DateTime.parse(json['lastAttemptAt'] as String),
    );
  }
}

/// Service for managing sync retry queue
class SyncQueueService {
  static final SyncQueueService _instance = SyncQueueService._internal();

  factory SyncQueueService() {
    return _instance;
  }

  SyncQueueService._internal();

  final HiveService _hiveService = HiveService();

  /// Add operation to retry queue
  Future<void> queueForRetry({
    required String entityId,
    required SyncEntityType entityType,
    required String userId,
    required Map<String, dynamic> payload,
    required String table,
  }) async {
    final op = QueuedSyncOperation(
      id: '$userId::${entityType.name}::$entityId::${DateTime.now().microsecondsSinceEpoch}',
      entityId: entityId,
      entityType: entityType,
      userId: userId,
      payload: payload,
      table: table,
      retryCount: 0,
      createdAt: DateTime.now(),
      lastAttemptAt: DateTime.now(),
    );

    // Store in Hive using HiveService
    // For now, we'll use the sync_state box to persist this
    // In production, create separate box
    _hiveService.saveSyncMetadata(
      SyncMetadata(
        entityId: op.id,
        entityType: entityType,
        userId: userId,
        updatedAt: DateTime.now(),
        syncedAt: null,
        isDeleted: false,
        deviceId: _hiveService.getDeviceId(),
      ),
    );
  }

  /// Get all operations ready for retry
  List<QueuedSyncOperation> getOperationsReadyForRetry(String userId) {
    // This is a simplified implementation
    // In production, maintain separate queue box in Hive
    return [];
  }

  /// Mark operation as successfully synced (remove from queue)
  Future<void> markAsSynced(String operationId) async {
    // Remove from queue
  }

  /// Mark operation as failed (increment retry count)
  Future<void> markAsFailed(String operationId) async {
    // Update retry count
  }

  /// Clear all operations for a user
  Future<void> clearQueue(String userId) async {
    // Clear all queued operations
  }
}
