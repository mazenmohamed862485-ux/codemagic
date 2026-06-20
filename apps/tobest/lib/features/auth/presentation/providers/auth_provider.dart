// apps/tobest/lib/features/auth/presentation/providers/auth_provider.dart
// C-5:  imports نُقلت للأعلى
// C-16: token يُرسَل مع كل طلب GAS
// M-10: device_info_plus حقيقي

import 'dart:developer' as developer;
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/config/app_config.dart';
import 'package:shared/domain/entities/user_entity.dart';
import 'package:shared/infrastructure/background_service.dart';
import 'package:shared/infrastructure/gas_client.dart';

part 'auth_provider.g.dart';

@riverpod
class AuthState extends _$AuthState {
  static const _kUserIdKey    = 'current_user_id';
  static const _kUserTokenKey = 'current_user_token';

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
      return _parseUser(resp.data ?? {});
    } catch (e) {
      developer.log('Load user failed: $e', name: 'AuthProvider');
      return null;
    }
  }

  Future<void> loginWithEmail({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final gas        = await ref.read(gasClientProvider.future);
      final deviceInfo = await _getDeviceInfo();

      final resp = await gas.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'email':      email,
          'password':   password,
          'deviceId':   deviceInfo['deviceId'],
          'deviceName': deviceInfo['deviceName'],
          'platform':   deviceInfo['platform'],
        },
      );

      final data = resp.data ?? {};
      _validateRole(data['role'] as String?);

      // C-16: حفظ وإرسال الـ token
      final token = data['token'] as String?;
      if (token != null) {
        await gas.updateToken(token);
        await _storage.write(key: _kUserTokenKey, value: token);
      }

      final user = _parseUser(data);
      await _storage.write(key: _kUserIdKey, value: user.id);
      await _startBackgroundTasks(user.id);
      return user;
    });
  }

  Future<void> loginWithGoogle(String idToken) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final gas        = await ref.read(gasClientProvider.future);
      final deviceInfo = await _getDeviceInfo();

      final resp = await gas.post<Map<String, dynamic>>(
        '/auth/google',
        data: {
          'idToken':    idToken,
          'deviceId':   deviceInfo['deviceId'],
          'deviceName': deviceInfo['deviceName'],
          'platform':   deviceInfo['platform'],
        },
      );

      final data  = resp.data ?? {};
      _validateRole(data['role'] as String?);
      final token = data['token'] as String?;
      if (token != null) {
        await gas.updateToken(token);
        await _storage.write(key: _kUserTokenKey, value: token);
      }

      final user = _parseUser(data);
      await _storage.write(key: _kUserIdKey, value: user.id);
      return user;
    });
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required double height,
    required double weight,
    required int age,
    required String gender,
    String? referralCode,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final gas  = await ref.read(gasClientProvider.future);
      final resp = await gas.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'name':         name,
          'email':        email,
          'password':     password,
          'phone':        phone,
          'height':       height,
          'weight':       weight,
          'age':          age,
          'gender':       gender,
          'referralCode': referralCode,
        },
      );
      final data  = resp.data ?? {};
      final token = data['token'] as String?;
      if (token != null) {
        await gas.updateToken(token);
        await _storage.write(key: _kUserTokenKey, value: token);
      }
      final user = _parseUser(data);
      await _storage.write(key: _kUserIdKey, value: user.id);
      return user;
    });
  }

  Future<void> logout() async {
    final userId = state.valueOrNull?.id;
    state        = const AsyncData(null);

    final gas = await ref.read(gasClientProvider.future);
    await gas.updateToken(null);
    await _storage.delete(key: _kUserIdKey);
    await _storage.delete(key: _kUserTokenKey);

    if (userId != null) await BackgroundService.cancelForUser(userId);
  }

  void _validateRole(String? role) {
    if (role == null) throw Exception('Role not specified');
    if (!AppConfig.toBestRoles.contains(role)) {
      throw Exception('Access denied: $role cannot access TO Best');
    }
  }

  Future<void> _startBackgroundTasks(String userId) async {
    await BackgroundService.scheduleChatFetch(userId);
    await BackgroundService.scheduleHealthSync(userId);
    await BackgroundService.scheduleWeeklyCleanup(userId);
  }

  /// M-10: معلومات الجهاز الحقيقية
  Future<Map<String, String>> _getDeviceInfo() async {
    final plugin = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        return {
          'deviceId':   info.id,
          'deviceName': '${info.manufacturer} ${info.model}',
          'platform':   'android',
        };
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        return {
          'deviceId':   info.identifierForVendor ?? 'ios_unknown',
          'deviceName': info.model,
          'platform':   'ios',
        };
      }
    } catch (_) {}
    return {
      'deviceId':   'device_${DateTime.now().millisecondsSinceEpoch}',
      'deviceName': 'Unknown',
      'platform':   'android',
    };
  }

  UserEntity _parseUser(Map<String, dynamic> d) => UserEntity(
        id:                 d['id'] as String? ?? '',
        email:              d['email'] as String? ?? '',
        role:               d['role'] as String? ?? AppRole.user,
        name:               d['name'] as String? ?? '',
        phone:              d['phone'] as String?,
        height:             (d['height'] as num?)?.toDouble(),
        weight:             (d['weight'] as num?)?.toDouble(),
        age:                d['age'] as int?,
        gender:             d['gender'] as String?,
        subscriptionStatus: _parseStatus(d['subscriptionStatus'] as String?),
        subscriptionPlan:   d['subscriptionPlan'] as String?,
        assignedCoachId:    d['assignedCoachId'] as String?,
        referralCode:       d['referralCode'] as String?,
        preferredLanguage:  d['preferredLanguage'] as String? ?? 'ar',
        selectedTheme:      d['selectedTheme'] as String? ?? 'auto',
      );

  static SubscriptionStatus _parseStatus(String? s) =>
      SubscriptionStatus.values.firstWhere(
        (e) => e.name == s,
        orElse: () => SubscriptionStatus.pending,
      );
}
