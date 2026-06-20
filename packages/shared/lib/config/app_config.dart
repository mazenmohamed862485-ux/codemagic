// packages/shared/lib/config/app_config.dart

import 'package:flutter/foundation.dart';

/// إعدادات التطبيق المركزية — كل الثوابت المشتركة هنا
///
/// الفائدة: تغيير اسم التطبيق أو Package ID أو الإعدادات
/// يتم من مكان واحد فقط دون لمس منطق الكود
class AppConfig {
  AppConfig._();

  // ── معلومات التطبيق الرئيسي ──────────────────────────
  static const String toBestName       = 'TO Best';
  static const String toBestPackageId  = 'com.tobest.app';
  static const String toBestVersion    = '1.0.0';

  // ── معلومات تطبيق الإدارة ────────────────────────────
  static const String managementName      = 'TO Best Management';
  static const String managementPackageId = 'com.tobest.management';
  static const String managementVersion   = '1.0.0';

  // ── إعدادات الشبكة ────────────────────────────────────
  /// مهلة الاتصال بـ GAS (ثوانٍ)
  static const Duration connectTimeout = Duration(seconds: 30);

  /// مهلة استقبال الرد من GAS (ثوانٍ)
  static const Duration receiveTimeout = Duration(seconds: 60);

  /// عدد محاولات إعادة الطلب عند الفشل
  static const int maxRetries = 3;

  // ── إعدادات الـ Polling ───────────────────────────────
  /// أقل فترة بين طلبات الشات عند النشاط (ثوانٍ)
  static const Duration chatPollingActive   = Duration(seconds: 5);

  /// أعلى فترة بين طلبات الشات عند الخمول (ثوانٍ)
  static const Duration chatPollingIdle     = Duration(seconds: 30);

  /// فترة Background Fetch عبر workmanager (دقائق)
  static const Duration backgroundFetchInterval = Duration(minutes: 15);

  // ── إعدادات الفيديو ──────────────────────────────────
  /// الحد الأقصى لـ Cache الفيديو (500 MB)
  static const int videoCacheMaxBytes = 500 * 1024 * 1024;

  // ── إعدادات الـ OTP ───────────────────────────────────
  /// صلاحية الـ OTP (دقائق)
  static const int otpExpiryMinutes = 10;

  /// فترة إعادة الإرسال (ثوانٍ)
  static const int otpResendSeconds = 60;

  /// الحد الأقصى لطلبات OTP في الساعة
  static const int otpRateLimit = 3;

  // ── الشاشات المحمية بـ FLAG_SECURE ───────────────────
  static const List<String> secureRoutes = [
    '/workout',
    '/nutrition',
    '/change-password',
    '/otp',
  ];

  // ── إعدادات التقييم ───────────────────────────────────
  /// حد رفع الوزن — عند هذا العدد من التكرارات أو أكثر
  static const int repsUpThreshold   = 12;

  /// حد خفض الوزن — عند هذا العدد من التكرارات أو أقل
  static const int repsDownThreshold = 4;

  /// عدد الأسابيع التي يُعتبر بعدها الثبات ركوداً
  static const int stagnationWeeks = 3;

  // ── أدوار المستخدمين ─────────────────────────────────
  /// هيكل قابل للتوسع — يمكن إضافة أدوار جديدة هنا
  static const List<String> toBestRoles      = [AppRole.user, AppRole.coach];
  static const List<String> managementRoles  = [
    AppRole.manager,
    AppRole.support,
    AppRole.subscriptions,
  ];

  // ── إعدادات Pedometer ────────────────────────────────
  /// معامل حساب المسافة: (خطوات × طول × 0.413) / 100000
  static const double strideRatio = 0.413;

  /// سعرات لكل خطوة: خطوات × 0.04 × وزن المستخدم
  static const double caloriesPerStepPerKg = 0.04;

  // ── إعدادات النوم ────────────────────────────────────
  /// الحد الأدنى للنوم قبل ظهور التحذير (ساعات)
  static const double sleepWarningThreshold = 6.0;

  // ── وضع التطوير ──────────────────────────────────────
  static bool get isDebug => kDebugMode;
}

/// أسماء الأدوار كثوابت نصية — مرجع مركزي
abstract class AppRole {
  static const String user          = 'USER';
  static const String coach         = 'COACH';
  static const String manager       = 'MANAGER';
  static const String support       = 'SUPPORT';
  static const String subscriptions = 'SUBSCRIPTIONS';
}
