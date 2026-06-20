// C-12: saveWorkoutLogLocally مُنفَّذ بالكامل
// W-3:  PerformancePoint يُستورَد من shared/utils/evaluator.dart (لا تكرار)
// إصلاح: import dart:convert كان بالخطأ داخل دالة — نُقل للأعلى
// إصلاح: setWeightsJson كان يُخزَّن بـ .toString() الهش — الآن jsonEncode صحيح

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/domain/entities/workout_entity.dart';
import 'package:shared/infrastructure/gas_client.dart';
import 'package:shared/infrastructure/isar_service.dart';
import 'package:shared/utils/evaluator.dart';
import 'package:tobest/features/auth/presentation/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value, OrderingTerm;
import 'package:shared/infrastructure/drift/app_database.dart';

part 'workout_provider.g.dart';

@riverpod
Future<List<ExerciseEntity>> todayExercises(Ref ref) async {
  final userId = ref.watch(authStateProvider).valueOrNull?.id;
  if (userId == null) return [];

  final isar = await ref.watch(isarServiceProvider.future);
  final local = await (isar.db.select(isar.db.exercisesTable)
        ..where((t) => t.sessionType.contains(_todaySessionType()))
        ..limit(20))
      .get();

  if (local.isNotEmpty) return local.map(_rowToExercise).toList();

  try {
    final gas  = await ref.read(gasClientProvider.future);
    final resp = await gas.get<Map<String, dynamic>>(
      '/workout/today', queryParameters: {'userId': userId},
    );
    final list = resp.data?['exercises'] as List<dynamic>? ?? [];
    final exercises = list.map((e) => _parseExercise(e as Map<String, dynamic>)).toList();
    // Cache locally
    await isar.db.batch((b) {
      for (final ex in exercises) {
        b.insertOnConflictUpdate(isar.db.exercisesTable, _exerciseToCompanion(ex));
      }
    });
    return exercises;
  } catch (e) {
    developer.log('Failed to fetch exercises: $e', name: 'WorkoutProvider');
    return [];
  }
}

@riverpod
Future<List<WorkoutLogEntry>> exerciseHistory(Ref ref, String exerciseId) async {
  final userId = ref.watch(authStateProvider).valueOrNull?.id;
  if (userId == null) return [];
  final isar  = await ref.watch(isarServiceProvider.future);
  final rows  = await (isar.db.select(isar.db.workoutLogsTable)
        ..where((t) => t.userId.equals(userId) & t.exerciseId.equals(exerciseId))
        ..orderBy([(t) => OrderingTerm.desc(t.date)])
        ..limit(30))
      .get();
  return rows.map((r) => _rowToLogEntry(r.toJson())).toList();
}

@riverpod
EvalResult? liveEvaluation(
  Ref ref, {
  required String exerciseId,
  required double currentWeight,
  required int currentReps,
  required DateTime now,
}) {
  final historyAsync = ref.watch(exerciseHistoryProvider(exerciseId));
  return historyAsync.when(
    loading: () => null,
    error:   (_, __) => null,
    data: (history) {
      if (history.isEmpty) return EvalResult.all['beg']!;
      final last     = history.first;
      final lastBest = Evaluator.bestSet(last.sets);
      if (lastBest == null) return EvalResult.all['beg']!;
      return Evaluator.evaluate(
        prev: PerformancePoint(weight: lastBest.weight, reps: lastBest.reps, date: last.date),
        curr: PerformancePoint(weight: currentWeight, reps: currentReps, date: now),
        history: history,
      );
    },
  );
}

@riverpod
RepSuggestion? repSuggestion(Ref ref, int reps) => Evaluator.repSuggestion(reps);

@riverpod
Future<bool> isPR(Ref ref, {required String exerciseId, required double weight, required int reps}) async {
  final history = await ref.read(exerciseHistoryProvider(exerciseId).future);
  return Evaluator.checkPR(history, weight, reps);
}

// ── Active Session ────────────────────────────────────────────

class ActiveSessionState {
  const ActiveSessionState({this.isActive = false, this.exercise, this.sets = const [], this.startedAt});
  final bool isActive;
  final ExerciseEntity? exercise;
  final List<SetRecord> sets;
  final DateTime? startedAt;

