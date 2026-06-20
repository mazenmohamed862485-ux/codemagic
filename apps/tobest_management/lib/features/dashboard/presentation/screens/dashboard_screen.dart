// apps/tobest_management/lib/features/dashboard/presentation/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/infrastructure/gas_client.dart';
import 'package:tobest_management/features/auth/presentation/providers/mgmt_auth_provider.dart';

part 'dashboard_screen.g.dart';

class _DashStats {
  const _DashStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.pendingRequests,
    required this.todayRegistrations,
    required this.monthRevenue,
  });
  final int totalUsers;
  final int activeUsers;
  final int pendingRequests;
  final int todayRegistrations;
  final double monthRevenue;
}

@riverpod
Future<_DashStats> dashboardStats(Ref ref) async {
  final gas  = await ref.read(gasClientProvider.future);
  final resp = await gas.get<Map<String, dynamic>>('/admin/dashboard/stats');
  final d    = resp.data ?? {};
  return _DashStats(
    totalUsers:         d['totalUsers'] as int? ?? 0,
    activeUsers:        d['activeUsers'] as int? ?? 0,
    pendingRequests:    d['pendingRequests'] as int? ?? 0,
    todayRegistrations: d['todayRegistrations'] as int? ?? 0,
    monthRevenue:       (d['monthRevenue'] as num?)?.toDouble() ?? 0,
  );
}

/// لوحة الإحصاءات الرئيسية
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final user       = ref.watch(mgmtAuthStateProvider).valueOrNull;
    final theme      = Theme.of(context);
    final isRtl      = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: Text(isRtl ? 'لوحة التحكم' : 'Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.base),
            child: Chip(
              avatar: const Icon(Icons.admin_panel_settings, size: 16),
              label: Text(user?.role ?? ''),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardStatsProvider),
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e, _) => Center(child: Text('$e')),
          data: (stats) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── إحصاءات ─────────────────────────────────
                Text(
                  isRtl ? 'إحصاءات سريعة' : 'Quick Stats',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing:  AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  shrinkWrap:       true,
                  physics:          const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.6,
                  children: [
                    _StatCard(
                      label: isRtl ? 'إجمالي المستخدمين' : 'Total Users',
                      value: stats.totalUsers.toString(),
                      icon:  Icons.people,
                      color: AppColors.info,
                    ),
                    _StatCard(
                      label: isRtl ? 'مستخدمون نشطون' : 'Active Users',
                      value: stats.activeUsers.toString(),
                      icon:  Icons.check_circle,
                      color: AppColors.success,
                    ),
                    _StatCard(
                      label: isRtl ? 'طلبات معلقة' : 'Pending Requests',
                      value: stats.pendingRequests.toString(),
                      icon:  Icons.hourglass_empty,
                      color: AppColors.warning,
                      urgent: stats.pendingRequests > 0,
                    ),
                    _StatCard(
                      label: isRtl ? 'تسجيلات اليوم' : "Today's Signups",
                      value: stats.todayRegistrations.toString(),
                      icon:  Icons.person_add,
                      color: AppColors.primary,
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── إيرادات الشهر (MANAGER فقط) ─────────────
                if (user?.isManager ?? false)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.base),
                      child: Row(children: [
                        Icon(Icons.attach_money,
                            color: AppColors.success, size: 32),
                        const SizedBox(width: AppSpacing.md),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isRtl ? 'إيرادات الشهر' : 'Monthly Revenue',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              '${stats.monthRevenue.toStringAsFixed(0)} ${isRtl ? 'ريال' : 'SAR'}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color:      AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.urgent = false,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: urgent ? color.withOpacity(0.08) : null,
      shape: urgent
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              side:         BorderSide(color: color.withOpacity(0.4)),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const Spacer(),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color:      color,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
