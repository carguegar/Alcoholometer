import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/network/auth_interceptor.dart';
import 'package:app/core/storage/secure_storage_service.dart';

/// In-memory fake of [SecureStorageService] that bypasses the underlying
/// platform [FlutterSecureStorage] entirely (its methods are never called).
class _FakeSecureStorageService extends SecureStorageService {
  _FakeSecureStorageService({String? accessToken, String? refreshToken})
      : _accessToken = accessToken,
        _refreshToken = refreshToken,
        super(const FlutterSecureStorage());

  String? _accessToken;
  String? _refreshToken;
  int clearCalls = 0;

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<String?> readRefreshToken() async => _refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    clearCalls++;
    _accessToken = null;
    _refreshToken = null;
  }
}

/// Programmable [HttpClientAdapter] that captures requests and replies with
/// scripted responses keyed by request path.
class _ScriptedAdapter implements HttpClientAdapter {
  final List<RequestOptions> capturedRequests = [];

  /// path → handler returning a [ResponseBody].
  final Map<String, ResponseBody Function(RequestOptions)> handlers = {};

  ResponseBody Function(RequestOptions)? fallback;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    capturedRequests.add(options);
    final handler = handlers[options.path] ?? fallback;
    if (handler == null) {
      return ResponseBody.fromString(
        '{}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(Object? body, int status) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  group('AuthInterceptor', () {
    test(
        'adds Authorization: Bearer <token> header when access token is stored',
        () async {
      final storage = _FakeSecureStorageService(accessToken: 'token-abc');
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
      final adapter = _ScriptedAdapter()
        ..fallback = (_) => _jsonResponse({'ok': true}, 200);
      dio.httpClientAdapter = adapter;

      dio.interceptors.add(
        AuthInterceptor(
          dio: dio,
          secureStorageService: storage,
          onUnauthorized: () async {},
        ),
      );

      await dio.get<dynamic>('/api/measurements');

      expect(adapter.capturedRequests, hasLength(1));
      expect(
        adapter.capturedRequests.single.headers['Authorization'],
        'Bearer token-abc',
      );
    });

    test(
        'does not add Authorization header when no access token is stored',
        () async {
      final storage = _FakeSecureStorageService();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
      final adapter = _ScriptedAdapter()
        ..fallback = (_) => _jsonResponse({'ok': true}, 200);
      dio.httpClientAdapter = adapter;

      dio.interceptors.add(
        AuthInterceptor(
          dio: dio,
          secureStorageService: storage,
          onUnauthorized: () async {},
        ),
      );

      await dio.get<dynamic>('/api/measurements');

      expect(
        adapter.capturedRequests.single.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test(
        '401 with no refresh token available clears tokens and invokes onUnauthorized',
        () async {
      final storage = _FakeSecureStorageService(); // no tokens stored
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
      final adapter = _ScriptedAdapter()
        ..fallback = (_) => _jsonResponse({'error': 'unauthorized'}, 401);
      dio.httpClientAdapter = adapter;

      var unauthorizedInvocations = 0;
      dio.interceptors.add(
        AuthInterceptor(
          dio: dio,
          secureStorageService: storage,
          onUnauthorized: () async {
            unauthorizedInvocations++;
          },
        ),
      );

      await expectLater(
        dio.get<dynamic>('/api/measurements'),
        throwsA(isA<DioException>()),
      );

      expect(unauthorizedInvocations, 1);
      expect(storage.clearCalls, greaterThanOrEqualTo(1));
    });

    test('401 with failing refresh request invokes onUnauthorized', () async {
      final storage = _FakeSecureStorageService(
        accessToken: 'expired',
        refreshToken: 'refresh-1',
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
      // Nota: NO encadenar `..handlers[...] = (_) => fn() ..fallback = ...`
      // porque el `..` se ata al cuerpo del closure (`fn() ..fallback`) en
      // vez de al adapter, lo que provoca un error de tipo sobre `ResponseBody`.
      final adapter = _ScriptedAdapter();
      adapter.handlers['/api/users/refresh'] =
          (_) => _jsonResponse({'error': 'invalid'}, 400);
      adapter.fallback = (_) => _jsonResponse({'error': 'unauthorized'}, 401);
      dio.httpClientAdapter = adapter;

      var unauthorizedInvocations = 0;
      dio.interceptors.add(
        AuthInterceptor(
          dio: dio,
          secureStorageService: storage,
          onUnauthorized: () async {
            unauthorizedInvocations++;
          },
        ),
      );

      await expectLater(
        dio.get<dynamic>('/api/measurements'),
        throwsA(isA<DioException>()),
      );

      expect(unauthorizedInvocations, 1);
      expect(storage.clearCalls, greaterThanOrEqualTo(1));
    });

    test(
        '401 on the refresh endpoint itself does not trigger another refresh loop',
        () async {
      final storage = _FakeSecureStorageService(
        accessToken: 'expired',
        refreshToken: 'refresh-1',
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
      final adapter = _ScriptedAdapter()
        ..fallback = (_) => _jsonResponse({'error': 'unauthorized'}, 401);
      dio.httpClientAdapter = adapter;

      var unauthorizedInvocations = 0;
      dio.interceptors.add(
        AuthInterceptor(
          dio: dio,
          secureStorageService: storage,
          onUnauthorized: () async {
            unauthorizedInvocations++;
          },
        ),
      );

      await expectLater(
        dio.post<dynamic>('/api/users/refresh',
            data: {'accessToken': 'x', 'refreshToken': 'y'}),
        throwsA(isA<DioException>()),
      );

      // Refresh endpoint is short-circuited: no callback, no extra refresh.
      expect(unauthorizedInvocations, 0);
    });
  });
}
