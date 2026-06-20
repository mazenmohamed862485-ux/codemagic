// packages/shared/lib/infrastructure/drift/app_database.dart
//
// C-4: ترحيل كامل من Isar v3 → drift v2.18 (متوافق مع Dart 3.x)
// كل Tables مُعرَّفة هنا — يولَّد _$AppDatabase تلقائياً بـ drift_dev

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_database.g.dart';

// ═══════════════════════════════════════════════════════════
//  TABLES
// ═══════════════════════════════════════════════════════════

/// جدول المستخدمين
class UsersTable extends Table {
  @override
  String get tableName => 'users';

  TextColumn get id              => text()();
  TextColumn get email           => text()();
  TextColumn get role            => text()();
  TextColumn get name            => text()();
  TextColumn get phone           => text().nullable()();
  RealColumn get height          => real().nullable()();
  RealColumn get weight          => real().nullable()();
  IntColumn  get age             => integer().nullable()();
  TextColumn get gender          => text().nullable()();
  TextColumn get profileImageUrl => text().nullable()();
  TextColumn get subscriptionStatus => text().withDefault(const Constant('pending'))();
  TextColumn get subscriptionPlan   => text().nullable()();
  DateTimeColumn get subscriptionExpiresAt => dateTime().nullable()();
  TextColumn get assignedCoachId  => text().nullable()();
  TextColumn get referralCode     => text().nullable()();
  TextColumn get referredBy       => text().nullable()();
  TextColumn get registeredDevices => text().withDefault(const Constant('[]'))();
  IntColumn  get maxDevices       => integer().withDefault(const Constant(1))();
  BoolColumn get isBanned         => boolean().withDefault(const Constant(false))();
  TextColumn get preferredLanguage => text().withDefault(const Constant('ar'))();
  TextColumn get selectedTheme    => text().withDefault(const Constant('auto'))();
  TextColumn get token            => text().nullable()();
  DateTimeColumn get createdAt    => dateTime().nullable()();
  DateTimeColumn get updatedAt    => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// جدول سجلات التمارين
class WorkoutLogsTable extends Table {
  @override
  String get tableName => 'workout_logs';

  TextColumn get id           => text()();
  TextColumn get userId       => text()();
  TextColumn get exerciseId   => text()();
  TextColumn get exerciseName => text()();
  DateTimeColumn get date     => dateTime()();
  TextColumn get sessionType  => text().nullable()();
  TextColumn get evaluation   => text().nullable()();
  TextColumn get notes        => text().nullable()();
  // Sets مُسطَّحة كـ JSON strings
  TextColumn get setWeightsJson => text().withDefault(const Constant('[]'))();
  TextColumn get setRepsJson    => text().withDefault(const Constant('[]'))();
  TextColumn get setRpeJson     => text().withDefault(const Constant('[]'))();
  TextColumn get setRirJson     => text().withDefault(const Constant('[]'))();
  DateTimeColumn get updatedAt  => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// جدول التمارين
class ExercisesTable extends Table {
  @override
  String get tableName => 'exercises';

  TextColumn get id          => text()();
  TextColumn get name        => text()();
  TextColumn get muscle      => text()();
  TextColumn get sessionType => text()();
  BoolColumn get isPrimary   => boolean().withDefault(const Constant(true))();
  TextColumn get alt1        => text().nullable()();
  TextColumn get alt2        => text().nullable()();
  TextColumn get note        => text().nullable()();
  TextColumn get warmupSets  => text().nullable()();
  IntColumn  get targetSets  => integer().nullable()();
  TextColumn get repRange    => text().nullable()();
  TextColumn get restRange   => text().nullable()();
  TextColumn get videoIdsJson => text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// جدول الأطعمة
class FoodItemsTable extends Table {
  @override
  String get tableName => 'food_items';

  TextColumn get id                => text()();
  TextColumn get name              => text()();
  TextColumn get category          => text().withDefault(const Constant('general'))();
  TextColumn get state             => text().withDefault(const Constant('raw'))();
  TextColumn get preparationMethod => text().withDefault(const Constant('none'))();
  RealColumn get calories          => real().withDefault(const Constant(0.0))();
  RealColumn get protein           => real().withDefault(const Constant(0.0))();
  RealColumn get fat               => real().withDefault(const Constant(0.0))();
  RealColumn get carbs             => real().withDefault(const Constant(0.0))();
  RealColumn get fiber             => real().withDefault(const Constant(0.0))();
  RealColumn get basisG            => real().withDefault(const Constant(100.0))();
  TextColumn get serving           => text().withDefault(const Constant('100g'))();
  TextColumn get normalizedName    => text().withDefault(const Constant(''))();
  TextColumn get searchKey         => text().withDefault(const Constant(''))();
  TextColumn get aliasesJson       => text().withDefault(const Constant('[]'))();
  TextColumn get searchHintsJson   => text().withDefault(const Constant('[]'))();
  RealColumn get cost              => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// جدول الوجبات
class MealEntriesTable extends Table {
  @override
  String get tableName => 'meal_entries';

  TextColumn get id              => text()();
  TextColumn get userId          => text()();
  DateTimeColumn get date        => dateTime()();
  TextColumn get mealType        => text()();
  RealColumn get totalCalories   => real().withDefault(const Constant(0.0))();
  RealColumn get totalProtein    => real().withDefault(const Constant(0.0))();
  RealColumn get totalCarbs      => real().withDefault(const Constant(0.0))();
  RealColumn get totalFat        => real().withDefault(const Constant(0.0))();
  RealColumn get totalFiber      => real().withDefault(const Constant(0.0))();
  // Items as JSON
  TextColumn get itemsJson       => text().withDefault(const Constant('[]'))();
  DateTimeColumn get updatedAt   => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// جدول الخطوات اليومية
class StepsTable extends Table {
  @override
  String get tableName => 'steps';

