// packages/shared/lib/infrastructure/background_service.dart
//
// Background Tasks عبر workmanager (iOS + Android)
// - Background Fetch للشات والإشعارات
// - Weekly Cleanup Flow

import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared/config/app_config.dart';

part 'background_service.g.dart';

// ── أسماء Tasks ──────────────────────────────────────────────
const _kChatFetchTask    = 'com.tobest.chatFetch';
const _kHealthSyncTask   = 'com.tobest.healthSync';
const _kWeeklyCleanup    = 'com.tobest.weeklyCleanup';
const _kConnectivityTask = 'com.tobest.connectivity';

/// Dispatcher لـ Background Tasks
///
/// يُسجَّل في main() قبل runApp()
/// يُستدعى من workmanager في الـ Background
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    developer.log('Background task: $taskName', name: 'BackgroundService');

    try {
      switch (taskName) {
        case _kChatFetchTask:
          await _handleChatFetch(inputData ?? {});
        case _kHealthSyncTask:
          await _handleHealthSync(inputData ?? {});
        case _kWeeklyCleanup:
          await _handleWeeklyCleanup(inputData ?? {});
        default:
          developer.log('Unknown task: $taskName', name: 'BackgroundService');
      }
      return true;
    } catch (e, st) {
      developer.log('Background task failed: $e\n$st', name: 'BackgroundService');
      return false;
    }
  });
}

/// معالج Background Chat Fetch
Future<void> _handleChatFetch(Map<String, dynamic> data) async {
  // يُنفَّذ في Isolate منفصل — يستخدم GAS Client مباشرة
  developer.log('Chat fetch background task', name: 'BackgroundService');
  // التنفيذ الكامل في طبقة البيانات
}

/// معالج Background Health Sync
Future<void> _handleHealthSync(Map<String, dynamic> data) async {
  developer.log('Health sync background task', name: 'BackgroundService');
}

/// معالج Weekly Cleanup
/// الترتيب الآمن: Sync → Cleanup → Sync
Future<void> _handleWeeklyCleanup(Map<String, dynamic> data) async {
  developer.log('Weekly cleanup starting...', name: 'BackgroundService');

  // التحقق من الاتصال قبل البدء
  // إذا لم يكن هناك إنترنت → إعادة الجدولة
  // التنفيذ الفعلي في SyncService
}

/// خدمة إدارة Background Tasks
class BackgroundService {
  BackgroundService._();

  /// تهيئة workmanager — تُستدعى في main()
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
    developer.log('BackgroundService initialized', name: 'BackgroundService');
  }

  /// جدولة Background Chat Fetch
  static Future<void> scheduleChatFetch(String userId) async {
    await Workmanager().registerPeriodicTask(
      '$_kChatFetchTask.$userId',
      _kChatFetchTask,
      frequency:       AppConfig.backgroundFetchInterval,
      constraints:     Constraints(networkType: NetworkType.connected),
      inputData:       {'userId': userId},
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }

  /// جدولة Health Sync
  static Future<void> scheduleHealthSync(String userId) async {
    await Workmanager().registerPeriodicTask(
      '$_kHealthSyncTask.$userId',
      _kHealthSyncTask,
      frequency:       const Duration(hours: 1),
      constraints:     Constraints(networkType: NetworkType.connected),
      inputData:       {'userId': userId},
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }

  /// جدولة Weekly Cleanup
  static Future<void> scheduleWeeklyCleanup(String userId) async {
    await Workmanager().registerPeriodicTask(
      '$_kWeeklyCleanup.$userId',
      _kWeeklyCleanup,
      frequency:       const Duration(days: 7),
      constraints:     Constraints(networkType: NetworkType.connected),
      inputData:       {'userId': userId},
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  /// إلغاء جميع المهام (عند Logout)
  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
    developer.log('All background tasks cancelled', name: 'BackgroundService');
  }

  /// إلغاء مهام مستخدم معين
  static Future<void> cancelForUser(String userId) async {
    await Workmanager().cancelByUniqueName('$_kChatFetchTask.$userId');
    await Workmanager().cancelByUniqueName('$_kHealthSyncTask.$userId');
    await Workmanager().cancelByUniqueName('$_kWeeklyCleanup.$userId');
  }
}

@riverpod
BackgroundService backgroundService(Ref ref) => throw UnimplementedError(
    'BackgroundService is static — use BackgroundService.initialize() in main()');
