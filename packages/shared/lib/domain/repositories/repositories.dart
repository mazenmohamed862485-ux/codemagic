// packages/shared/lib/domain/repositories/chat_repository.dart

import 'package:shared/domain/entities/chat_entity.dart';

abstract class ChatRepository {
  /// جلب رسائل محادثة
  Stream<List<ChatMessage>> getMessages(String conversationId);

  /// إرسال رسالة نصية
  Future<ChatMessage> sendTextMessage({
    required String conversationId,
    required String senderId,
    required String senderRole,
    required String content,
    String? replyToId,
    String? replyToContent,
  });

  /// إرسال صورة
  Future<ChatMessage> sendImageMessage({
    required String conversationId,
    required String senderId,
    required String senderRole,
    required String imageLocalPath,
    String? replyToId,
  });

  /// إرسال رسالة صوتية
  Future<ChatMessage> sendVoiceMessage({
    required String conversationId,
    required String senderId,
    required String senderRole,
    required String audioLocalPath,
    required int durationSeconds,
  });

  /// تعديل رسالة
  Future<ChatMessage> editMessage({
    required String messageId,
    required String newContent,
  });

  /// حذف رسالة (تظهر "تم حذف هذه الرسالة")
  Future<void> deleteMessage(String messageId);

  /// إضافة تفاعل
  Future<void> addReaction({
    required String messageId,
    required String userId,
    required String reactionType,
  });

  /// حذف تفاعل
  Future<void> removeReaction({
    required String messageId,
    required String userId,
  });

  /// تحديد الرسائل كمقروءة
  Future<void> markAsRead({
    required String conversationId,
    required String userId,
  });

  /// جلب قائمة المحادثات حسب الدور
  Future<List<Conversation>> getConversations({
    required String userId,
    required String role,
  });

  /// إنشاء محادثة جديدة
  Future<Conversation> createConversation({
    required String initiatorId,
    required String initiatorRole,
    required String targetId,
    required String targetRole,
  });

  /// polling يدوي — يُستدعى كل N ثانية
  Future<void> pollNewMessages({
    required String conversationId,
    required DateTime since,
  });
}

// ─────────────────────────────────────────────────────────────

// packages/shared/lib/domain/repositories/nutrition_repository.dart

import 'package:shared/domain/entities/nutrition_entity.dart';

abstract class NutritionRepository {
  /// جلب وجبات اليوم
  Future<List<MealEntry>> getTodayMeals(String userId);

  /// حفظ وجبة
  Future<MealEntry> saveMeal(MealEntry meal);

  /// حذف وجبة
  Future<void> deleteMeal(String mealId);

  /// البحث في قاعدة الأطعمة
  Future<List<FoodItem>> searchFoods(String query, {int limit = 20});

  /// جلب الهدف الغذائي اليومي
  Future<MacroResult?> getDailyGoal(String userId);

  /// تحديث الهدف الغذائي
  Future<void> updateDailyGoal({
    required String userId,
    required MacroResult goal,
  });

  /// مزامنة بيانات التغذية مع GAS
  Future<void> syncNutrition(String userId);
}

// ─────────────────────────────────────────────────────────────

// packages/shared/lib/domain/repositories/health_repository.dart

import 'package:shared/domain/entities/health_entity.dart';

abstract class HealthRepository {
  /// حفظ بيانات الخطوات اليومية
  Future<StepsRecord> saveSteps(StepsRecord record);

  /// جلب بيانات الخطوات لنطاق زمني
  Future<List<StepsRecord>> getStepsHistory({
    required String userId,
    required DateTime from,
    required DateTime to,
  });

  /// حفظ بيانات النوم
  Future<SleepRecord> saveSleep(SleepRecord record);

  /// جلب بيانات النوم
  Future<List<SleepRecord>> getSleepHistory({
    required String userId,
    required DateTime from,
    required DateTime to,
  });

  /// حفظ قياسات جسدية
  Future<BodyMeasurement> saveMeasurement(BodyMeasurement measurement);

  /// جلب تاريخ القياسات
  Future<List<BodyMeasurement>> getMeasurementHistory({
    required String userId,
    int limit = 30,
  });

  /// جلب آخر قياس
  Future<BodyMeasurement?> getLatestMeasurement(String userId);

  /// مزامنة بيانات الصحة مع GAS
  Future<void> syncHealthData(String userId);
}

// ─────────────────────────────────────────────────────────────

// packages/shared/lib/domain/repositories/subscription_repository.dart

import 'package:shared/domain/entities/subscription_entity.dart';

abstract class SubscriptionRepository {
  /// جلب الخطط المتاحة
  Future<List<SubscriptionPlan>> getPlans();

  /// إرسال طلب اشتراك جديد
  Future<SubscriptionRequest> submitRequest({
    required String userId,
    required String planId,
    required String paymentImagePath,
    required String requestType,
  });

  /// جلب حالة طلب المستخدم الحالي
  Future<SubscriptionRequest?> getMyRequest(String userId);

  /// الموافقة على طلب (SUBSCRIPTIONS فقط)
  Future<void> approveRequest({
    required String requestId,
    required int durationDays,
    required String reviewedBy,
  });

  /// رفض طلب (SUBSCRIPTIONS فقط)
  Future<void> rejectRequest({
    required String requestId,
    required String reason,
    required String reviewedBy,
  });

  /// إرسال طلب تعديل من SUPPORT
  Future<SupportSubscriptionRequest> submitSupportRequest({
    required String userId,
    required String requestedBy,
    required String targetPlanId,
    required String reason,
  });

  /// الموافقة/الرفض على طلب SUPPORT
  Future<void> reviewSupportRequest({
    required String requestId,
    required bool approved,
    String? rejectionReason,
  });

  /// جلب طلبات الاشتراك (للإدارة)
  Future<List<SubscriptionRequest>> getAllRequests({
    SubscriptionRequestStatus? status,
  });

  /// تعديل خطة مباشرة (SUBSCRIPTIONS / MANAGER)
  Future<void> updatePlan({required String planId, required Map<String, dynamic> fields});
}

// ─────────────────────────────────────────────────────────────

// packages/shared/lib/domain/repositories/video_repository.dart

import 'package:shared/domain/entities/video_entity.dart';

abstract class VideoRepository {
  /// جلب metadata الفيديوهات لتمرين
  Future<List<VideoMetadata>> getVideosForExercise(String exerciseId);

  /// الحصول على Streaming URL (مخفي عن الـ UI)
  Future<String> getStreamUrl(String videoId);

  /// تحميل فيديو مسبقاً للـ Cache
  Future<void> prefetchVideo(String videoId);

  /// التحقق من وجود الفيديو في Cache
  Future<bool> isVideoCached(String videoId);

  /// مسح Cache الفيديو
  Future<void> clearVideoCache();

  /// حجم Cache الحالي بالبايت
  Future<int> getVideoCacheSizeBytes();
}
