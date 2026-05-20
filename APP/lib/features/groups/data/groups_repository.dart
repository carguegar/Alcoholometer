import 'package:dio/dio.dart';
import 'package:app/core/network/error_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/network/api_client.dart';
import 'package:app/features/groups/domain/group_models.dart';

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return GroupsRepository(dio);
});

class GroupsRepository {
  GroupsRepository(this._dio);

  final Dio _dio;

  Future<List<GroupSummaryModel>> getMyGroups() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/groups');
      final jsonList = response.data ?? <dynamic>[];
      return jsonList
          .map((item) =>
              GroupSummaryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {      throw Exception(extractErrorMessage(e, 'Error al cargar grupos'));
    }
  }

  Future<GroupDetailsModel> getGroupDetails(String groupId) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/api/groups/$groupId');
      final data = response.data;
      if (data == null) throw Exception('Detalles del grupo vacíos');
      return GroupDetailsModel.fromJson(data);
    } on DioException catch (e) {      throw Exception(extractErrorMessage(e, 'Error al cargar detalles del grupo'));
    }
  }

  Future<GroupRankingModel> getGroupRanking(
    String groupId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) {
      queryParams['startDate'] = startDate.toUtc().toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toUtc().toIso8601String();
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/groups/$groupId/ranking',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      final data = response.data;
      if (data == null) throw Exception('Ranking vacío');
      return GroupRankingModel.fromJson(data);
    } on DioException catch (e) {      throw Exception(extractErrorMessage(e, 'Error al cargar ranking'));
    }
  }

  Future<Map<String, String>> createGroup({
    required String name,
    required String description,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/groups',
        data: {'name': name, 'description': description},
      );
      final data = response.data;
      return {
        'groupId': data?['groupId'] as String? ?? '',
        'invitationCode': data?['invitationCode'] as String? ?? '',
      };
    } on DioException catch (e) {      throw Exception(extractErrorMessage(e, 'Error al crear grupo'));
    }
  }

  Future<void> joinGroup(String invitationCode) async {
    try {
      await _dio.post<void>(
        '/api/groups/join',
        data: {'invitationCode': invitationCode},
      );
    } on DioException catch (e) {      throw Exception(extractErrorMessage(e, 'Error al unirse al grupo'));
    }
  }

  Future<void> leaveGroup(String groupId) async {
    try {
      await _dio.delete<void>('/api/groups/$groupId/leave');
    } on DioException catch (e) {      throw Exception(extractErrorMessage(e, 'Error al abandonar grupo'));
    }
  }

  Future<void> updateGroupConfig(String groupId, double threshold) async {
    try {
      await _dio.put<void>(
        '/api/groups/$groupId/config',
        data: threshold,
      );
    } on DioException catch (e) {      throw Exception(extractErrorMessage(e, 'Error al actualizar configuración'));
    }
  }

  Future<void> kickMember(String groupId, String targetUserId) async {
    try {
      await _dio.delete<void>('/api/groups/$groupId/members/$targetUserId');
    } on DioException catch (e) {      throw Exception(extractErrorMessage(e, 'Error al expulsar miembro'));
    }
  }

  Future<void> promoteToAdmin(String groupId, String targetUserId) async {
    try {
      await _dio.put<void>('/api/groups/$groupId/members/$targetUserId/admin');
    } on DioException catch (e) {      throw Exception(extractErrorMessage(e, 'Error al ascender a administrador'));
    }
  }
}