  ActiveSessionState copyWith({bool? isActive, ExerciseEntity? exercise, List<SetRecord>? sets, DateTime? startedAt}) =>
      ActiveSessionState(
        isActive:  isActive  ?? this.isActive,
        exercise:  exercise  ?? this.exercise,
        sets:      sets      ?? this.sets,
        startedAt: startedAt ?? this.startedAt,
      );
}

@riverpod
class ActiveWorkoutSession extends _$ActiveWorkoutSession {
  @override
  ActiveSessionState build() => const ActiveSessionState();

  void startSession(ExerciseEntity exercise) => state = state.copyWith(
    isActive: true, exercise: exercise,
    startedAt: DateTime.now(), sets: [],
  );

  void addSet({required double weight, required int reps, int? rpe, int? rir}) =>
    state = state.copyWith(sets: [
      ...state.sets,
      SetRecord(weight: weight, reps: reps, rpe: rpe, rir: rir, epley1RM: Evaluator.epley(weight, reps)),
    ]);

  void editSet(int index, {required double weight, required int reps}) {
    final updated = List<SetRecord>.from(state.sets);
    updated[index] = updated[index].copyWith(weight: weight, reps: reps, epley1RM: Evaluator.epley(weight, reps));
    state = state.copyWith(sets: updated);
  }

  void removeSet(int index) {
    final updated = List<SetRecord>.from(state.sets)..removeAt(index);
    state = state.copyWith(sets: updated);
  }

  Future<WorkoutLogEntry?> finishSession(WidgetRef widgetRef) async {
    if (!state.isActive || state.exercise == null || state.sets.isEmpty) return null;
    final user = widgetRef.read(authStateProvider).valueOrNull;
    if (user == null) return null;

    final entry = WorkoutLogEntry(
      id:           const Uuid().v4(),
      userId:       user.id,
      exerciseId:   state.exercise!.id,
      exerciseName: state.exercise!.name,
      date:         state.startedAt ?? DateTime.now(),
      sets:         state.sets,
      sessionType:  state.exercise!.sessionType,
      updatedAt:    DateTime.now(),
    );

    // C-12: مُنفَّذ بالكامل
    await _saveWorkoutLogLocally(entry, widgetRef);

    try {
      final gas = await widgetRef.read(gasClientProvider.future);
      await gas.post('/workout/log', data: _entryToJson(entry));
    } catch (e) {
      developer.log('GAS workout sync deferred: $e', name: 'WorkoutProvider');
    }

    state = const ActiveSessionState();
    widgetRef.invalidate(exerciseHistoryProvider(entry.exerciseId));
    return entry;
  }

  // C-12: التنفيذ الحقيقي — jsonEncode بدل .toString() الهش
  Future<void> _saveWorkoutLogLocally(WorkoutLogEntry entry, WidgetRef widgetRef) async {
    final isar = await widgetRef.read(isarServiceProvider.future);
    await isar.db.into(isar.db.workoutLogsTable).insertOnConflictUpdate(
      WorkoutLogsTableCompanion(
        id:             Value(entry.id),
        userId:         Value(entry.userId),
        exerciseId:     Value(entry.exerciseId),
        exerciseName:   Value(entry.exerciseName),
        date:           Value(entry.date),
        sessionType:    Value.absentIfNull(entry.sessionType),
        evaluation:     Value.absentIfNull(entry.evaluation),
        notes:          Value.absentIfNull(entry.notes),
        setWeightsJson: Value(jsonEncode(entry.sets.map((s) => s.weight).toList())),
        setRepsJson:    Value(jsonEncode(entry.sets.map((s) => s.reps).toList())),
        setRpeJson:     Value(jsonEncode(entry.sets.map((s) => s.rpe).toList())),
        setRirJson:     Value(jsonEncode(entry.sets.map((s) => s.rir).toList())),
        updatedAt:      Value(entry.updatedAt),
      ),
    );
    developer.log('Workout log saved locally: ${entry.id}', name: 'WorkoutProvider');
  }

