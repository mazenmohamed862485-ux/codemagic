// packages/shared/lib/domain/entities/workout_entity.dart

/// سِت تدريبي واحد (مجموعة)
class SetRecord {
  const SetRecord({
    required this.weight,
    required this.reps,
    this.rpe,
    this.rir,
    this.epley1RM,
  });

  /// الوزن بالكيلوغرام
  final double weight;

  /// عدد التكرارات
  final int reps;

  /// Rate of Perceived Exertion (1-10)
  final int? rpe;

  /// Reps in Reserve (0-4)
  final int? rir;

  /// أقصى وزن لتكرار واحد محسوب بمعادلة Epley
  final double? epley1RM;

  SetRecord copyWith({
    double? weight,
    int? reps,
    int? rpe,
    int? rir,
    double? epley1RM,
  }) =>
      SetRecord(
        weight: weight ?? this.weight,
        reps: reps ?? this.reps,
        rpe: rpe ?? this.rpe,
        rir: rir ?? this.rir,
        epley1RM: epley1RM ?? this.epley1RM,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetRecord &&
          weight == other.weight &&
          reps == other.reps;

  @override
  int get hashCode => Object.hash(weight, reps);
}

/// كيان تمرين واحد
class ExerciseEntity {
  const ExerciseEntity({
    required this.id,
    required this.name,
    required this.muscle,
    required this.sessionType,
    required this.isPrimary,
    this.alt1,
    this.alt2,
    this.note,
    this.warmupSets,
    this.targetSets,
    this.repRange,
    this.restRange,
    this.videoIds = const [],
  });

  final String id;
  final String name;

  /// المجموعة العضلية المستهدفة (عربي)
  final String muscle;

  /// نوع الجلسة: 'Upper A', 'Anterior B', إلخ
  final String sessionType;

  /// هل التمرين رئيسي أم مساعد
  final bool isPrimary;
  final String? alt1;
  final String? alt2;
  final String? note;

  /// عدد سيتات الإحماء (مثل '1~2')
  final String? warmupSets;
  final int? targetSets;

  /// نطاق التكرارات كنص (مثل '6~8')
  final String? repRange;

  /// نطاق وقت الراحة كنص (مثل '3~5')
  final String? restRange;

  /// معرّفات الفيديوهات المرتبطة
  final List<String> videoIds;
}

/// سجل أداء تمرين في جلسة معينة
class WorkoutLogEntry {
  const WorkoutLogEntry({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.exerciseName,
    required this.date,
    required this.sets,
    this.sessionType,
    this.evaluation,
    this.notes,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String exerciseId;
  final String exerciseName;
  final DateTime date;
  final List<SetRecord> sets;
  final String? sessionType;

  /// نتيجة التقييم (s1, s2, s3, rv, gd, st, ws, dn, beg)
  final String? evaluation;
  final String? notes;
  final DateTime? updatedAt;

  WorkoutLogEntry copyWith({
    String? id,
    String? userId,
    String? exerciseId,
    String? exerciseName,
    DateTime? date,
    List<SetRecord>? sets,
    String? sessionType,
    String? evaluation,
    String? notes,
    DateTime? updatedAt,
  }) =>
      WorkoutLogEntry(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        exerciseId: exerciseId ?? this.exerciseId,
        exerciseName: exerciseName ?? this.exerciseName,
        date: date ?? this.date,
        sets: sets ?? this.sets,
        sessionType: sessionType ?? this.sessionType,
        evaluation: evaluation ?? this.evaluation,
        notes: notes ?? this.notes,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// نتيجة التقييم الكاملة بعد حساب الـ Evaluator
class EvalResult {
  const EvalResult({
    required this.code,
    required this.labelAr,
    required this.labelEn,
    required this.iconName,
  });

  /// رمز التقييم: s1, s2, s3, rv, gd, st, ws, dn, beg
  final String code;

  /// النص العربي
  final String labelAr;

  /// النص الإنجليزي
  final String labelEn;

  /// اسم الـ Icon (من Material Icons)
  final String iconName;

  static const Map<String, EvalResult> all = {
    's1': EvalResult(
      code: 's1',
      labelAr: 'ممتاز جدا جدا',
      labelEn: 'Outstanding',
      iconName: 'emoji_events',
    ),
    's2': EvalResult(
      code: 's2',
      labelAr: 'ممتاز جدا',
      labelEn: 'Excellent',
      iconName: 'star',
    ),
    's3': EvalResult(
      code: 's3',
      labelAr: 'ممتاز',
      labelEn: 'Great',
      iconName: 'thumb_up',
    ),
    'rv': EvalResult(
      code: 'rv',
      labelAr: 'استعادة المستوى',
      labelEn: 'Level Restored',
      iconName: 'trending_up',
    ),
    'gd': EvalResult(
      code: 'gd',
      labelAr: 'جيد',
      labelEn: 'Good',
      iconName: 'check_circle',
    ),
    'st': EvalResult(
      code: 'st',
      labelAr: 'ثبات',
      labelEn: 'Stagnation',
      iconName: 'remove_circle',
    ),
    'ws': EvalResult(
      code: 'ws',
      labelAr: 'تحذير ثبات',
      labelEn: 'Warning Plateau',
      iconName: 'warning',
    ),
    'dn': EvalResult(
      code: 'dn',
      labelAr: 'انخفاض',
      labelEn: 'Decline',
      iconName: 'arrow_circle_down',
    ),
    'beg': EvalResult(
      code: 'beg',
      labelAr: 'بداية',
      labelEn: 'Beginning',
      iconName: 'play_circle',
    ),
  };
}

/// اقتراح تعديل الوزن بناءً على عدد التكرارات
class RepSuggestion {
  const RepSuggestion({required this.type, required this.messageKey});

  /// 'up' = ارفع الوزن | 'down' = انزل الوزن
  final String type;

  /// مفتاح الترجمة للرسالة
  final String messageKey;
}

/// برامج التدريب المتاحة
enum WorkoutProgram {
  upperLower('UL', 'Upper / Lower', 4),
  anteriorPosterior('AP', 'Anterior / Posterior', 4),
  fullBody('FB', 'Full Body', 3),
  arnold('ARNOLD', 'Arnold', 5),
  pushPullLegs('PPL', 'Push / Pull / Legs', 5),
  custom('CUSTOM', 'برنامج مخصص', 4);

  const WorkoutProgram(this.id, this.nameEn, this.daysPerWeek);

  final String id;
  final String nameEn;
  final int daysPerWeek;
}
