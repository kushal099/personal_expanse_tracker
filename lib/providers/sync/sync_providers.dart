import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sync/sync_models.dart';
import '../../services/connectivity/connectivity_service.dart';
import '../../services/storage/hive_service.dart';
import '../../services/sync/supabase_sync_service.dart';
import '../auth/auth_provider.dart';
import '../storage/storage_providers.dart';

class SyncNotifier extends StateNotifier<SyncState> {
  final Ref _ref;
  final HiveService _hiveService;
  final SupabaseSyncService _syncService;
  final ConnectivityService _connectivityService;

  SyncNotifier(this._ref, this._hiveService)
    : _syncService = SupabaseSyncService(hiveService: _hiveService),
      _connectivityService = ConnectivityService(),
      super(const SyncState());

  /// Get current authenticated user ID
  String? _getUserId() {
    return _ref.read(currentUserIdProvider);
  }

  /// Perform full sync now
  Future<SyncResult> syncNow() async {
    final userId = _getUserId();
    if (userId == null || userId.isEmpty) {
      state = state.copyWith(
        isSyncing: false,
        status: 'Not authenticated',
        error: 'Please log in to sync data',
      );
      return SyncResult(
        uploadCount: 0,
        downloadCount: 0,
        completedAt: DateTime.now(),
        status: 'Not authenticated',
        error: 'User not authenticated',
      );
    }

    final authState = _ref.read(authStateProvider);
    if (!authState.isAuthenticated) {
      state = _hiveService
          .getSyncState(userId)
          .copyWith(isSyncing: false, status: 'Local only', error: null);
      return SyncResult(
        uploadCount: 0,
        downloadCount: 0,
        completedAt: DateTime.now(),
        status: 'Local only',
      );
    }

    // Check connectivity
    final isOnline = await _connectivityService.isOnline();
    if (!isOnline) {
      state = state.copyWith(
        isSyncing: false,
        status: 'Offline',
        error: 'No internet connection',
      );
      return SyncResult(
        uploadCount: 0,
        downloadCount: 0,
        completedAt: DateTime.now(),
        status: 'Offline',
        error: 'No internet connection',
      );
    }

    try {
      final result = await _syncService.syncUser(userId);
      state = _hiveService.getSyncState(userId);
      await _refreshLocalStores(userId);
      return result;
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        status: 'Sync failed',
        error: e.toString(),
      );
      return SyncResult(
        uploadCount: 0,
        downloadCount: 0,
        completedAt: DateTime.now(),
        status: 'Sync failed',
        error: e.toString(),
      );
    }
  }

  /// Refresh current sync status
  Future<void> refreshStatus() async {
    final userId = _getUserId();
    if (userId != null && userId.isNotEmpty) {
      state = _hiveService.getSyncState(userId);
    }
  }

  /// Auto-sync on app startup
  Future<void> autoSyncOnStartup() async {
    final userId = _getUserId();
    if (userId == null || userId.isEmpty) {
      return;
    }
    if (!_ref.read(authStateProvider).isAuthenticated) {
      await refreshStatus();
      return;
    }

    // Don't block the UI; run in background
    Future.microtask(() => syncNow());
  }

  /// Refresh local stores after successful sync
  Future<void> _refreshLocalStores(String userId) async {
    await Future.wait([
      _ref.read(expensesProvider.notifier).fetchExpenses(userId),
      _ref.read(receivablesProvider.notifier).fetchReceivables(userId),
      _ref.read(payablesProvider.notifier).fetchPayables(userId),
      _ref.read(recurringTemplatesProvider.notifier).fetchTemplates(userId),
    ]);
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return SyncNotifier(ref, hiveService);
});
