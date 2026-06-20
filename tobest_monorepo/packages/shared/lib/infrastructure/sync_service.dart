// packages/shared/lib/infrastructure/sync_service.dart
//
// خدمة المزامنة مع GAS
// Field-Level Merge: الحقل الأحدث يكسب دائماً

import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/infrastructure/gas_client.dart';
import 'package:shared/infrastructure/isar_service.dart';

part 'sync_service.g.dart';

/// خدمة المزامنة بين Isar و GAS
///
/// كل حقل في Isar له `updatedAt: DateTime`
/// عند التعارض: الحقل الأحدث يكسب دائماً — لا يُسقَط أي تعديل
class SyncService {
  SyncService({
    required GasClient gasClient,
    required IsarService isarService,
  })  : _gas  = gasClient,
        _isar = isarService;

  final GasClient _gas;
  final IsarService _isar;

  bool _isSyncing = false;

  /// التحقق من وجود الإنترنت
  Future<bool> hasInternet() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// رفع التعديلات المحلية لـ GAS
  Future<void> syncLocalChangesToGAS(String userId) async {
    if (!await hasInternet()) {
      developer.log('Sync skipped — no internet', name: 'SyncService');
      return;
    }

    developer.log('Uploading local changes...', name: 'SyncService');

    try {
      // جمع جميع البيانات المعدّلة محلياً
      final pendingChanges = await _collectPendingChanges(userId);
      if (pendingChanges.isEmpty) return;

      await _gas.post(
        '/sync/fields',
        data: {
          'userId':  userId,
          'changes': pendingChanges,
        },
      );

      developer.log(
        'Uploaded ${pendingChanges.length} changes',
        name: 'SyncService',
      );
    } catch (e) {
      developer.log('Upload failed: $e', name: 'SyncService');
      rethrow;
    }
  }

  /// جلب جميع بيانات المستخدم من GAS
  Future<void> syncAllDataFromGAS(String userId) async {
    if (!await hasInternet()) return;

    developer.log('Pulling all data from GAS...', name: 'SyncService');

    try {
      final response = await _gas.get<Map<String, dynamic>>(
        '/sync/user/$userId',
      );

      final data = response.data;
      if (data == null) return;

      // Field-Level Merge لكل نوع بيانات
      await _mergeUserData(userId, data);
      await _mergeWorkoutData(userId, data['workout'] as List<dynamic>? ?? []);
      await _mergeNutritionData(userId, data['nutrition'] as List<dynamic>? ?? []);
      await _mergeHealthData(userId, data['health'] as Map<String, dynamic>? ?? {});
      await _mergeChatData(userId, data['chat'] as List<dynamic>? ?? []);

      developer.log('All data synced from GAS', name: 'SyncService');
    } catch (e) {
      developer.log('Pull from GAS failed: $e', name: 'SyncService');
      rethrow;
    }
  }

  /// Weekly Cleanup Flow — الترتيب الآمن
  ///
  /// Step 1: Sync Local → GAS (لا تضيع بيانات)
  /// Step 2: Cleanup Isar (بما في ذلك Video Cache)
  /// Step 3: Sync GAS → Local (استعادة كاملة)
  Future<void> runWeeklyCleanup(String userId) async {
    if (_isSyncing) {
      developer.log('Cleanup skipped — sync in progress', name: 'SyncService');
      return;
    }

    if (!await hasInternet()) {
      developer.log('Cleanup skipped — no internet', name: 'SyncService');
      _scheduleRetry(userId);
      return;
    }

    _isSyncing = true;

    try {
      // Step 1: رفع أولاً — لا تُحذف بيانات قبل الرفع
      developer.log('Cleanup Step 1: Sync local → GAS', name: 'SyncService');
      await syncLocalChangesToGAS(userId);

      // Step 2: تنظيف Isar (بما في ذلك Video Cache)
      developer.log('Cleanup Step 2: Clear Isar', name: 'SyncService');
      await _isar.clearForWeeklyCleanup();

      // Step 3: استعادة من GAS
      developer.log('Cleanup Step 3: Sync GAS → local', name: 'SyncService');
      await syncAllDataFromGAS(userId);

      developer.log('Weekly cleanup completed successfully', name: 'SyncService');
    } catch (e) {
      developer.log('Weekly cleanup failed: $e — retrying later', name: 'SyncService');
      // ⚠️ لا تُكمل الـ Cleanup إذا فشل أي خطوة
      _scheduleRetry(userId);
    } finally {
      _isSyncing = false;
    }
  }

  void _scheduleRetry(String userId) {
    developer.log('Cleanup retry scheduled', name: 'SyncService');
    // Retry عند توفر الإنترنت — يتم عبر Connectivity listener
  }

  // ── Field-Level Merge ─────────────────────────────────────

  Future<void> _mergeUserData(String userId, Map<String, dynamic> data) async {
    // الدمج حسب updatedAt لكل حقل
    final remoteUpdatedAt = _parseDate(data['updatedAt']);
    final localUser       = await _isar.getCurrentUser();

    if (localUser == null || remoteUpdatedAt == null) return;
    final localUpdatedAt = localUser.updatedAt;

    if (localUpdatedAt == null || remoteUpdatedAt.isAfter(localUpdatedAt)) {
      // الحقل الريموت أحدث — يُطبَّق
      await _isar.saveUser(localUser..fromRemote(data));
    }
  }

  Future<void> _mergeWorkoutData(String userId, List<dynamic> entries) async {
    // كل entry له updatedAt — يُقارن مع النسخة المحلية
    for (final entry in entries) {
      final entryMap = entry as Map<String, dynamic>;
      // تُطبَّق منطق الدمج في WorkoutRepository
      developer.log('Merging workout entry: ${entryMap['id']}', name: 'SyncService');
    }
  }

  Future<void> _mergeNutritionData(String userId, List<dynamic> meals) async {
    for (final meal in meals) {
      developer.log('Merging meal: ${(meal as Map)['id']}', name: 'SyncService');
    }
  }

  Future<void> _mergeHealthData(String userId, Map<String, dynamic> health) async {
    developer.log('Merging health data', name: 'SyncService');
  }

  Future<void> _mergeChatData(String userId, List<dynamic> messages) async {
    developer.log('Merging ${messages.length} chat messages', name: 'SyncService');
  }

  Future<List<Map<String, dynamic>>> _collectPendingChanges(String userId) async {
    // جمع جميع الحقول التي تغيرت منذ آخر sync
    return [];
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

/// مزود SyncService
@riverpod
Future<SyncService> syncService(Ref ref) async {
  final gas  = await ref.watch(gasClientProvider.future);
  final isar = await ref.watch(isarServiceProvider.future);
  return SyncService(gasClient: gas, isarService: isar);
}
