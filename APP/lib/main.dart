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
import 'package:app/core/ui/loading_provider.dart';

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

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class AlcoholimetroApp extends ConsumerStatefulWidget {
  const AlcoholimetroApp({super.key});

  @override
  ConsumerState<AlcoholimetroApp> createState() => _AlcoholimetroAppState();
}

class _AlcoholimetroAppState extends ConsumerState<AlcoholimetroApp> {
  bool _pushStarted = false;
  StreamSubscription? _fgSub;

  @override
  void initState() {
    super.initState();
    _fgSub = PushService.instance.foregroundMessages.listen((msg) {
      final title = msg.notification?.title ?? 'Nueva Notificación';
      final body = msg.notification?.body ?? '';
      
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(body),
              ],
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          backgroundColor: AppColors.surface,
          action: SnackBarAction(
            label: 'Cerrar',
            onPressed: () {
              rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
            },
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _fgSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    final authState = ref.watch(authControllerProvider);
    final status = authState.asData?.value;
    
    // Reset flag if we log out
    if (status != AuthStatus.authenticated) {
      _pushStarted = false;
    } else if (!_pushStarted) {
      // If authenticated and push not started, start it
      _pushStarted = true;
      final authRepo = ref.read(authRepositoryProvider);
      unawaited(
        PushService.instance.init(
          readUserId: () => 'me',
          registerToken: (token) => authRepo.updateDeviceToken(token),
        ),
      );
    }

    return MaterialApp.router(
      title: 'Alcoholímetro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      builder: (context, child) {
        return _GlobalLoadingWrapper(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

class _GlobalLoadingWrapper extends ConsumerWidget {
  final Widget child;

  const _GlobalLoadingWrapper({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadingState = ref.watch(loadingProvider);

    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        child,
        if (loadingState.isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.6),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    if (loadingState.message != null && loadingState.message!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        loadingState.message!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

