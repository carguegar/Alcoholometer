import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/auth/auth_session.dart';
import 'package:app/core/storage/secure_storage_service.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/auth/domain/auth_status.dart';
import 'package:app/features/auth/domain/user_model.dart';
import 'package:app/features/groups/presentation/controllers/groups_controller.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthStatus>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final secureStorageService = ref.watch(secureStorageServiceProvider);
  final controller = AuthController(authRepository, secureStorageService, ref);
  // Reaccionar a forzados desde el interceptor (401 sin refresh válido)
  // sin necesidad de que `api_client` importe este archivo.
  ref.listen<int>(authSessionEventProvider, (prev, next) {
    if (prev != next) controller.handleExternalSignOut();
  });
  return controller;
});

final userProfileProvider =
    StateNotifierProvider<UserProfileController, AsyncValue<UserModel?>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return UserProfileController(authRepository);
});

class AuthController extends StateNotifier<AsyncValue<AuthStatus>> {
  AuthController(this._authRepository, this._secureStorageService, this._ref)
      : super(const AsyncValue.data(AuthStatus.initial)) {
    checkAuthStatus();
  }

  final AuthRepository _authRepository;
  final SecureStorageService _secureStorageService;
  final Ref _ref;

  Future<void> checkAuthStatus() async {
    state = const AsyncValue.loading();
    final accessToken = await _secureStorageService.readAccessToken();

    if (accessToken != null && accessToken.isNotEmpty) {
      state = const AsyncValue.data(AuthStatus.authenticated);
      return;
    }
    state = const AsyncValue.data(AuthStatus.unauthenticated);
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.login(email: email, password: password);
      state = const AsyncValue.data(AuthStatus.authenticated);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _authRepository.logout();
    
    // Clear user-specific data from providers
    _ref.invalidate(userProfileProvider);
    _ref.invalidate(groupsControllerProvider);
    
    state = const AsyncValue.data(AuthStatus.unauthenticated);
  }

  /// Invocado cuando el interceptor HTTP fuerza un sign-out por 401.
  /// Los tokens ya han sido borrados por el callback; aquí solo
  /// invalidamos providers dependientes y publicamos el nuevo estado.
  void handleExternalSignOut() {
    _ref.invalidate(userProfileProvider);
    _ref.invalidate(groupsControllerProvider);
    state = const AsyncValue.data(AuthStatus.unauthenticated);
  }
}

class UserProfileController extends StateNotifier<AsyncValue<UserModel?>> {
  UserProfileController(this._authRepository)
      : super(const AsyncValue.data(null));

  final AuthRepository _authRepository;

  Future<void> loadProfile() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.getUserProfile();
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateProfile({
    required String userId,
    required double weightKg,
    required double heightCm,
    bool? hasLicense,
  }) async {
    try {
      await _authRepository.updateProfile(
        userId: userId,
        weightKg: weightKg,
        heightCm: heightCm,
        hasLicense: hasLicense,
      );
      await loadProfile();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
