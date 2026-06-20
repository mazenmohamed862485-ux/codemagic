// apps/tobest_management/lib/router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/config/app_config.dart';
import 'package:shared/domain/entities/user_entity.dart';
import 'package:tobest_management/features/auth/presentation/providers/mgmt_auth_provider.dart';
import 'package:tobest_management/features/auth/presentation/screens/mgmt_login_screen.dart';
import 'package:tobest_management/features/auth/presentation/screens/mgmt_splash_screen.dart';
import 'package:tobest_management/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:tobest_management/features/dashboard/presentation/screens/main_shell.dart';
import 'package:tobest_management/features/subscriptions/presentation/screens/subscriptions_screen.dart';
import 'package:tobest_management/features/users/presentation/screens/users_screen.dart';
import 'package:tobest_management/features/users/presentation/screens/user_detail_screen.dart';
import 'package:tobest_management/features/coaches/presentation/screens/coaches_screen.dart';
import 'package:tobest_management/features/settings/presentation/screens/mgmt_settings_screen.dart';

part 'router.g.dart';

abstract class MgmtRoutes {
  static const splash    = '/';
  static const login     = '/login';
  static const dashboard = '/dashboard';
  static const users     = '/users';
  static const userDetail = '/users/:userId';
  static const subscriptions = '/subscriptions';
  static const coaches   = '/coaches';
  static const settings  = '/settings';
}

@riverpod
GoRouter mgmtRouter(Ref ref) {
  final authState = ref.watch(mgmtAuthStateProvider);

  return GoRouter(
    initialLocation: MgmtRoutes.splash,
    debugLogDiagnostics: AppConfig.isDebug,

    redirect: (context, state) {
      final location = state.matchedLocation;
      final user     = authState.valueOrNull;

      if (location == MgmtRoutes.splash) return null;

      if (user == null) {
        return location == MgmtRoutes.login ? null : MgmtRoutes.login;
      }

      // التحقق من الأدوار — MANAGER أو SUPPORT أو SUBSCRIPTIONS فقط
      if (!user.canAccessManagement) {
        ref.read(mgmtAuthStateProvider.notifier).logout();
        return MgmtRoutes.login;
      }

      if (location == MgmtRoutes.login) return MgmtRoutes.dashboard;

      // SUPPORT لا يستطيع الوصول لشاشة الكوتشات
      if (location == MgmtRoutes.coaches && user.isSupport) {
        return MgmtRoutes.dashboard;
      }

      return null;
    },

    routes: [
      GoRoute(
        path:    MgmtRoutes.splash,
        builder: (context, state) => const MgmtSplashScreen(),
      ),
      GoRoute(
        path:    MgmtRoutes.login,
        builder: (context, state) => const MgmtLoginScreen(),
      ),

      ShellRoute(
        builder: (context, state, child) => MgmtMainShell(child: child),
        routes:  [
          GoRoute(
            path:    MgmtRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path:    MgmtRoutes.users,
            builder: (context, state) => const UsersScreen(),
            routes:  [
              GoRoute(
                path:    ':userId',
                builder: (context, state) => UserDetailScreen(
                  userId: state.pathParameters['userId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path:    MgmtRoutes.subscriptions,
            builder: (context, state) => const SubscriptionsScreen(),
          ),
          GoRoute(
            path:    MgmtRoutes.coaches,
            builder: (context, state) => const CoachesScreen(),
          ),
          GoRoute(
            path:    MgmtRoutes.settings,
            builder: (context, state) => const MgmtSettingsScreen(),
          ),
        ],
      ),
    ],
  );
}
