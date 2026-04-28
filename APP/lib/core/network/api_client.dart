import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';

const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://unilobed-louie-pitifully.ngrok-free.dev',
);

final onUnauthorizedProvider = Provider<OnUnauthorized>((ref) {
  return () async {};
});

final dioProvider = Provider<Dio>((ref) {
  final secureStorageService = ref.watch(secureStorageServiceProvider);
  final onUnauthorized = ref.watch(onUnauthorizedProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      secureStorageService: secureStorageService,
      onUnauthorized: onUnauthorized,
    ),
  );

  return dio;
});
