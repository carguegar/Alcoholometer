import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/notifications/push_service.dart';
import 'package:app/core/routing/app_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/auth/domain/auth_status.dart';
import 'package:app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    registerFirebaseBackgroundHandler();
  } catch (e) {
    // If Firebase config is missing (TODO placeholders), continue without crashing.
    debugPrint('Firebase init skipped: $e');
  }
  runApp(const ProviderScope(child: AlcoholimetroApp()));
}

class AlcoholimetroApp extends ConsumerWidget {
  const AlcoholimetroApp({super.key});

  static bool _pushStarted = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    ref.listen<AsyncValue<AuthStatus>>(authControllerProvider, (prev, next) {
      final status = next.asData?.value;
      if (status == AuthStatus.authenticated && !_pushStarted) {
        _pushStarted = true;
        final authRepo = ref.read(authRepositoryProvider);
        // Fire-and-forget; PushService.init has its own try/catch.
        unawaited(
          PushService.instance.init(
            readUserId: () => 'me',
            registerToken: (token) => authRepo.updateDeviceToken(token),
          ),
        );
      }
    });

    return MaterialApp.router(
      title: 'Alcoholímetro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
