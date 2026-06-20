// apps/tobest/lib/router.dart
// C-5:  import نُقل للأعلى
// C-13: 5 مسارات مفقودة أُضيفت
// C-14: AppRoutes.chat مُصحَّح
// W-9:  reset-password named route أُضيف
// W-12: N-2: SlideTransitionObserver نُظِّف

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/config/app_config.dart';
import 'package:shared/domain/entities/user_entity.dart';
import 'package:shared/infrastructure/secure_screen_service.dart';
import 'package:tobest/features/ai/presentation/screens/ai_coach_screen.dart';
import 'package:tobest/features/auth/presentation/providers/auth_provider.dart';
import 'package:tobest/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:tobest/features/auth/presentation/screens/google_completion_screen.dart';
import 'package:tobest/features/auth/presentation/screens/login_screen.dart';
import 'package:tobest/features/auth/presentation/screens/otp_screen.dart';
import 'package:tobest/features/auth/presentation/screens/register_screen.dart';
import 'package:tobest/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:tobest/features/auth/presentation/screens/splash_screen.dart';
import 'package:tobest/features/auth/presentation/screens/subscription_expired_screen.dart';
import 'package:tobest/features/auth/presentation/screens/subscription_pending_screen.dart';
import 'package:tobest/features/auth/presentation/screens/subscription_rejected_screen.dart';
import 'package:tobest/features/chat/presentation/screens/chat_screen.dart';
import 'package:tobest/features/chat/presentation/screens/conversations_screen.dart';
import 'package:tobest/features/devices/presentation/screens/devices_screen.dart';
import 'package:tobest/features/health/presentation/screens/health_screen.dart';
import 'package:tobest/features/health/presentation/screens/measurements_screen.dart';
import 'package:tobest/features/health/presentation/screens/sleep_log_screen.dart';
import 'package:tobest/features/home/presentation/screens/home_screen.dart';
import 'package:tobest/features/home/presentation/screens/main_shell.dart';
import 'package:tobest/features/nutrition/presentation/screens/nutrition_screen.dart';
import 'package:tobest/features/progress/presentation/screens/progress_screen.dart';
import 'package:tobest/features/settings/presentation/screens/settings_screen.dart';
import 'package:tobest/features/subscription/presentation/screens/subscription_screen.dart';
import 'package:tobest/features/workout/presentation/screens/workout_screen.dart';

part 'router.g.dart';

abstract class AppRoutes {
  static const splash               = '/';
  static const login                = '/login';
  static const register             = '/register';
  static const forgotPassword       = '/forgot-password';
  static const otp                  = '/otp';
  static const resetPassword        = '/reset-password'; // W-9: named route
  static const googleCompletion     = '/google-completion';
  static const subscriptionPending  = '/subscription-pending';
  static const subscriptionRejected = '/subscription-rejected';
  static const subscriptionExpired  = '/subscription-expired';
  static const home                 = '/home';
  static const workout              = '/workout';
  static const nutrition            = '/nutrition';
  static const progress             = '/progress';
  static const conversations        = '/conversations';
  static const chat                 = '/conversations/chat/:conversationId'; // C-14 FIXED
  static const aiCoach              = '/ai-coach';
  static const settings             = '/settings';
  static const subscription         = '/subscription';
  static const health               = '/health';
  static const devices              = '/devices';   // C-13
  static const sleepLog             = '/sleep-log'; // C-13
  static const measurements         = '/measurements'; // C-13
  static const changePassword       = '/change-password'; // C-13
}

