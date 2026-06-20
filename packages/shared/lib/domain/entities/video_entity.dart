// packages/shared/lib/domain/entities/video_entity.dart

/// بيانات فيديو تمرين — Metadata فقط
///
/// الـ Streaming URL يُجلب عند الطلب ولا يُخزَّن في الـ UI
class VideoMetadata {
  const VideoMetadata({
    required this.id,
    required this.exerciseId,
    required this.title,
    required this.durationSeconds,
    required this.order,
    this.thumbnailUrl,
    this.isCached = false,
  });

  final String id;
  final String exerciseId;
  final String title;
  final int durationSeconds;

  /// الترتيب في Carousel الفيديوهات
  final int order;

  /// صورة مصغرة (اختياري)
  final String? thumbnailUrl;

  /// هل الفيديو محفوظ في Cache المحلي
  final bool isCached;

  VideoMetadata copyWith({
    String? id,
    String? exerciseId,
    String? title,
    int? durationSeconds,
    int? order,
    String? thumbnailUrl,
    bool? isCached,
  }) =>
      VideoMetadata(
        id: id ?? this.id,
        exerciseId: exerciseId ?? this.exerciseId,
        title: title ?? this.title,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        order: order ?? this.order,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        isCached: isCached ?? this.isCached,
      );
}

/// حالة تحميل/تشغيل الفيديو
enum VideoPlayState {
  /// جاهز للتشغيل
  idle,

  /// يتم التحميل
  loading,

  /// يعمل
  playing,

  /// موقوف
  paused,

  /// انتهى
  ended,

  /// خطأ — غير متاح أوفلاين
  offlineUnavailable,

  /// خطأ عام
  error,
}
