// apps/tobest_management/lib/features/coaches/presentation/screens/coaches_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/config/app_config.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/domain/entities/user_entity.dart';
import 'package:shared/infrastructure/gas_client.dart';

part 'coaches_screen.g.dart';

@riverpod
Future<List<UserEntity>> coaches(Ref ref) async {
  final gas  = await ref.read(gasClientProvider.future);
  final resp = await gas.get<Map<String, dynamic>>(
    '/admin/users',
    queryParameters: {'role': AppRole.coach},
  );
  final list = resp.data?['users'] as List<dynamic>? ?? [];
  return list.map((u) {
    final data = u as Map<String, dynamic>;
    return UserEntity(
      id:                 data['id'] as String? ?? '',
      email:              data['email'] as String? ?? '',
      role:               AppRole.coach,
      name:               data['name'] as String? ?? '',
      subscriptionStatus: SubscriptionStatus.active,
    );
  }).toList();
}

/// شاشة إدارة الكوتشات — MANAGER فقط
class CoachesScreen extends ConsumerWidget {
  const CoachesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coachesAsync = ref.watch(coachesProvider);
    final isRtl        = Directionality.of(context) == TextDirection.rtl;
    final theme        = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isRtl ? 'الكوتشات' : 'Coaches'),
        actions: [
          IconButton(
            icon:      const Icon(Icons.person_add),
            tooltip:   isRtl ? 'إضافة كوتش' : 'Add Coach',
            onPressed: () => _showAddCoachDialog(context, ref, isRtl),
          ),
        ],
      ),
      body: coachesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('$e')),
        data: (coaches) {
          if (coaches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center,
                    size:  80,
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    isRtl ? 'لا كوتشات مسجلون' : 'No coaches registered',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding:          const EdgeInsets.all(AppSpacing.base),
            itemCount:        coaches.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (ctx, i) {
              final coach = coaches[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        theme.colorScheme.primary.withOpacity(0.1),
                    child: Text(
                      coach.name.isNotEmpty
                          ? coach.name[0].toUpperCase()
                          : 'C',
                      style: TextStyle(
                        color:      theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title:    Text(coach.name),
                  subtitle: Text(coach.email),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) =>
                        _handleCoachAction(context, ref, coach, action, isRtl),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'view_users',
                        child: Text(
                            isRtl ? 'عرض المستخدمين' : 'View Users'),
                      ),
                      PopupMenuItem(
                        value: 'remove',
                        child: Text(
                          isRtl ? 'إزالة الكوتش' : 'Remove Coach',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddCoachDialog(
      BuildContext context, WidgetRef ref, bool isRtl) {
    showDialog(
      context: context,
      builder: (ctx) => _AddCoachDialog(isRtl: isRtl, ref: ref),
    );
  }

  void _handleCoachAction(
    BuildContext context,
    WidgetRef ref,
    UserEntity coach,
    String action,
    bool isRtl,
  ) {
    switch (action) {
      case 'view_users':
        break;
      case 'remove':
        _removeCoach(context, ref, coach, isRtl);
    }
  }

  Future<void> _removeCoach(
    BuildContext context,
    WidgetRef ref,
    UserEntity coach,
    bool isRtl,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isRtl ? 'إزالة الكوتش؟' : 'Remove Coach?'),
        content: Text(coach.name),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child:     Text(isRtl ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            style:     FilledButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () => ctx.pop(true),
            child:     Text(isRtl ? 'إزالة' : 'Remove'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      final gas = await ref.read(gasClientProvider.future);
      await gas.post('/admin/users/${coach.id}/role', data: {
        'role': AppRole.user,
      });
      ref.invalidate(coachesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text('$e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

class _AddCoachDialog extends StatefulWidget {
  const _AddCoachDialog({required this.isRtl, required this.ref});
  final bool isRtl;
  final WidgetRef ref;

  @override
  State<_AddCoachDialog> createState() => _AddCoachDialogState();
}

class _AddCoachDialogState extends State<_AddCoachDialog> {
  final _emailCtrl = TextEditingController();
  bool _loading    = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isRtl ? 'إضافة كوتش' : 'Add Coach'),
      content: TextField(
        controller:   _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: widget.isRtl ? 'إيميل المستخدم' : 'User Email',
          hintText:  'coach@example.com',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child:     Text(widget.isRtl ? 'إلغاء' : 'Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white,
                  ),
                )
              : Text(widget.isRtl ? 'إضافة' : 'Add'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_emailCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);

    try {
      final gas = await widget.ref.read(gasClientProvider.future);
      await gas.post('/admin/users/promote-coach', data: {
        'email': _emailCtrl.text.trim(),
      });

      widget.ref.invalidate(coachesProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text('$e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }
}
