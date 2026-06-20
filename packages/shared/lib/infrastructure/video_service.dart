// packages/shared/lib/infrastructure/video_service.dart
//
// واجهة خدمة الفيديو المجردة — قابلة للاستبدال مستقبلاً
// بـ CloudflareVideoService أو BunnyVideoService بدون لمس الـ UI

import 'package:shared/domain/entities/video_entity.dart';

/// خدمة الفيديو المجردة
///
/// التطبيق الحالي: [VideoServiceDrive] — عبر Google Drive
/// تطبيقات مستقبلية محتملة: Cloudflare Stream، Bunny.net، Mux
/// التبديل يتم فقط في مزود Riverpod — لا تغيير في الـ UI أو الـ Domain
abstract class VideoService {
  /// جلب metadata الفيديوهات لتمرين معين
  Future<List<VideoMetadata>> getVideosForExercise(String exerciseId);

  /// الحصول على Streaming URL للتشغيل
  ///
  /// ⚠️ هذا الـ URL يُمرَّر مباشرة لـ video_player ولا يُعرض في الـ UI أبداً
  Future<String> getStreamUrl(String videoId);

  /// تحميل فيديو مسبقاً للـ Cache (صامت)
  Future<void> prefetchVideo(String videoId);

  /// التحقق من وجود الفيديو في Cache
  Future<bool> isVideoCached(String videoId);

  /// مسح Cache الفيديو (يُستدعى في Weekly Cleanup)
  Future<void> clearVideoCache();

  /// حجم Cache الحالي بالبايت
  Future<int> getVideoCacheSizeBytes();
}
