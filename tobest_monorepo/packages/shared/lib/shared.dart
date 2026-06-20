// packages/shared/lib/shared.dart
//
// المصدر الرئيسي للحزمة المشتركة — يصدّر جميع الأجزاء العامة بمسار واحد
// ملاحظة: data/models/*.dart (Isar) حُذفت بعد الترحيل لـ drift —
// drift/app_database.dart الآن هو المصدر الوحيد لطبقة البيانات المحلية

// ── Config ────────────────────────────────────────────────────
export 'config/app_config.dart';
// secrets.dart مستثنى عمداً — لا يُصدَّر لمنع الكشف

// ── Domain Entities ───────────────────────────────────────────
export 'domain/entities/user_entity.dart';
export 'domain/entities/workout_entity.dart';
export 'domain/entities/nutrition_entity.dart';
export 'domain/entities/chat_entity.dart';
export 'domain/entities/health_entity.dart';
export 'domain/entities/subscription_entity.dart';
export 'domain/entities/video_entity.dart';

// ── Domain Repositories ───────────────────────────────────────
export 'domain/repositories/auth_repository.dart';
export 'domain/repositories/workout_repository.dart';

// ── Infrastructure ────────────────────────────────────────────
export 'infrastructure/gas_client.dart';
export 'infrastructure/isar_service.dart';      // اسم محفوظ — wrapper على drift
export 'infrastructure/drift/app_database.dart';
export 'infrastructure/video_service.dart';
export 'infrastructure/video_service_drive.dart';
export 'infrastructure/notification_service.dart';
export 'infrastructure/polling_service.dart';
export 'infrastructure/background_service.dart';
export 'infrastructure/sync_service.dart';
export 'infrastructure/food_seeding_service.dart';

// ── Design System ─────────────────────────────────────────────
export 'design/tokens.dart';
export 'design/themes.dart';
export 'design/widgets/breathing_animation.dart';

// ── Utils ─────────────────────────────────────────────────────
export 'utils/evaluator.dart';
export 'utils/validators.dart';
export 'utils/extensions.dart';
