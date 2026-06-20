// packages/shared/lib/infrastructure/polling_service.dart
//
// Adaptive Polling للشات
// Foreground نشط: 5 ثواني → خامل: يزداد تدريجياً حتى 30 ثانية
// Background: workmanager

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/config/app_config.dart';

part 'polling_service.g.dart';

/// خدمة الـ Polling التكيّفي للشات
///
/// تُقلل تردد الطلبات تلقائياً عند خمول المستخدم
/// وتعود للـ 5 ثواني فوراً عند أي نشاط
class PollingService {
  PollingService({required this.onPoll});

  /// Callback يُستدعى في كل دورة polling
  final Future<void> Function() onPoll;

  Timer? _timer;
  Duration _currentInterval = AppConfig.chatPollingActive;
  DateTime _lastActivity    = DateTime.now();
  bool _isRunning           = false;

  /// بدء الـ Polling
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _scheduleNext();
    developer.log('Polling started', name: 'PollingService');
  }

  /// إيقاف الـ Polling
  void stop() {
    _timer?.cancel();
    _timer    = null;
    _isRunning = false;
    developer.log('Polling stopped', name: 'PollingService');
  }

  /// إعادة تعيين المؤقت عند نشاط المستخدم
  void onUserActivity() {
    _lastActivity    = DateTime.now();
    _currentInterval = AppConfig.chatPollingActive;

    // إعادة جدولة فورية
    _timer?.cancel();
    if (_isRunning) _scheduleNext();
  }

  void _scheduleNext() {
    _timer = Timer(_currentInterval, () async {
      if (!_isRunning) return;

      try {
        await onPoll();
      } catch (e) {
        developer.log('Polling error: $e', name: 'PollingService');
      }

      // حساب الفترة التالية بناءً على وقت آخر نشاط
      _updateInterval();
      _scheduleNext();
    });
  }

  /// تحديث فترة الـ Polling بشكل تدريجي
  void _updateInterval() {
    final idleSeconds = DateTime.now()
        .difference(_lastActivity)
        .inSeconds;

    if (idleSeconds < 30) {
      _currentInterval = AppConfig.chatPollingActive;  // 5s
    } else if (idleSeconds < 120) {
      _currentInterval = const Duration(seconds: 10);
    } else if (idleSeconds < 300) {
      _currentInterval = const Duration(seconds: 20);
    } else {
      _currentInterval = AppConfig.chatPollingIdle;   // 30s
    }

    developer.log(
      'Polling interval: ${_currentInterval.inSeconds}s (idle: ${idleSeconds}s)',
      name: 'PollingService',
    );
  }

  /// الفترة الحالية (للاختبار)
  Duration get currentInterval => _currentInterval;

  void dispose() => stop();
}

/// Factory مزود PollingService
@riverpod
PollingService pollingService(Ref ref, Future<void> Function() onPoll) {
  final service = PollingService(onPoll: onPoll);
  ref.onDispose(service.dispose);
  return service;
}
