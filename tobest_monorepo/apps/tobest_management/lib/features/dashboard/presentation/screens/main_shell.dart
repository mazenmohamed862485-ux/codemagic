// apps/tobest_management/lib/features/dashboard/presentation/screens/main_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/config/app_config.dart';
import 'package:shared/design/tokens.dart';
import 'package:tobest_management/features/auth/presentation/providers/mgmt_auth_provider.dart';
import 'package:tobest_management/router.dart';

/// Shell الإدارة مع التنقل الجانبي (Rail) للأجهزة الكبيرة
/// والـ Bottom Navigation للموبايل
class MgmtMainShell extends ConsumerWidget {
  const MgmtMainShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user     = ref.watch(mgmtAuthStateProvider).valueOrNull;
    final location = GoRouterState.of(context).matchedLocation;
    final isRtl    = Directionality.of(context) == TextDirection.rtl;

    // التبويبات بناءً على الدور
    final tabs = _buildTabs(user?.role, isRtl);
    final currentIdx = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIdx.clamp(0, tabs.length - 1),
        onDestinationSelected: (i) => _navigate(context, tabs[i].route),
        destinations: tabs.map((t) => NavigationDestination(
          icon:         Icon(t.icon),
          selectedIcon: Icon(t.selectedIcon),
          label:        t.label,
        )).toList(),
      ),
    );
  }

  List<_NavTab> _buildTabs(String? role, bool isRtl) {
    final isManager       = role == AppRole.manager;
    final isSupport       = role == AppRole.support;
    final isSubscriptions = role == AppRole.subscriptions;

    return [
      _NavTab(
        route:        MgmtRoutes.dashboard,
        icon:         Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label:        isRtl ? 'الرئيسية' : 'Dashboard',
      ),

      // المستخدمون — MANAGER + SUPPORT
      if (isManager || isSupport)
        _NavTab(
          route:        MgmtRoutes.users,
          icon:         Icons.people_outlined,
          selectedIcon: Icons.people,
          label:        isRtl ? 'المستخدمون' : 'Users',
        ),

      // الاشتراكات — MANAGER + SUBSCRIPTIONS
      if (isManager || isSubscriptions)
        _NavTab(
          route:        MgmtRoutes.subscriptions,
          icon:         Icons.card_membership_outlined,
          selectedIcon: Icons.card_membership,
          label:        isRtl ? 'الاشتراكات' : 'Subscriptions',
        ),

      // الكوتشات — MANAGER فقط
      if (isManager)
        _NavTab(
          route:        MgmtRoutes.coaches,
          icon:         Icons.fitness_center_outlined,
          selectedIcon: Icons.fitness_center,
          label:        isRtl ? 'الكوتشات' : 'Coaches',
        ),

      _NavTab(
        route:        MgmtRoutes.settings,
        icon:         Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label:        isRtl ? 'الإعدادات' : 'Settings',
      ),
    ];
  }

  int _locationToIndex(String location) {
    if (location.startsWith('/users'))         return 1;
    if (location.startsWith('/subscriptions')) return 2;
    if (location.startsWith('/coaches'))       return 3;
    if (location.startsWith('/settings'))      return 4;
    return 0;
  }

  void _navigate(BuildContext context, String route) => context.go(route);
}

class _NavTab {
  const _NavTab({
    required this.route,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
  final String route;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
