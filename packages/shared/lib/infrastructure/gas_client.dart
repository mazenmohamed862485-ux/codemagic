// packages/shared/lib/infrastructure/gas_client.dart
// C-16: إضافة Authorization: Bearer token
// W-14: إعادة تهيئة interceptors بعد updateConnectionSettings

import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/config/app_config.dart';
import 'package:shared/config/secrets.dart';

part 'gas_client.g.dart';

class GasClient {
  GasClient._(this._dio, this._storage);
  final Dio _dio;
  final FlutterSecureStorage _storage;

  static const _kGasUrlKey    = 'gas_base_url';
  static const _kGasSecretKey = 'gas_secret_key';
  static const _kGeminiKey    = 'gemini_api_key';
  static const _kUserToken    = 'current_user_token';

  static Future<GasClient> create(FlutterSecureStorage storage) async {
    final storedUrl   = await storage.read(key: _kGasUrlKey);
    final storedKey   = await storage.read(key: _kGasSecretKey);
    final storedToken = await storage.read(key: _kUserToken);

    final baseUrl   = storedUrl ?? AppSecrets.gasBaseUrl;
    final secretKey = storedKey ?? AppSecrets.gasSecretKey;

    final dio = Dio(BaseOptions(
      baseUrl:        baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {
        'Content-Type':  'application/json',
        'X-Secret-Key':  secretKey,
        if (storedToken != null)
          'Authorization': 'Bearer $storedToken', // C-16
      },
    ));

    _addInterceptors(dio);
    return GasClient._(dio, storage);
  }

  static void _addInterceptors(Dio dio) {
    dio.interceptors.clear();
    dio.interceptors.add(_RetryInterceptor(dio: dio, maxRetries: AppConfig.maxRetries));
    if (AppConfig.isDebug) {
      dio.interceptors.add(LogInterceptor(
        requestBody:  true,
        responseBody: true,
        logPrint:     (o) => developer.log(o.toString(), name: 'GAS'),
      ));
    }
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters, Options? options}) =>
      _dio.get<T>(path, queryParameters: queryParameters, options: options);

  Future<Response<T>> post<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) =>
      _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);

  Future<Response<T>> patch<T>(String path, {dynamic data, Options? options}) =>
      _dio.patch<T>(path, data: data, options: options);

  Future<Response<T>> delete<T>(String path, {dynamic data, Options? options}) =>
      _dio.delete<T>(path, data: data, options: options);

  /// تحديث إعدادات الاتصال (MANAGER فقط) — W-14: يُعيد تهيئة interceptors
  Future<void> updateConnectionSettings({
    required String gasUrl,
    required String secretKey,
    required String geminiKey,
  }) async {
    await _storage.write(key: _kGasUrlKey,    value: gasUrl);
    await _storage.write(key: _kGasSecretKey, value: secretKey);
    await _storage.write(key: _kGeminiKey,    value: geminiKey);

    _dio.options.baseUrl = gasUrl;
    _dio.options.headers['X-Secret-Key'] = secretKey;
    _addInterceptors(_dio); // W-14: إعادة تهيئة
    developer.log('Connection settings updated', name: 'GasClient');
  }

  /// تحديث الـ token عند تسجيل الدخول (يُستدعى من auth providers)
  Future<void> updateToken(String? token) async {
    if (token != null) {
      await _storage.write(key: _kUserToken, value: token);
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      await _storage.delete(key: _kUserToken);
      _dio.options.headers.remove('Authorization');
    }
  }

  Future<String> getGeminiKey() async {
    final stored = await _storage.read(key: _kGeminiKey);
    return stored ?? AppSecrets.geminiApiKey;
  }

  Dio get dio => _dio; // M-19: للاستخدام في VideoServiceDrive
}

class _RetryInterceptor extends Interceptor {
  _RetryInterceptor({required this.dio, required this.maxRetries});
  final Dio dio;
  final int maxRetries;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra   = err.requestOptions.extra;
    final retries = (extra['retries'] as int?) ?? 0;
    final status  = err.response?.statusCode;

    if (status == 401 || status == 403 || status == 404) return handler.next(err);

    if (retries < maxRetries) {
      developer.log('Retry ${retries + 1}/$maxRetries', name: 'GasClient');
      await Future.delayed(Duration(seconds: 1 << retries));
      try {
        final opts = Options(
          method: err.requestOptions.method,
          headers: err.requestOptions.headers,
          extra:   {...err.requestOptions.extra, 'retries': retries + 1},
        );
        final resp = await dio.request<dynamic>(
          err.requestOptions.path,
          data:            err.requestOptions.data,
          queryParameters: err.requestOptions.queryParameters,
          options:         opts,
        );
        handler.resolve(resp);
      } catch (_) {
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }
}

@riverpod
Future<GasClient> gasClient(Ref ref) async {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  return GasClient.create(storage);
}
