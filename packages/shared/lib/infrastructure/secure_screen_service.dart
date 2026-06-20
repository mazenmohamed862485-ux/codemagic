// packages/shared/lib/infrastructure/secure_screen_service.dart
//
// إصلاح أمني حقيقي: الشاشات الحساسة كانت تستخدم SystemUiMode.immersive
// فقط (يُخفي شريط الحالة) — هذا لا يمنع لقطات الشاشة أو التسجيل!
// الحل الصحيح: FLAG_SECURE عبر flutter_windowmanager (Android فقط — iOS لا يدعم هذا)

import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

/// خدمة حماية الشاشات الحساسة من لقطات الشاشة والتسجيل
///
/// تُستخدم في: OTP، تغيير كلمة المرور، شاشات الدفع
/// ⚠️ تعمل على Android فقط — على iOS لا توجد طريقة برمجية مكافئة
/// (Apple لا تسمح بمنع لقطات الشاشة بشكل برمجي)
class SecureScreenService {
  SecureScreenService._();

  /// تفعيل الحماية — يُستدعى في initState() للشاشة الحساسة
  static Future<void> enable() async {
    if (!Platform.isAndroid) return;
    try {
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      developer.log('FLAG_SECURE enabled', name: 'SecureScreenService');
    } catch (e) {
      developer.log('Failed to enable FLAG_SECURE: $e', name: 'SecureScreenService');
    }
  }

  /// تعطيل الحماية — يُستدعى في dispose() عند مغادرة الشاشة
  static Future<void> disable() async {
    if (!Platform.isAndroid) return;
    try {
      await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
      developer.log('FLAG_SECURE disabled', name: 'SecureScreenService');
    } catch (e) {
      developer.log('Failed to disable FLAG_SECURE: $e', name: 'SecureScreenService');
    }
  }
}

/// Mixin لتسهيل تطبيق FLAG_SECURE في أي StatefulWidget
///
/// الاستخدام:
/// ```dart
/// class _MyScreenState extends State<MyScreen> with SecureScreenMixin {
///   // لا حاجة لأي كود إضافي — يُطبَّق تلقائياً
/// }
/// ```
mixin SecureScreenMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    SecureScreenService.enable();
  }

  @override
  void dispose() {
    SecureScreenService.disable();
    super.dispose();
  }
}
