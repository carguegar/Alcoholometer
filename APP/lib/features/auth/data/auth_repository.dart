import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/network/api_client.dart';
import 'package:app/core/storage/secure_storage_service.dart';
import 'package:app/core/utils/jwt_utils.dart';
import 'package:app/features/auth/domain/user_model.dart';
import 'package:app/core/network/error_handler.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final secureStorageService = ref.watch(secureStorageServiceProvider);
  return AuthRepository(dio, secureStorageService);
});

class AuthRepository {
  AuthRepository(this._dio, this._secureStorageService);

  final Dio _dio;
  final SecureStorageService _secureStorageService;


  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/users/login',
        data: {
          'emailRaw': {'value': email},
          'password': password,
        },
      );

      final responseBody = response.data;
      final accessToken = responseBody?['accessToken'] as String?;
      final refreshToken = responseBody?['refreshToken'] as String?;

      if (accessToken == null || refreshToken == null) {
        throw Exception('Respuesta de login inválida');
      }

      await _secureStorageService.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      // Extract userId from JWT
      final userId = extractUserIdFromToken(accessToken);
      if (userId != null) {
        await _secureStorageService.saveUserId(userId);
      }
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Error de conexión al iniciar sesión. Inténtalo de nuevo.'));
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String secondLastName,
    required String email,
    required String password,
    required String birthDate,
    required double weightKg,
    required double heightCm,
    required String biologicalSex,
    required String? drivingLicenseIssueDate,
  }) async {
    try {
      await _dio.post<void>('/api/users', data: {
        'firstName': firstName,
        'lastName': lastName,
        'secondLastName': secondLastName,
        'emailRaw': email,
        'password': password,
        'birthDate': birthDate,
        'weightKg': weightKg,
        'heightCm': heightCm,
        'biologicalSex': biologicalSex,
        'drivingLicenseIssueDate': drivingLicenseIssueDate,
      });
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Error al registrar el usuario. Comprueba tus datos e inténtalo de nuevo.'));
    }
  }

  Future<UserModel> getUserProfile() async {
    final userId = await _secureStorageService.readUserId();
    if (userId == null) {
      throw Exception('No se encontró el ID del usuario');
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/users/$userId',
      );
      final data = response.data;
      if (data == null) throw Exception('Perfil vacío');
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Error al cargar los datos del perfil.'));
    }
  }

  Future<void> updateProfile({
    required String userId,
    required double weightKg,
    required double heightCm,
    bool? hasLicense,
  }) async {
    try {
      await _dio.put<void>('/api/users/$userId', data: {
        'userId': userId,
        'weightKg': weightKg,
        'heightCm': heightCm,
        if (hasLicense != null) 'hasLicense': hasLicense,
      });
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Error al actualizar tu perfil. Inténtalo más tarde.'));
    }
  }

  Future<void> updateDeviceToken(String token) async {
    try {
      await _dio.put<void>('/api/users/device-token', data: {'deviceToken': token});
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Error interno al sincronizar notificaciones.'));
    }
  }

  Future<void> logout() async {
    await _secureStorageService.clearTokens();
  }
}
