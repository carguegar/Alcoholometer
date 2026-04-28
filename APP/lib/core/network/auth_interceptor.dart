import 'dart:async';
import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

typedef OnUnauthorized = Future<void> Function();

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required SecureStorageService secureStorageService,
    required OnUnauthorized onUnauthorized,
  })  : _dio = dio,
        _secureStorageService = secureStorageService,
        _onUnauthorized = onUnauthorized;

  final Dio _dio;
  final SecureStorageService _secureStorageService;
  final OnUnauthorized _onUnauthorized;

  Future<String?>? _refreshFuture;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _secureStorageService.readAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final requestPath = err.requestOptions.path;

    final isUnauthorized = statusCode == 401;
    final isRefreshRequest = requestPath.contains('/api/users/refresh');
    final isLoginRequest = requestPath.contains('/api/users/login');

    if (!isUnauthorized || isRefreshRequest || isLoginRequest) {
      handler.next(err);
      return;
    }

    final newAccessToken = await _refreshAccessToken();

    if (newAccessToken == null) {
      await _secureStorageService.clearTokens();
      await _onUnauthorized();
      handler.next(err);
      return;
    }

    try {
      final requestOptions = err.requestOptions;
      requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final response = await _dio.fetch<dynamic>(requestOptions);
      handler.resolve(response);
    } catch (retryError) {
      handler.next(err);
    }
  }

  Future<String?> _refreshAccessToken() async {
    if (_refreshFuture != null) {
      return _refreshFuture;
    }

    final completer = Completer<String?>();
    _refreshFuture = completer.future;

    try {
      final currentAccessToken =
          await _secureStorageService.readAccessToken();
      final refreshToken = await _secureStorageService.readRefreshToken();

      if (currentAccessToken == null || refreshToken == null) {
        completer.complete(null);
        return completer.future;
      }

      final refreshClient = Dio(
        BaseOptions(
          baseUrl: _dio.options.baseUrl,
          connectTimeout: _dio.options.connectTimeout,
          receiveTimeout: _dio.options.receiveTimeout,
          sendTimeout: _dio.options.sendTimeout,
        ),
      );

      final response = await refreshClient.post<Map<String, dynamic>>(
        '/api/users/refresh',
        data: {
          'accessToken': currentAccessToken,
          'refreshToken': refreshToken,
        },
      );

      final data = response.data;
      final newAccessToken = data?['accessToken'] as String?;
      final newRefreshToken = data?['refreshToken'] as String?;

      if (newAccessToken == null || newRefreshToken == null) {
        completer.complete(null);
        return completer.future;
      }

      await _secureStorageService.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      completer.complete(newAccessToken);
      return completer.future;
    } catch (_) {
      completer.complete(null);
      return completer.future;
    } finally {
      _refreshFuture = null;
    }
  }
}