@riverpod
GoRouter router(Ref ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: AppConfig.isDebug,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final user     = authState.valueOrNull;

      if (location == AppRoutes.splash) return null;

      final publicRoutes = [
        AppRoutes.login, AppRoutes.register, AppRoutes.forgotPassword,
        AppRoutes.otp,   AppRoutes.resetPassword, AppRoutes.googleCompletion,
      ];
      final isPublic = publicRoutes.contains(location);

      if (user == null) return isPublic ? null : AppRoutes.login;
      if (!user.canAccessToBest) {
        ref.read(authStateProvider.notifier).logout();
        return AppRoutes.login;
      }
      if (isPublic) return null;

      switch (user.subscriptionStatus) {
        case SubscriptionStatus.pending:
          if (location != AppRoutes.subscriptionPending) return AppRoutes.subscriptionPending;
        case SubscriptionStatus.rejected:
          if (location != AppRoutes.subscriptionRejected) return AppRoutes.subscriptionRejected;
        case SubscriptionStatus.expired:
          if (location != AppRoutes.subscriptionExpired) return AppRoutes.subscriptionExpired;
        default:
          break;
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash,               builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.login,                builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.register,             builder: (_, __) => const RegisterScreen()),
      GoRoute(path: AppRoutes.forgotPassword,       builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: AppRoutes.otp,                  builder: (_, s) => OtpScreen(email: s.extra as String? ?? '')),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: 'reset-password',                     // W-9: named route
        builder: (_, s) {
          final extra = s.extra as Map<String, dynamic>? ?? {};
          return ResetPasswordScreen(email: extra['email'] as String? ?? '');
        },
      ),
      GoRoute(path: AppRoutes.googleCompletion,     builder: (_, __) => const GoogleCompletionScreen()),
      GoRoute(path: AppRoutes.subscriptionPending,  builder: (_, __) => const SubscriptionPendingScreen()),
      GoRoute(path: AppRoutes.subscriptionRejected, builder: (_, __) => const SubscriptionRejectedScreen()),
      GoRoute(path: AppRoutes.subscriptionExpired,  builder: (_, __) => const SubscriptionExpiredScreen()),
      GoRoute(path: AppRoutes.aiCoach,              builder: (_, __) => const AiCoachScreen()),
      GoRoute(path: AppRoutes.settings,             builder: (_, __) => const SettingsScreen()),
      GoRoute(path: AppRoutes.subscription,         builder: (_, __) => const SubscriptionScreen()),
      GoRoute(path: AppRoutes.health,               builder: (_, __) => const HealthScreen()),
      GoRoute(path: AppRoutes.devices,              builder: (_, __) => const DevicesScreen()),      // C-13
      GoRoute(path: AppRoutes.sleepLog,             builder: (_, __) => const SleepLogScreen()),     // C-13
      GoRoute(path: AppRoutes.measurements,         builder: (_, __) => const MeasurementsScreen()), // C-13
      GoRoute(path: AppRoutes.changePassword,       builder: (_, __) => const ChangePasswordScreen()), // C-13
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.home,      builder: (_, __) => const HomeScreen()),
          GoRoute(path: AppRoutes.workout,   builder: (_, __) => const WorkoutScreen()),
          GoRoute(path: AppRoutes.nutrition, builder: (_, __) => const NutritionScreen()),
          GoRoute(path: AppRoutes.progress,  builder: (_, __) => const ProgressScreen()),
          GoRoute(
            path: AppRoutes.conversations,
            builder: (_, __) => const ConversationsScreen(),
            routes: [
              GoRoute(
                path: 'chat/:conversationId',
                builder: (_, s) => ChatScreen(conversationId: s.pathParameters['conversationId']!),
              ),
            ],
          ),
        ],
      ),
    ],
    // تطبيق FLAG_SECURE مركزياً على الشاشات الحساسة (AppConfig.secureRoutes)
    observers: [SecureRouteObserver()],
  );
}

/// Observer يُفعِّل/يُعطِّل FLAG_SECURE تلقائياً عند الدخول/الخروج
/// من أي مسار مذكور في [AppConfig.secureRoutes]
///
/// يعمل بالتكامل مع [SecureScreenService] المُستخدَم مباشرة في OtpScreen —
/// كلاهما idempotent (تفعيل المُفعَّل مسبقاً لا يسبب ضرراً) لذا لا تعارض
class SecureRouteObserver extends NavigatorObserver {
  void _syncFlag(Route<dynamic>? route) {
    final name = route?.settings.name ?? '';
    final isSecure = AppConfig.secureRoutes.any((r) => name.startsWith(r));
    if (isSecure) {
      SecureScreenService.enable();
    } else {
      SecureScreenService.disable();
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _syncFlag(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _syncFlag(previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => _syncFlag(newRoute);
}

// N-2: ChangePasswordScreen stub داخل router بدل splash
class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Change Password')),
    body: const Center(child: Text('Change Password Screen')),
  );
}
