// apps/tobest_management/lib/features/users/presentation/screens/user_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/domain/entities/user_entity.dart';
import 'package:shared/infrastructure/gas_client.dart';
import 'package:tobest_management/features/auth/presentation/providers/mgmt_auth_provider.dart';
import 'package:tobest_management/features/users/presentation/screens/users_screen.dart'
    show _parseUser;

part 'user_detail_screen.g.dart';

@riverpod
Future<UserEntity> userDetail(Ref ref, String userId) async {
  final gas  = await ref.read(gasClientProvider.future);
  final resp = await gas.get<Map<String, dynamic>>('/admin/users/$userId');
  return _parseUser(resp.data?['user'] as Map<String, dynamic>? ?? {});
}

/// شاشة تفاصيل المستخدم
///
/// MANAGER: بان، تعديل أجهزة، تعيين كوتش
/// SUPPORT: عرض + إرسال طلب تعديل اشتراك
class UserDetailScreen extends ConsumerWidget {
  const UserDetailScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDetailProvider(userId));
    final me        = ref.watch(mgmtAuthStateProvider).valueOrNull;
    final theme     = Theme.of(context);
    final isRtl     = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: Text(isRtl ? 'تفاصيل المستخدم' : 'User Details'),
        actions: [
          // ── إعادة تحميل ──────────────────────────────
          IconButton(
            icon:      const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(userDetailProvider(userId)),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('$e')),
        data: (user) => ListView(
          padding: const EdgeInsets.all(AppSpacing.base),
          children: [
            // ── معلومات أساسية ──────────────────────────
            _InfoSection(
              title: isRtl ? 'المعلومات الأساسية' : 'Basic Info',
              children: [
                _InfoRow(isRtl ? 'الاسم'   : 'Name',   user.name),
                _InfoRow(isRtl ? 'الإيميل' : 'Email',  user.email),
                _InfoRow(isRtl ? 'الدور'   : 'Role',   user.role),
                _InfoRow(isRtl ? 'الطول'   : 'Height', user.height != null ? '${user.height} cm' : '—'),
                _InfoRow(isRtl ? 'الوزن'   : 'Weight', user.weight != null ? '${user.weight} kg' : '—'),
                _InfoRow(isRtl ? 'العمر'   : 'Age',    user.age != null ? '${user.age}' : '—'),
                _InfoRow(isRtl ? 'الجنس'   : 'Gender', user.gender ?? '—'),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // ── حالة الاشتراك ──────────────────────────
            _InfoSection(
              title: isRtl ? 'الاشتراك' : 'Subscription',
              children: [
                _InfoRow(isRtl ? 'الحالة'  : 'Status', user.subscriptionStatus.name),
                _InfoRow(isRtl ? 'الخطة'   : 'Plan',   user.subscriptionPlan ?? '—'),
                _InfoRow(
                  isRtl ? 'تنتهي في' : 'Expires',
                  user.subscriptionExpiresAt?.toLocal().toString().split(' ').first ?? '—',
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // ── الأجهزة ───────────────────────────────
            _InfoSection(
              title: isRtl ? 'الأجهزة' : 'Devices',
              children: [
                _InfoRow(
                  isRtl ? 'الأجهزة المسجلة' : 'Registered',
                  '${user.registeredDevices.length} / ${user.maxDevices}',
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // ── الكود الإحالي ─────────────────────────
            if (user.referralCode != null)
              _InfoSection(
                title: isRtl ? 'الإحالة' : 'Referral',
                children: [
                  _InfoRow(isRtl ? 'كود الإحالة' : 'Referral Code', user.referralCode!),
                  if (user.referredBy != null)
                    _InfoRow(isRtl ? 'أُحيل من' : 'Referred By', user.referredBy!),
                ],
              ),

            const SizedBox(height: AppSpacing.xl),

            // ── إجراءات MANAGER ──────────────────────
            if (me?.isManager ?? false) ...[
              Text(
                isRtl ? 'إجراءات المدير' : 'Manager Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color:      theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // بان / رفع البان
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor:
                      user.isBanned ? AppColors.success : AppColors.error,
                ),
                onPressed: () => _toggleBan(context, ref, user, isRtl),
                icon:      Icon(user.isBanned ? Icons.lock_open : Icons.block),
                label:     Text(
                  user.isBanned
                      ? (isRtl ? 'رفع الحظر' : 'Unban User')
                      : (isRtl ? 'حظر المستخدم' : 'Ban User'),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // تعديل عدد الأجهزة
              OutlinedButton.icon(
                onPressed: () => _editDeviceLimit(context, ref, user, isRtl),
                icon:      const Icon(Icons.devices),
                label:     Text(isRtl ? 'تعديل حد الأجهزة' : 'Edit Device Limit'),
              ),

              const SizedBox(height: AppSpacing.sm),

              // تعيين كوتش
              OutlinedButton.icon(
                onPressed: () => _assignCoach(context, ref, user, isRtl),
                icon:      const Icon(Icons.fitness_center),
                label:     Text(isRtl ? 'تعيين كوتش' : 'Assign Coach'),
              ),
            ],

            // ── إجراءات SUPPORT ──────────────────────
            if (me?.isSupport ?? false) ...[
              Text(
                isRtl ? 'إجراءات الدعم' : 'Support Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color:      theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () =>
                    _requestSubscriptionChange(context, ref, user, isRtl),
                icon:      const Icon(Icons.card_membership),
                label:     Text(
                  isRtl ? 'طلب تعديل اشتراك' : 'Request Subscription Change',
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleBan(
    BuildContext context, WidgetRef ref, UserEntity user, bool isRtl,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(user.isBanned
            ? (isRtl ? 'رفع الحظر؟' : 'Unban User?')
            : (isRtl ? 'حظر المستخدم؟' : 'Ban User?')),
        content: Text(user.name),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child:     Text(isRtl ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => ctx.pop(true),
            style:     FilledButton.styleFrom(
              backgroundColor:
                  user.isBanned ? AppColors.success : AppColors.error,
            ),
            child: Text(user.isBanned
                ? (isRtl ? 'رفع الحظر' : 'Unban')
                : (isRtl ? 'حظر' : 'Ban')),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      final gas = await ref.read(gasClientProvider.future);
      await gas.post('/admin/users/${user.id}/ban', data: {
        'ban': !user.isBanned,
      });
      ref.invalidate(userDetailProvider(userId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isRtl ? 'تم التعديل ✓' : 'Done ✓'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text('$e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  Future<void> _editDeviceLimit(
    BuildContext context, WidgetRef ref, UserEntity user, bool isRtl,
  ) async {
    final ctrl = TextEditingController(text: user.maxDevices.toString());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isRtl ? 'حد الأجهزة' : 'Device Limit'),
        content: TextField(
          controller:   ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: isRtl ? 'عدد الأجهزة' : 'Number of devices',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child:     Text(isRtl ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => ctx.pop(true),
            child:     Text(isRtl ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final limit = int.tryParse(ctrl.text) ?? user.maxDevices;
    final gas   = await ref.read(gasClientProvider.future);
    await gas.post('/admin/users/${user.id}/device-limit', data: {'maxDevices': limit});
    ref.invalidate(userDetailProvider(userId));
  }

  Future<void> _assignCoach(
    BuildContext context, WidgetRef ref, UserEntity user, bool isRtl,
  ) async {
    // في التطبيق الكامل تعرض قائمة الكوتشات
  }

  Future<void> _requestSubscriptionChange(
    BuildContext context, WidgetRef ref, UserEntity user, bool isRtl,
  ) async {
    // إرسال طلب تعديل اشتراك من SUPPORT
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color:      Theme.of(context).colorScheme.primary,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ]),
    );
  }
}
