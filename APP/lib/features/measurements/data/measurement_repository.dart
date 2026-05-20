import 'package:dio/dio.dart';
import 'package:app/core/network/error_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/network/api_client.dart';
import 'package:app/features/measurements/domain/measurement_models.dart';

final measurementRepositoryProvider = Provider<MeasurementRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return MeasurementRepository(dio);
});

class MeasurementRepository {
  MeasurementRepository(this._dio);

  final Dio _dio;

  Future<MeasurementResultModel> recordMeasurement({
    required double level,
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/measurements',
        data: {
          'measurementLevel': level,
          'lat': lat,
          'lng': lng,
        },
      );

      final data = response.data;
      if (data == null) throw Exception('Respuesta vacía del servidor');
      return MeasurementResultModel.fromJson(data);
    } on DioException catch (e) {      throw Exception(extractErrorMessage(e, 'Error al registrar medición'));
    }
  }

  Future<List<MeasurementHistoryModel>> getMeasurementsByUser(
    String userId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/measurements/user/$userId',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );
      final jsonList = response.data ?? <dynamic>[];
      return jsonList
          .map((item) =>
              MeasurementHistoryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {      throw Exception(extractErrorMessage(e, 'Error al cargar historial'));
    }
  }
}