  Map<String, dynamic> _entryToJson(WorkoutLogEntry e) => {
    'id': e.id, 'userId': e.userId,
    'exerciseId': e.exerciseId, 'exerciseName': e.exerciseName,
    'date': e.date.toIso8601String(), 'sessionType': e.sessionType,
    'sets': e.sets.map((s) => {'weight': s.weight, 'reps': s.reps, 'rpe': s.rpe, 'rir': s.rir}).toList(),
    'updatedAt': e.updatedAt?.toIso8601String(),
  };
}

// ── Helpers ───────────────────────────────────────────────────
String _todaySessionType() {
  final day = DateTime.now().weekday;
  return 'Session $day';
}

ExerciseEntity _parseExercise(Map<String, dynamic> d) => ExerciseEntity(
  id: d['id'] as String, name: d['name'] as String,
  muscle: d['muscle'] as String? ?? '',
  sessionType: d['sessionType'] as String? ?? '',
  isPrimary: d['isPrimary'] as bool? ?? true,
  alt1: d['alt1'] as String?, alt2: d['alt2'] as String?,
  note: d['note'] as String?,
  warmupSets: d['warmupSets'] as String?,
  targetSets: d['targetSets'] as int?,
  repRange:   d['repRange'] as String?,
  restRange:  d['restRange'] as String?,
  videoIds: List<String>.from(d['videoIds'] as List? ?? []),
);

ExerciseEntity _rowToExercise(ExercisesTableData r) => ExerciseEntity(
  id: r.id, name: r.name,
  muscle: r.muscle, sessionType: r.sessionType,
  isPrimary: r.isPrimary, alt1: r.alt1,
  alt2: r.alt2, note: r.note,
  warmupSets: r.warmupSets, targetSets: r.targetSets,
  repRange: r.repRange, restRange: r.restRange,
  videoIds: List<String>.from(jsonDecode(r.videoIdsJson) as List),
);

WorkoutLogEntry _rowToLogEntry(Map<String, dynamic> r) {
  final weights = List<double>.from(
      (jsonDecode(r['setWeightsJson'] as String? ?? '[]') as List).map((e) => (e as num).toDouble()));
  final repsL = List<int>.from(
      (jsonDecode(r['setRepsJson'] as String? ?? '[]') as List).map((e) => (e as num).toInt()));
  final rpeL = (jsonDecode(r['setRpeJson'] as String? ?? '[]') as List)
      .map((e) => e == null ? null : (e as num).toInt())
      .toList();
  final rirL = (jsonDecode(r['setRirJson'] as String? ?? '[]') as List)
      .map((e) => e == null ? null : (e as num).toInt())
      .toList();

  final sets = List.generate(weights.length, (i) => SetRecord(
        weight: weights[i],
        reps:   i < repsL.length ? repsL[i] : 0,
        rpe:    i < rpeL.length ? rpeL[i] : null,
        rir:    i < rirL.length ? rirL[i] : null,
      ));

  return WorkoutLogEntry(
    id:           r['id'] as String,
    userId:       r['userId'] as String,
    exerciseId:   r['exerciseId'] as String,
    exerciseName: r['exerciseName'] as String,
    date:         r['date'] as DateTime,
    sets:         sets,
    sessionType:  r['sessionType'] as String?,
    evaluation:   r['evaluation'] as String?,
    notes:        r['notes'] as String?,
    updatedAt:    r['updatedAt'] as DateTime?,
  );
}

dynamic _exerciseToCompanion(ExerciseEntity e) => ExercisesTableCompanion(
  id: Value(e.id), name: Value(e.name), muscle: Value(e.muscle),
  sessionType: Value(e.sessionType), isPrimary: Value(e.isPrimary),
  alt1: Value.absentIfNull(e.alt1), alt2: Value.absentIfNull(e.alt2),
  note: Value.absentIfNull(e.note), warmupSets: Value.absentIfNull(e.warmupSets),
  targetSets: Value.absentIfNull(e.targetSets), repRange: Value.absentIfNull(e.repRange),
  restRange: Value.absentIfNull(e.restRange), videoIdsJson: Value(jsonEncode(e.videoIds)),
);
