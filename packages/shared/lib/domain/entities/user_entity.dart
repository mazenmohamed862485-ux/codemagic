// packages/shared/lib/domain/entities/user_entity.dart

import 'package:shared/config/app_config.dart';

/// كيان المستخدم — التمثيل النقي لبيانات المستخدم في طبقة الـ Domain
///
/// لا يحتوي على أي منطق خاص بقاعدة البيانات أو الشبكة
/// كل الحسابات الصحية تعتمد على هذا الكيان
class UserEntity {
  const UserEntity({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    this.phone,
    this.height,
    this.weight,
    this.age,
    this.gender,
    this.profileImageUrl,
    this.subscriptionStatus = SubscriptionStatus.pending,
    this.subscriptionPlan,
    this.subscriptionExpiresAt,
    this.assignedCoachId,
    this.referralCode,
    this.referredBy,
    this.registeredDevices = const [],
    this.maxDevices = 1,
    this.isBanned = false,
    this.preferredLanguage = 'ar',
    this.selectedTheme = 'auto',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;

  /// دور المستخدم — يحدد التطبيق الذي يصل إليه والصلاحيات
  final String role;
  final String name;
  final String? phone;

  /// الطول بالسنتيمتر
  final double? height;

  /// الوزن بالكيلوغرام
  final double? weight;
  final int? age;

  /// 'male' | 'female'
  final String? gender;
  final String? profileImageUrl;
  final SubscriptionStatus subscriptionStatus;
  final String? subscriptionPlan;
  final DateTime? subscriptionExpiresAt;

  /// معرف الكوتش المعين للمستخدم (null إذا لم يكن هناك كوتش)
  final String? assignedCoachId;
  final String? referralCode;
  final String? referredBy;
  final List<String> registeredDevices;
  final int maxDevices;
  final bool isBanned;
  final String preferredLanguage;
  final String selectedTheme;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ── صلاحيات الوصول ───────────────────────────────────

  /// هل يمكنه دخول تطبيق TO Best
  bool get canAccessToBest =>
      AppConfig.toBestRoles.contains(role) && !isBanned;

  /// هل يمكنه دخول تطبيق الإدارة
  bool get canAccessManagement =>
      AppConfig.managementRoles.contains(role) && !isBanned;

  bool get isUser          => role == AppRole.user;
  bool get isCoach         => role == AppRole.coach;
  bool get isManager       => role == AppRole.manager;
  bool get isSupport       => role == AppRole.support;
  bool get isSubscriptions => role == AppRole.subscriptions;

  /// هل الاشتراك مفعّل حالياً
  bool get hasActiveSubscription =>
      subscriptionStatus == SubscriptionStatus.active &&
      (subscriptionExpiresAt == null ||
          subscriptionExpiresAt!.isAfter(DateTime.now()));

  /// هل البيانات الصحية مكتملة (مطلوبة عند تسجيل حساب Google)
  bool get hasHealthData =>
      height != null && weight != null && age != null && gender != null;

  UserEntity copyWith({
    String? id,
    String? email,
    String? role,
    String? name,
    String? phone,
    double? height,
    double? weight,
    int? age,
    String? gender,
    String? profileImageUrl,
    SubscriptionStatus? subscriptionStatus,
    String? subscriptionPlan,
    DateTime? subscriptionExpiresAt,
    String? assignedCoachId,
    String? referralCode,
    String? referredBy,
    List<String>? registeredDevices,
    int? maxDevices,
    bool? isBanned,
    String? preferredLanguage,
    String? selectedTheme,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionExpiresAt:
          subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      assignedCoachId: assignedCoachId ?? this.assignedCoachId,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      registeredDevices: registeredDevices ?? this.registeredDevices,
      maxDevices: maxDevices ?? this.maxDevices,
      isBanned: isBanned ?? this.isBanned,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      selectedTheme: selectedTheme ?? this.selectedTheme,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// حالة الاشتراك
enum SubscriptionStatus {
  /// معلق — ينتظر الموافقة
  pending,

  /// مفعّل
  active,

  /// مرفوض
  rejected,

  /// منتهي
  expired,

  /// وضع المشاهدة المحدود
  guest,
}
