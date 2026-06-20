// apps/tobest/lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/design/tokens.dart';
import 'package:tobest/features/auth/presentation/providers/auth_provider.dart';
import 'package:tobest/features/home/presentation/widgets/daily_summary_card.dart';
import 'package:tobest/features/home/presentation/widgets/quick_actions_row.dart';
import 'package:tobest/features/home/presentation/widgets/streak_heatmap.dart';
import 'package:tobest/features/home/presentation/widgets/today_workout_card.dart';
import 'package:tobest/router.dart';

/// الشاشة الرئيسية — Dashboard المستخدم
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user  = ref.watch(authStateProvider).valueOrNull;
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isRtl
              ? 'مرحباً ${user?.name.split(' ').first ?? ''} 👋'
              : 'Hello ${user?.name.split(' ').first ?? ''} 👋',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          // ── زر الذكاء الاصطناعي ──────────────────────────
          IconButton(
            icon: const Icon(Icons.psychology_outlined),
            tooltip: isRtl ? 'مدرب الذكاء الاصطناعي' : 'AI Coach',
            onPressed: () => context.push(AppRoutes.aiCoach),
          ),

          // ── زر الإعدادات ─────────────────────────────────
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          // إعادة تحميل جميع البيانات
          ref.invalidate(authStateProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.base),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── ملخص اليوم ──────────────────────────────
                  const DailySummaryCard(),
                  const SizedBox(height: AppSpacing.md),

                  // ── الإجراءات السريعة ────────────────────────
                  const QuickActionsRow(),
                  const SizedBox(height: AppSpacing.md),

                  // ── تمرين اليوم ──────────────────────────────
                  const TodayWorkoutCard(),
                  const SizedBox(height: AppSpacing.md),

                  // ── Streak Heatmap ────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.base),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isRtl ? 'سجل الانتظام' : 'Consistency',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const StreakHeatmap(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxxl),
                ]),
              ),
            ),
          ],
        ),
      ),

      // ── FAB: تسجيل وجبة سريع ──────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoutes.nutrition),
        icon:  const Icon(Icons.add),
        label: Text(isRtl ? 'تسجيل وجبة' : 'Log Meal'),
      ),
    );
  }
}
