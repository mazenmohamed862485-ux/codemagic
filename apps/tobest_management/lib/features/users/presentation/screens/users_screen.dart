// apps/tobest_management/lib/features/users/presentation/screens/users_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/domain/entities/user_entity.dart';
import 'package:shared/infrastructure/gas_client.dart';

part 'users_screen.g.dart';

@riverpod
Future<List<UserEntity>> allUsers(Ref ref, {String? search, String? roleFilter}) async {
  final gas  = await ref.read(gasClientProvider.future);
  final resp = await gas.get<Map<String, dynamic>>(
    '/admin/users',
    queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (roleFilter != null) 'role': roleFilter,
    },
  );
  final list = resp.data?['users'] as List<dynamic>? ?? [];
  return list.map((u) => _parseUser(u as Map<String, dynamic>)).toList();
}

UserEntity _parseUser(Map<String, dynamic> data) => UserEntity(
  id:                 data['id'] as String? ?? '',
  email:              data['email'] as String? ?? '',
  role:               data['role'] as String? ?? AppRole.user,
  name:               data['name'] as String? ?? '',
  subscriptionStatus: SubscriptionStatus.values.firstWhere(
    (s) => s.name == data['subscriptionStatus'],
    orElse: () => SubscriptionStatus.pending,
  ),
  subscriptionPlan:   data['subscriptionPlan'] as String?,
  isBanned:           data['isBanned'] as bool? ?? false,
  assignedCoachId:    data['assignedCoachId'] as String?,
  registeredDevices:  List<String>.from(data['registeredDevices'] as List? ?? []),
  maxDevices:         data['maxDevices'] as int? ?? 1,
  createdAt:          data['createdAt'] != null
      ? DateTime.tryParse(data['createdAt'] as String)
      : null,
);

/// شاشة المستخدمين — MANAGER + SUPPORT
class UsersScreen extends HookConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchCtrl  = useTextEditingController();
    final search      = useState('');
    final roleFilter  = useState<String?>(null);
    final theme       = Theme.of(context);
    final isRtl       = Directionality.of(context) == TextDirection.rtl;

    useEffect(() {
      searchCtrl.addListener(() => search.value = searchCtrl.text);
      return searchCtrl.removeListener;
    }, const []);

    final usersAsync = ref.watch(
      allUsersProvider(search: search.value, roleFilter: roleFilter.value),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(isRtl ? 'المستخدمون' : 'Users'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.base, 0, AppSpacing.base, AppSpacing.sm),
            child: TextField(
              controller: searchCtrl,
              decoration: InputDecoration(
                hintText:  isRtl ? 'بحث بالاسم أو الإيميل...' : 'Search by name or email...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: search.value.isNotEmpty
                    ? IconButton(
                        icon:      const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          searchCtrl.clear();
                          search.value = '';
                        },
                      )
                    : null,
                isDense:   true,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── فلاتر الدور ────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical:   AppSpacing.sm,
            ),
            child: Row(
              children: [
                null, AppRole.user, AppRole.coach,
              ].map((r) {
                final label = r == null
                    ? (isRtl ? 'الكل' : 'All')
                    : r == AppRole.user
                        ? (isRtl ? 'مستخدمون' : 'Users')
                        : (isRtl ? 'كوتشات' : 'Coaches');
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    label:      Text(label),
                    selected:   roleFilter.value == r,
                    onSelected: (_) => roleFilter.value = r,
                  ),
                );
              }).toList(),
            ),
          ),

          // ── قائمة المستخدمين ───────────────────────────
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:   (e, _) => Center(child: Text('$e')),
              data: (users) {
                if (users.isEmpty) {
                  return Center(
                    child: Text(
                      isRtl ? 'لا مستخدمون' : 'No users found',
                    ),
                  );
                }
                return ListView.separated(
                  padding:          const EdgeInsets.all(AppSpacing.base),
                  itemCount:        users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (ctx, i) {
                    final user = users[i];
                    return Card(
                      child: ListTile(
                        onTap: () => context.push('/users/${user.id}'),
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  (user.isBanned ? AppColors.error : theme.colorScheme.primary)
                                      .withOpacity(0.1),
                              child: Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: user.isBanned
                                      ? AppColors.error
                                      : theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (user.isBanned)
                              Positioned(
                                right: 0, bottom: 0,
                                child: Container(
                                  width:  12, height: 12,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title:    Text(user.name),
                        subtitle: Text(user.email),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _StatusBadge(status: user.subscriptionStatus, isRtl: isRtl),
                            Text(
                              user.role,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.4),
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
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.isRtl});
  final SubscriptionStatus status;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      SubscriptionStatus.active   => (AppColors.success, isRtl ? 'نشط'    : 'Active'),
      SubscriptionStatus.pending  => (AppColors.warning, isRtl ? 'معلق'   : 'Pending'),
      SubscriptionStatus.rejected => (AppColors.error,   isRtl ? 'مرفوض'  : 'Rejected'),
      SubscriptionStatus.expired  => (AppColors.accent5, isRtl ? 'منتهي'  : 'Expired'),
      SubscriptionStatus.guest    => (AppColors.info,    isRtl ? 'زائر'   : 'Guest'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          color:      color,
          fontWeight: FontWeight.w600,
          fontSize:   AppTypography.labelSm,
        ),
      ),
    );
  }
}
