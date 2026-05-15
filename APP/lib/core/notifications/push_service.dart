import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String _webVapidKey =
    'BKrJpkDUS4D8W1s1QC53STn0Qf8dAZDZutE0dvieOUumqcTlvsN0-BNjKtuE3kzm5c-NVxIkfBG9DSQGJ5VcItA';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op background handler. Required to be a top-level function.
}

class PushService {
  PushService._();

  static final PushService instance = PushService._();

  final StreamController<RemoteMessage> _foregroundController =
      StreamController<RemoteMessage>.broadcast();

  Stream<RemoteMessage> get foregroundMessages => _foregroundController.stream;

  bool _initialized = false;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;

  Future<void> init({
    required String? Function() readUserId,
    required Future<void> Function(String token) registerToken,
  }) async {
    try {
      final messaging = FirebaseMessaging.instance;

      if (!_initialized && !kIsWeb) {
        await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      final token = kIsWeb
          ? await messaging.getToken(vapidKey: _webVapidKey)
          : await messaging.getToken();

      if (token != null && token.isNotEmpty && readUserId() != null) {
        try {
          await registerToken(token);
        } catch (e) {
          debugPrint('PushService: failed to register token: $e');
        }
      }

      if (!_initialized) {
        _tokenRefreshSub = messaging.onTokenRefresh.listen((newToken) async {
          if (readUserId() != null) {
            try {
              await registerToken(newToken);
            } catch (e) {
              debugPrint('PushService: failed to register refreshed token: $e');
            }
          }
        });

        _onMessageSub = FirebaseMessaging.onMessage.listen((msg) {
          _foregroundController.add(msg);
        });

        _initialized = true;
      }
    } catch (e) {
      debugPrint('PushService init failed: $e');
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _onMessageSub?.cancel();
    await _foregroundController.close();
  }
}

final pushServiceProvider = Provider<PushService>(
  (ref) => PushService.instance,
);

void registerFirebaseBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}
