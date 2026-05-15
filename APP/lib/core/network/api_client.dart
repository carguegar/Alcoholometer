import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_session.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';

// Base URL de la API. Override en build/run con:
//   flutter run --dart-define=API_BASE_URL=https://mi-api.com
// Default apunta al loopback del emulador Android (10.0.2.2 = host).

/// Base URL for the Alcoholimetro backend.
///
/// Override at build time with `--dart-define=API_BASE_URL=https://<your-host>`.
/// Examples:
///   flutter run -d chrome --dart-define=API_BASE_URL=https://abcd.ngrok-free.app
///   flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://unilobed-louie-pitifully.ngrok-free.dev',
);

final onUnauthorizedProvider = Provider<OnUnauthorized>((ref) {
  return () async {
    // Solo invocado tras un 401 con refresh fallido. Mantener este closure
    // SIN referenciar `authControllerProvider` para no recrear el ciclo
    // api_client → auth_controller → auth_repository → api_client.
    await ref.read(secureStorageServiceProvider).clearTokens();
    ref.read(authSessionEventProvider.notifier).state++;
  };
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
