// packages/shared/lib/domain/repositories/workout_repository.dart

import 'package:shared/domain/entities/workout_entity.dart';

/// واجهة مستودع التمارين
abstract class WorkoutRepository {
  /// جلب تمارين جلسة معينة للمستخدم
  Future<List<ExerciseEntity>> getSessionExercises({
    required String userId,
    required String sessionType,
  });

  /// حفظ أداء تمرين
  Future<WorkoutLogEntry> saveWorkoutLog(WorkoutLogEntry entry);

  /// جلب سجل التمارين للمستخدم
  Future<List<WorkoutLogEntry>> getWorkoutHistory({
    required String userId,
    required String exerciseId,
    int limit = 30,
  });

  /// جلب آخر تمرين لحساب التقييم
  Future<WorkoutLogEntry?> getLastWorkoutLog({
    required String userId,
    required String exerciseId,
  });

  /// جلب أفضل 10 PRs
  Future<List<PRRecord>> getTopPRs({required String userId, int limit = 10});

  /// طلب تغيير/إضافة برنامج تدريبي
  Future<void> requestProgramChange({
    required String userId,
    required String requestedProgram,
    required String reason,
  });

  /// تحديث جلسات اليوم من GAS
  Future<void> syncTodayWorkout(String userId);
}

/// أفضل رقم قياسي في تمرين
class PRRecord {
  const PRRecord({
    required this.exerciseId,
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.epley1RM,
    required this.date,
  });

  final String exerciseId;
  final String exerciseName;
  final double weight;
  final int reps;
  final double epley1RM;
  final DateTime date;
}
