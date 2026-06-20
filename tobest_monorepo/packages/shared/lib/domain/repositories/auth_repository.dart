// packages/shared/lib/domain/repositories/auth_repository.dart

import 'package:shared/domain/entities/user_entity.dart';

/// واجهة المصادقة — تُنفَّذ في طبقة البيانات
abstract class AuthRepository {
  /// تسجيل دخول بالإيميل وكلمة المرور
  Future<UserEntity> loginWithEmail({
    required String email,
    required String password,
    required String deviceId,
    required String deviceName,
  });

  /// تسجيل دخول بـ Google
  Future<UserEntity> loginWithGoogle({
    required String idToken,
    required String deviceId,
    required String deviceName,
  });

  /// تسجيل حساب جديد
  Future<UserEntity> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required double height,
    required double weight,
    required int age,
    required String gender,
    String? referralCode,
  });

  /// إكمال بيانات Google Sign-In (عند نقص البيانات الصحية)
  Future<UserEntity> completeGoogleProfile({
    required String userId,
    required double height,
    required double weight,
    required int age,
    required String gender,
    required String phone,
  });

  /// تسجيل الخروج
  Future<void> logout();

  /// إرسال OTP لنسيان كلمة المرور
  Future<void> sendOtp(String email);

  /// التحقق من OTP
  Future<bool> verifyOtp({required String email, required String otp});

  /// إعادة تعيين كلمة المرور بعد التحقق
  Future<void> resetPassword({
    required String email,
    required String newPassword,
  });

  /// جلب المستخدم الحالي المخزَّن محلياً
  Future<UserEntity?> getCurrentUser();

  /// تحديث بيانات المستخدم
  Future<UserEntity> updateProfile({
    required String userId,
    String? name,
    String? phone,
    double? height,
    double? weight,
    int? age,
    String? gender,
    String? profileImageUrl,
  });

  /// تدفق حالة المصادقة
  Stream<UserEntity?> get authStateChanges;

  /// قائمة الأجهزة المسجلة
  Future<List<RegisteredDevice>> getDevices(String userId);

  /// حذف جهاز مسجل
  Future<void> removeDevice({
    required String userId,
    required String deviceId,
  });

  /// تعديل عدد الأجهزة المسموح بها
  Future<void> updateDeviceLimit({
    required String userId,
    required int maxDevices,
  });
}

/// جهاز مسجل للمستخدم
class RegisteredDevice {
  const RegisteredDevice({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.registeredAt,
    this.lastSeenAt,
  });

  final String deviceId;
  final String deviceName;
  final String platform;
  final DateTime registeredAt;
  final DateTime? lastSeenAt;
}
