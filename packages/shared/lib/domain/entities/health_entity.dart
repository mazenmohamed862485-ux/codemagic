// packages/shared/lib/domain/entities/health_entity.dart

import 'package:shared/config/app_config.dart';

/// سجل بيانات الخطوات اليومية
class StepsRecord {
  const StepsRecord({
    required this.id,
    required this.userId,
    required this.date,
    required this.steps,
    required this.userWeight,
    required this.userHeightCm,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final DateTime date;
  final int steps;

  /// الوزن الحالي للمستخدم (لحساب السعرات المحروقة)
  final double userWeight;

  /// الطول بالسنتيمتر (لحساب المسافة)
  final double userHeightCm;
  final DateTime? updatedAt;

  /// المسافة بالكيلومتر: (خطوات × طول × 0.413) / 100000
  double get distanceKm =>
      (steps * userHeightCm * AppConfig.strideRatio) / 100000;

  /// السعرات المحروقة: خطوات × 0.04 × وزن (تقريبي)
  double get caloriesBurned =>
      steps * AppConfig.caloriesPerStepPerKg * userWeight;
}

/// سجل النوم اليومي
class SleepRecord {
  const SleepRecord({
    required this.id,
    required this.userId,
    required this.date,
    required this.durationHours,
    required this.durationMinutes,
    required this.quality,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final DateTime date;

  /// ساعات النوم
  final int durationHours;

  /// دقائق إضافية
  final int durationMinutes;

  /// جودة النوم
  final SleepQuality quality;
  final DateTime? updatedAt;

  /// المدة الكاملة بالساعات
  double get totalHours => durationHours + durationMinutes / 60.0;

  /// هل النوم أقل من الحد الأدنى الموصى به
  bool get isBelowWarningThreshold =>
      totalHours < AppConfig.sleepWarningThreshold;
}

/// جودة النوم — 4 مستويات
enum SleepQuality {
  poor('poor', 'سيئ', 'Poor'),
  fair('fair', 'عادي', 'Fair'),
  good('good', 'جيد', 'Good'),
  excellent('excellent', 'ممتاز', 'Excellent');

  const SleepQuality(this.key, this.labelAr, this.labelEn);
  final String key;
  final String labelAr;
  final String labelEn;
}

/// القياسات الجسدية
class BodyMeasurement {
  const BodyMeasurement({
    required this.id,
    required this.userId,
    required this.date,
    this.weight,
    this.height,
    this.chest,
    this.waist,
    this.hip,
    this.neck,
    this.bodyFatPercent,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final DateTime date;

  /// الوزن بالكيلوغرام
  final double? weight;

  /// الطول بالسنتيمتر
  final double? height;

  /// محيط الصدر (cm)
  final double? chest;

  /// محيط الخصر (cm)
  final double? waist;

  /// محيط الورك (cm)
  final double? hip;

  /// محيط الرقبة (cm) — مطلوب لـ Navy Method
  final double? neck;

  /// نسبة الدهون المحسوبة
  final double? bodyFatPercent;
  final DateTime? updatedAt;

  /// حساب نسبة الدهون بـ Navy Method
  /// يتطلب: الخصر، الرقبة، الطول (للذكور) | الخصر، الورك، الرقبة، الطول (للإناث)
  static double? calcNavyBodyFat({
    required String gender,
    required double waistCm,
    required double neckCm,
    required double heightCm,
    double? hipCm,
  }) {
    if (gender == 'male') {
      // Navy Method للذكور: 86.010×log10(خصر−رقبة) − 70.041×log10(طول) + 36.76
      final diff = waistCm - neckCm;
      if (diff <= 0) return null;
      return 86.010 * _log10(diff) -
          70.041 * _log10(heightCm) +
          36.76;
    } else {
      // Navy Method للإناث — تتطلب قياس الورك
      if (hipCm == null) return null;
      final sum = waistCm + hipCm - neckCm;
      if (sum <= 0) return null;
      return 163.205 * _log10(sum) -
          97.684 * _log10(heightCm) -
          78.387;
    }
  }

  static double _log10(double x) => x > 0 ? (x == 0 ? 0 : (x > 0 ? (x / 2.302585) : 0)) : 0;
}