  TextColumn get id           => text()();
  TextColumn get userId       => text()();
  DateTimeColumn get date     => dateTime()();
  IntColumn  get steps        => integer().withDefault(const Constant(0))();
  RealColumn get userWeight   => real()();
  RealColumn get userHeightCm => real()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// جدول النوم
class SleepRecordsTable extends Table {
  @override
  String get tableName => 'sleep_records';

  TextColumn get id              => text()();
  TextColumn get userId          => text()();
  DateTimeColumn get date        => dateTime()();
  IntColumn  get durationHours   => integer().withDefault(const Constant(0))();
  IntColumn  get durationMinutes => integer().withDefault(const Constant(0))();
  TextColumn get quality         => text().withDefault(const Constant('fair'))();
  DateTimeColumn get updatedAt   => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// جدول القياسات الجسدية
class MeasurementsTable extends Table {
  @override
  String get tableName => 'measurements';

  TextColumn get id             => text()();
  TextColumn get userId         => text()();
  DateTimeColumn get date       => dateTime()();
  RealColumn get weight         => real().nullable()();
  RealColumn get height         => real().nullable()();
  RealColumn get chest          => real().nullable()();
  RealColumn get waist          => real().nullable()();
  RealColumn get hip            => real().nullable()();
  RealColumn get neck           => real().nullable()();
  RealColumn get bodyFatPercent => real().nullable()();
  DateTimeColumn get updatedAt  => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// جدول رسائل الشات
class ChatMessagesTable extends Table {
  @override
  String get tableName => 'chat_messages';

  TextColumn get id             => text()();
  TextColumn get conversationId => text()();
  TextColumn get senderId       => text()();
  TextColumn get senderRole     => text()();
  TextColumn get content        => text()();
  DateTimeColumn get sentAt     => dateTime()();
  TextColumn get messageType    => text().withDefault(const Constant('text'))();
  TextColumn get mediaUrl       => text().nullable()();
  TextColumn get replyToId      => text().nullable()();
  TextColumn get replyToContent => text().nullable()();
  BoolColumn get isDeleted      => boolean().withDefault(const Constant(false))();
  BoolColumn get isEdited       => boolean().withDefault(const Constant(false))();
  DateTimeColumn get editedAt   => dateTime().nullable()();
  DateTimeColumn get readAt     => dateTime().nullable()();
  TextColumn get reactionsJson  => text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// جدول المحادثات
class ConversationsTable extends Table {
  @override
  String get tableName => 'conversations';

  TextColumn get id                  => text()();
  TextColumn get participantIdsJson  => text().withDefault(const Constant('[]'))();
  TextColumn get participantRolesJson => text().withDefault(const Constant('[]'))();
  TextColumn get lastMessageContent  => text().nullable()();
  DateTimeColumn get lastMessageAt   => dateTime().nullable()();
  IntColumn  get unreadCount         => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt       => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// جدول طلبات الاشتراك
class SubscriptionRequestsTable extends Table {
  @override
  String get tableName => 'subscription_requests';

  TextColumn get id               => text()();
  TextColumn get userId           => text()();
  TextColumn get userName         => text()();
  TextColumn get planId           => text()();
  TextColumn get requestType      => text().withDefault(const Constant('new'))();
  TextColumn get paymentImageUrl  => text()();
  TextColumn get status           => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt    => dateTime()();
  TextColumn get reviewedBy       => text().nullable()();
  DateTimeColumn get reviewedAt   => dateTime().nullable()();
  TextColumn get rejectionReason  => text().nullable()();
  IntColumn  get approvedDurationDays => integer().nullable()();
  DateTimeColumn get startDate    => dateTime().nullable()();
  DateTimeColumn get expiresAt    => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// جدول خطط الاشتراك
class SubscriptionPlansTable extends Table {
  @override
  String get tableName => 'subscription_plans';

  TextColumn get id          => text()();
  TextColumn get nameAr      => text()();
  TextColumn get nameEn      => text()();
  RealColumn get price       => real()();
  TextColumn get featuresJson => text().withDefault(const Constant('[]'))();
  BoolColumn get isActive    => boolean().withDefault(const Constant(true))();
  IntColumn  get durationDays => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// جدول طلبات تغيير البرنامج
class ProgramChangeRequestsTable extends Table {
  @override
  String get tableName => 'program_change_requests';

  TextColumn get id               => text()();
  TextColumn get userId           => text()();
  TextColumn get userName         => text()();
  TextColumn get requestedProgram => text()();
  TextColumn get reason           => text()();
  TextColumn get status           => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt    => dateTime()();
  DateTimeColumn get reviewedAt   => dateTime().nullable()();
  TextColumn get rejectionReason  => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ═══════════════════════════════════════════════════════════
//  DATABASE CLASS
// ═══════════════════════════════════════════════════════════

@DriftDatabase(tables: [
  UsersTable,
  WorkoutLogsTable,
  ExercisesTable,
  FoodItemsTable,
  MealEntriesTable,
  StepsTable,
  SleepRecordsTable,
  MeasurementsTable,
  ChatMessagesTable,
  ConversationsTable,
  SubscriptionRequestsTable,
  SubscriptionPlansTable,
  ProgramChangeRequestsTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // سيتم إضافة migrations هنا عند تغيير الـ Schema
        },
      );
}

/// فتح اتصال قاعدة البيانات
QueryExecutor _openConnection() {
  return driftDatabase(name: 'tobest_db');
}

// ═══════════════════════════════════════════════════════════
//  RIVERPOD PROVIDER
// ═══════════════════════════════════════════════════════════

/// مزود قاعدة البيانات — Singleton
@riverpod
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}
