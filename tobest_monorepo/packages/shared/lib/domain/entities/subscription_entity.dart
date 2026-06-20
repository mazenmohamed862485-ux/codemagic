// packages/shared/lib/domain/entities/subscription_entity.dart

/// طلب اشتراك
class SubscriptionRequest {
  const SubscriptionRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.planId,
    required this.requestType,
    required this.paymentImageUrl,
    required this.status,
    required this.createdAt,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
    this.approvedDurationDays,
    this.startDate,
    this.expiresAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String planId;

  /// 'new' | 'renewal' | 'upgrade'
  final String requestType;
  final String paymentImageUrl;
  final SubscriptionRequestStatus status;
  final DateTime createdAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final int? approvedDurationDays;
  final DateTime? startDate;
  final DateTime? expiresAt;
}

enum SubscriptionRequestStatus { pending, approved, rejected }

/// خطة اشتراك (ديناميكية من GAS)
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.price,
    required this.features,
    required this.isActive,
    this.durationDays,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final double price;
  final List<String> features;
  final bool isActive;

  /// مدة الخطة بالأيام (null = مفتوح)
  final int? durationDays;
}

/// طلب تعديل اشتراك من SUPPORT
class SupportSubscriptionRequest {
  const SupportSubscriptionRequest({
    required this.id,
    required this.userId,
    required this.requestedBy,
    required this.targetPlanId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.rejectionReason,
  });

  final String id;
  final String userId;
  final String requestedBy;
  final String targetPlanId;
  final String reason;
  final SupportRequestStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;
}

enum SupportRequestStatus { pending, approved, rejected }

/// طلب تغيير/إضافة برنامج تدريبي
class ProgramChangeRequest {
  const ProgramChangeRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.requestedProgram,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.rejectionReason,
  });

  final String id;
  final String userId;
  final String userName;
  final String requestedProgram;
  final String reason;
  final ProgramChangeStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;
}

enum ProgramChangeStatus { pending, approved, rejected }
