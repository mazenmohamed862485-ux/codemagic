// apps/tobest_management/lib/features/auth/presentation/providers/mgmt_auth_provider.dart

import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/config/app_config.dart';
import 'package:shared/domain/entities/user_entity.dart';
import 'package:shared/infrastructure/background_service.dart';
import 'package:shared/infrastructure/gas_client.dart';

part 'mgmt_auth_provider.g.dart';

@riverpod
class MgmtAuthState extends _$MgmtAuthState {
  static const _kUserIdKey = 'mgmt_user_id';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  @override
  FutureOr<UserEntity?> build() async => _loadCurrentUser();

  Future<UserEntity?> _loadCurrentUser() async {
    try {
      final userId = await _storage.read(key: _kUserIdKey);
      if (userId == null) return null;

      final gas  = await ref.read(gasClientProvider.future);
      final resp = await gas.get<Map<String, dynamic>>(
        '/auth/me',
        queryParameters: {'userId': userId},
      );
      final user = _parseUser(resp.data ?? {});

      // تأكيد دور الإدارة
      if (!AppConfig.managementRoles.contains(user.role)) {
        await _storage.delete(key: _kUserIdKey);
        return null;
      }
      return user;
    } catch (e) {
      developer.log('MGMT load user failed: $e', name: 'MgmtAuth');
      return null;
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final gas  = await ref.read(gasClientProvider.future);
      final resp = await gas.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'email':      email,
          'password':   password,
          'deviceId':   'mgmt_device',
          'deviceName': 'Management App',
          'platform':   'android',
        },
      );

      final data = resp.data ?? {};
      final role = data['role'] as String?;

      // تحقق مزدوج: دور إداري فقط
      if (role == null || !AppConfig.managementRoles.contains(role)) {
        throw Exception(
          'Access denied: role $role cannot access Management app',
        );
      }

      final user = _parseUser(data);
      await _storage.write(key: _kUserIdKey, value: user.id);
      return user;
    });
  }

  Future<void> logout() async {
    final userId = state.valueOrNull?.id;
    state = const AsyncData(null);
    await _storage.delete(key: _kUserIdKey);
    if (userId != null) await BackgroundService.cancelForUser(userId);
  }

  UserEntity _parseUser(Map<String, dynamic> data) => UserEntity(
        id:                 data['id'] as String? ?? '',
        email:              data['email'] as String? ?? '',
        role:               data['role'] as String? ?? AppRole.manager,
        name:               data['name'] as String? ?? '',
        subscriptionStatus: SubscriptionStatus.active,
        preferredLanguage:  data['preferredLanguage'] as String? ?? 'ar',
        selectedTheme:      data['selectedTheme'] as String? ?? 'auto',
      );
}
