// packages/shared/lib/infrastructure/isar_service.dart
// C-4: Isar→drift | M-13: IsarServiceRef→Ref

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/infrastructure/drift/app_database.dart';

part 'isar_service.g.dart';

class IsarService {
  IsarService._(this.db);
  final AppDatabase db;

  static Future<IsarService> open() async {
    final db = AppDatabase();
    developer.log('Database opened (drift)', name: 'IsarService');
    return IsarService._(db);
  }

  // ── User ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final row = await (db.select(db.usersTable)..limit(1)).getSingleOrNull();
    return row?.toJson();
  }

  Future<void> saveUser(Map<String, dynamic> u) async {
    await db.into(db.usersTable).insertOnConflictUpdate(
      UsersTableCompanion(
        id:                 Value(u['id'] as String),
        email:              Value(u['email'] as String),
        role:               Value(u['role'] as String),
        name:               Value(u['name'] as String),
        phone:              Value.absentIfNull(u['phone'] as String?),
        height:             Value.absentIfNull((u['height'] as num?)?.toDouble()),
        weight:             Value.absentIfNull((u['weight'] as num?)?.toDouble()),
        age:                Value.absentIfNull(u['age'] as int?),
        gender:             Value.absentIfNull(u['gender'] as String?),
        subscriptionStatus: Value(u['subscriptionStatus'] as String? ?? 'pending'),
        subscriptionPlan:   Value.absentIfNull(u['subscriptionPlan'] as String?),
        assignedCoachId:    Value.absentIfNull(u['assignedCoachId'] as String?),
        referralCode:       Value.absentIfNull(u['referralCode'] as String?),
        referredBy:         Value.absentIfNull(u['referredBy'] as String?),
        registeredDevices:  Value(jsonEncode(u['registeredDevices'] ?? [])),
        maxDevices:         Value(u['maxDevices'] as int? ?? 1),
        isBanned:           Value(u['isBanned'] as bool? ?? false),
        preferredLanguage:  Value(u['preferredLanguage'] as String? ?? 'ar'),
        selectedTheme:      Value(u['selectedTheme'] as String? ?? 'auto'),
        token:              Value.absentIfNull(u['token'] as String?),
        updatedAt:          Value(DateTime.now()),
      ),
    );
  }

  Future<void> clearUser() => db.delete(db.usersTable).go();

  // ── Workout ───────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getWorkoutHistory({
    required String userId,
    required String exerciseId,
    int limit = 30,
  }) async {
    final rows = await (db.select(db.workoutLogsTable)
          ..where((t) => t.userId.equals(userId) & t.exerciseId.equals(exerciseId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(limit))
        .get();
    return rows.map((r) => r.toJson()).toList();
  }

  Future<void> saveWorkoutLog(Map<String, dynamic> log) async {
    await db.into(db.workoutLogsTable).insertOnConflictUpdate(
      WorkoutLogsTableCompanion(
        id:             Value(log['id'] as String),
        userId:         Value(log['userId'] as String),
        exerciseId:     Value(log['exerciseId'] as String),
        exerciseName:   Value(log['exerciseName'] as String),
        date:           Value(DateTime.parse(log['date'] as String)),
        sessionType:    Value.absentIfNull(log['sessionType'] as String?),
        evaluation:     Value.absentIfNull(log['evaluation'] as String?),
        notes:          Value.absentIfNull(log['notes'] as String?),
        setWeightsJson: Value(jsonEncode(log['setWeights'] ?? [])),
        setRepsJson:    Value(jsonEncode(log['setReps'] ?? [])),
        setRpeJson:     Value(jsonEncode(log['setRpe'] ?? [])),
        setRirJson:     Value(jsonEncode(log['setRir'] ?? [])),
        updatedAt:      Value(DateTime.now()),
      ),
    );
  }

  // ── Food ─────────────────────────────────────────────────────
  Future<int> getFoodCount() => db.foodItemsTable.count().getSingle();

  Future<void> seedFoods(List<Map<String, dynamic>> foods) async {
    const batchSize = 200;
    for (int i = 0; i < foods.length; i += batchSize) {
      final chunk = foods.skip(i).take(batchSize).toList();
      await db.batch((b) {
        for (final f in chunk) {
          b.insertOnConflictUpdate(
            db.foodItemsTable,
            FoodItemsTableCompanion(
              id:                Value(f['id'] as String? ?? f['name'] as String),
              name:              Value(f['name'] as String? ?? ''),
              category:          Value(f['category'] as String? ?? 'general'),
              state:             Value(f['state'] as String? ?? 'raw'),
              preparationMethod: Value(f['preparationMethod'] as String? ?? 'none'),
              calories:          Value((f['calories'] as num?)?.toDouble() ?? 0),
              protein:           Value((f['protein'] as num?)?.toDouble() ?? 0),
              fat:               Value((f['fat'] as num?)?.toDouble() ?? 0),
              carbs:             Value((f['carbs'] as num?)?.toDouble() ?? 0),
              fiber:             Value((f['fiber'] as num?)?.toDouble() ?? 0),
              basisG:            Value((f['basis_g'] as num?)?.toDouble() ?? 100),
              serving:           Value(f['serving'] as String? ?? '100g'),
              normalizedName:    Value(f['normalizedName'] as String? ?? ''),
              searchKey:         Value(f['searchKey'] as String? ?? ''),
              aliasesJson:       Value(jsonEncode(f['aliases'] ?? [])),
              searchHintsJson:   Value(jsonEncode(f['searchHints'] ?? [])),
            ),
          );
        }
      });
    }
    developer.log('Seeded ${foods.length} foods', name: 'IsarService');
  }

  Future<List<Map<String, dynamic>>> searchFoods(String query, {int limit = 20}) async {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];
    final rows = await (db.select(db.foodItemsTable)
          ..where((t) =>
              t.name.lower().contains(q) |
              t.normalizedName.contains(q) |
              t.searchKey.contains(q) |
              t.aliasesJson.contains(q))
          ..limit(limit))
        .get();
    return rows.map((r) => r.toJson()).toList();
  }

  /// جلب قاعدة الأطعمة كاملة — تُستخدم لدوال Evaluator
  /// (parseMealText, suggestMeal) التي تحتاج كل العناصر للمطابقة
  Future<List<Map<String, dynamic>>> getAllFoods() async {
    final rows = await db.select(db.foodItemsTable).get();
    return rows.map((r) => r.toJson()).toList();
  }

  // ── Chat ──────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getMessages(String convId, {int limit = 50}) async {
    final rows = await (db.select(db.chatMessagesTable)
          ..where((t) => t.conversationId.equals(convId))
          ..orderBy([(t) => OrderingTerm.desc(t.sentAt)])
          ..limit(limit))
        .get();
    return rows.map((r) => r.toJson()).toList();
  }

  Future<void> saveMessages(List<Map<String, dynamic>> messages) async {
    await db.batch((b) {
      for (final m in messages) {
        b.insertOnConflictUpdate(
          db.chatMessagesTable,
          ChatMessagesTableCompanion(
            id:             Value(m['id'] as String),
            conversationId: Value(m['conversationId'] as String),
            senderId:       Value(m['senderId'] as String),
            senderRole:     Value(m['senderRole'] as String),
            content:        Value(m['content'] as String),
            sentAt:         Value(DateTime.parse(m['sentAt'] as String)),
            messageType:    Value(m['messageType'] as String? ?? 'text'),
            mediaUrl:       Value.absentIfNull(m['mediaUrl'] as String?),
            replyToId:      Value.absentIfNull(m['replyToId'] as String?),
            replyToContent: Value.absentIfNull(m['replyToContent'] as String?),
            isDeleted:      Value(m['isDeleted'] as bool? ?? false),
            isEdited:       Value(m['isEdited'] as bool? ?? false),
            reactionsJson:  Value(jsonEncode(m['reactions'] ?? [])),
          ),
        );
      }
    });
  }

  // ── Health ────────────────────────────────────────────────────
  Future<void> saveSteps(Map<String, dynamic> s) async {
    await db.into(db.stepsTable).insertOnConflictUpdate(
      StepsTableCompanion(
        id:           Value(s['id'] as String),
        userId:       Value(s['userId'] as String),
        date:         Value(DateTime.parse(s['date'] as String)),
        steps:        Value(s['steps'] as int),
        userWeight:   Value((s['userWeight'] as num).toDouble()),
        userHeightCm: Value((s['userHeightCm'] as num).toDouble()),
        updatedAt:    Value(DateTime.now()),
      ),
    );
  }

  Future<void> saveSleep(Map<String, dynamic> s) async {
    await db.into(db.sleepRecordsTable).insertOnConflictUpdate(
      SleepRecordsTableCompanion(
        id:              Value(s['id'] as String),
        userId:          Value(s['userId'] as String),
        date:            Value(DateTime.parse(s['date'] as String)),
        durationHours:   Value(s['durationHours'] as int),
        durationMinutes: Value(s['durationMinutes'] as int),
        quality:         Value(s['quality'] as String? ?? 'fair'),
        updatedAt:       Value(DateTime.now()),
      ),
    );
  }

  Future<void> saveMeasurement(Map<String, dynamic> m) async {
    await db.into(db.measurementsTable).insertOnConflictUpdate(
      MeasurementsTableCompanion(
        id:             Value(m['id'] as String),
        userId:         Value(m['userId'] as String),
        date:           Value(DateTime.parse(m['date'] as String)),
        weight:         Value.absentIfNull((m['weight'] as num?)?.toDouble()),
        height:         Value.absentIfNull((m['height'] as num?)?.toDouble()),
        chest:          Value.absentIfNull((m['chest'] as num?)?.toDouble()),
        waist:          Value.absentIfNull((m['waist'] as num?)?.toDouble()),
        hip:            Value.absentIfNull((m['hip'] as num?)?.toDouble()),
        neck:           Value.absentIfNull((m['neck'] as num?)?.toDouble()),
        bodyFatPercent: Value.absentIfNull((m['bodyFatPercent'] as num?)?.toDouble()),
        updatedAt:      Value(DateTime.now()),
      ),
    );
  }

  // ── Weekly Cleanup ────────────────────────────────────────────
  Future<void> clearForWeeklyCleanup() async {
    developer.log('Weekly cleanup starting...', name: 'IsarService');
    await db.transaction(() async {
      await db.delete(db.workoutLogsTable).go();
      await db.delete(db.mealEntriesTable).go();
      await db.delete(db.stepsTable).go();
      await db.delete(db.sleepRecordsTable).go();
      await db.delete(db.chatMessagesTable).go();
    });
    developer.log('Weekly cleanup done', name: 'IsarService');
  }

  Future<void> close() => db.close();
}

@riverpod
Future<IsarService> isarService(Ref ref) async {
  final service = await IsarService.open();
  ref.onDispose(service.close);
  return service;
}
