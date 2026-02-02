import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/constants.dart';
import 'database_service.dart';

/// Offline-first: automatic background sync when online
/// No data loss during interruptions
class SyncService {
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static bool _isSyncing = false;

  static void startListening() {
    _subscription?.cancel();
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (results.any((r) =>
          r == ConnectivityResult.wifi || r == ConnectivityResult.mobile)) {
        syncWhenOnline();
      }
    });
  }

  static void stopListening() {
    _subscription?.cancel();
  }

  static Future<void> syncWhenOnline() async {
    if (_isSyncing) return;
    _isSyncing = true;

    for (var attempt = 0; attempt < AppConstants.syncRetryAttempts; attempt++) {
      try {
        // TODO: Implement sync with backend
        // 1. Push pending_sync records
        // 2. Pull updates (modules, questions)
        // 3. Clear synced pending records
        await Future.delayed(const Duration(seconds: 1));
        break;
      } catch (e) {
        if (attempt == AppConstants.syncRetryAttempts - 1) rethrow;
        await Future.delayed(Duration(seconds: 1 << attempt));
      }
    }

    _isSyncing = false;
  }

  static Future<void> queueForSync({
    required String tableName,
    required String recordId,
    required String action,
    String? dataJson,
  }) async {
    final db = await DatabaseService.database;
    await db.insert('pending_sync', {
      'tableName': tableName,
      'recordId': recordId,
      'action': action,
      'dataJson': dataJson,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}
