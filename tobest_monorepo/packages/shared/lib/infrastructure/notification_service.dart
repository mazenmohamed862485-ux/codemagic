// packages/shared/lib/infrastructure/notification_service.dart
//
// خدمة الإشعارات المحلية — flutter_local_notifications فقط
// لا Push Notifications بأي شكل

import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_service.g.dart';

/// أنواع الإشعارات
enum NotificationType {
  /// موافقة/رفض اشتراك
  subscription,

  /// رسالة جديدة في الشات
  newMessage,

  /// موافقة/رفض تغيير البرنامج
  programChange,

  /// جهاز جديد حاول الدخول
  newDevice,

  /// طلب اشتراك معلق (للـ SUBSCRIPTIONS)
  pendingRequest,

  /// طلب تعديل من SUPPORT
  supportRequest,

  /// رسائل تحفيزية (streak، إنجاز، تذكير)
  motivational,
}

/// خدمة الإشعارات المحلية
///
/// يُستخدم Local Notifications فقط
/// الاكتشاف عبر Adaptive Polling + Background Fetch (workmanager)
class NotificationService {
  NotificationService._(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  /// تهيئة الخدمة — تُستدعى مرة واحدة عند Bootstrap
  static Future<NotificationService> initialize() async {
    final plugin = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings     = DarwinInitializationSettings(
      requestAlertPermission:  true,
      requestBadgePermission:  true,
      requestSoundPermission:  true,
    );

    await plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS:     iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // طلب الإذن على Android 13+
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    developer.log('NotificationService initialized', name: 'NotificationService');
    return NotificationService._(plugin);
  }

  static void _onNotificationTap(NotificationResponse response) {
    developer.log(
      'Notification tapped: ${response.payload}',
      name: 'NotificationService',
    );
    // التعامل مع التنقل يتم في Router عند الحاجة
  }

  // ── إرسال الإشعارات ───────────────────────────────────────

  /// إشعار موافقة/رفض اشتراك
  Future<void> notifySubscriptionUpdate({
    required bool approved,
    String? reason,
    required bool isRtl,
  }) =>
      _show(
        id:      NotificationType.subscription.index,
        title:   isRtl
            ? (approved ? 'تم تفعيل اشتراكك 🎉' : 'تم رفض طلبك')
            : (approved ? 'Subscription Activated' : 'Request Rejected'),
        body:    reason ??
            (isRtl
                ? (approved ? 'يمكنك الآن استخدام التطبيق كاملاً' : 'راجع التطبيق لمعرفة السبب')
                : (approved ? 'You now have full access' : 'Check the app for details')),
        type:    NotificationType.subscription,
        payload: 'subscription',
      );

  /// إشعار رسالة جديدة في الشات
  Future<void> notifyNewMessage({
    required String senderName,
    required String preview,
    required String conversationId,
    required bool isRtl,
  }) =>
      _show(
        id:      NotificationType.newMessage.index,
        title:   senderName,
        body:    preview,
        type:    NotificationType.newMessage,
        payload: 'chat:$conversationId',
      );

  /// إشعار جهاز جديد حاول الدخول
  Future<void> notifyNewDeviceAttempt({
    required String userName,
    required String deviceName,
    required String userId,
    required bool isRtl,
  }) =>
      _show(
        id:      NotificationType.newDevice.index,
        title:   isRtl ? 'محاولة دخول من جهاز جديد' : 'New Device Login Attempt',
        body:    isRtl
            ? '$userName حاول الدخول من $deviceName'
            : '$userName tried to login from $deviceName',
        type:    NotificationType.newDevice,
        payload: 'device:$userId',
      );

  /// إشعار موافقة/رفض تغيير البرنامج
  Future<void> notifyProgramChange({
    required bool approved,
    String? rejectionReason,
    required bool isRtl,
  }) =>
      _show(
        id:      NotificationType.programChange.index,
        title:   isRtl
            ? (approved ? 'تم الموافقة على طلبك' : 'تم رفض طلبك')
            : (approved ? 'Request Approved' : 'Request Rejected'),
        body:    rejectionReason ??
            (isRtl
                ? (approved ? 'تم تطبيق البرنامج الجديد' : 'تواصل مع الدعم لمزيد من التفاصيل')
                : (approved ? 'New program applied' : 'Contact support for details')),
        type:    NotificationType.programChange,
        payload: 'program',
      );

  /// إشعار تحفيزي (streak، إنجاز)
  Future<void> notifyMotivational({
    required String title,
    required String body,
  }) =>
      _show(
        id:      NotificationType.motivational.index,
        title:   title,
        body:    body,
        type:    NotificationType.motivational,
        payload: 'motivational',
      );

  /// إشعار طلب اشتراك معلق
  Future<void> notifyPendingSubscriptionRequest({
    required String userName,
    required bool isRtl,
  }) =>
      _show(
        id:      NotificationType.pendingRequest.index,
        title:   isRtl ? 'طلب اشتراك جديد' : 'New Subscription Request',
        body:    isRtl ? '$userName يطلب الاشتراك' : '$userName requested a subscription',
        type:    NotificationType.pendingRequest,
        payload: 'pending_requests',
      );

  // ── عرض الإشعار ──────────────────────────────────────────

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required NotificationType type,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'tobest_channel',
      'TO Best',
      channelDescription: 'إشعارات تطبيق TO Best',
      importance: Importance.high,
      priority:   Priority.high,
      icon:       '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: androidDetails,
        iOS:     iosDetails,
      ),
      payload: payload,
    );
  }

  /// إلغاء إشعار معين
  Future<void> cancel(int id) => _plugin.cancel(id);

  /// إلغاء جميع الإشعارات
  Future<void> cancelAll() => _plugin.cancelAll();
}

/// مزود NotificationService
@riverpod
Future<NotificationService> notificationService(Ref ref) =>
    NotificationService.initialize();
