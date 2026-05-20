import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/groups/data/groups_repository.dart';
import 'package:app/features/groups/domain/group_models.dart';
import 'package:app/core/ui/loading_provider.dart';

final groupsControllerProvider =
    StateNotifierProvider<GroupsController, AsyncValue<List<GroupSummaryModel>>>(
        (ref) {
  final repository = ref.watch(groupsRepositoryProvider);
  return GroupsController(repository, ref);
});

class GroupsController
    extends StateNotifier<AsyncValue<List<GroupSummaryModel>>> {
  GroupsController(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadGroups();
  }

  final GroupsRepository _repository;
  final Ref _ref;

  Future<void> loadGroups() async {
    state = const AsyncValue.loading();
    try {
      final groups = await _repository.getMyGroups();
      state = AsyncValue.data(groups);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<Map<String, String>> createGroup({
    required String name,
    required String description,
  }) async {
    _ref.read(loadingProvider.notifier).show(message: "Creando grupo...");
    try {
      final result = await _repository.createGroup(
        name: name,
        description: description,
      );
      await loadGroups();
      return result;
    } finally {
      _ref.read(loadingProvider.notifier).hide();
    }
  }

  Future<void> joinGroup(String invitationCode) async {
    _ref.read(loadingProvider.notifier).show(message: "Uniéndose al grupo...");
    try {
      await _repository.joinGroup(invitationCode);
      await loadGroups();
    } finally {
      _ref.read(loadingProvider.notifier).hide();
    }
  }
}

// ── Group Details ──

class GroupDetailsState {
  const GroupDetailsState({
    required this.details,
    required this.ranking,
  });

  final GroupDetailsModel details;
  final GroupRankingModel ranking;
}

final groupDetailsControllerProvider =
    StateNotifierProvider.autoDispose.family<
        GroupDetailsController, AsyncValue<GroupDetailsState>, String>(
  (ref, groupId) {
    final repository = ref.watch(groupsRepositoryProvider);
    return GroupDetailsController(repository, ref)..load(groupId);
  },
);

class GroupDetailsController
    extends StateNotifier<AsyncValue<GroupDetailsState>> {
  GroupDetailsController(this._repository, this._ref) : super(const AsyncValue.loading());

  final GroupsRepository _repository;
  final Ref _ref;

  Future<void> load(String groupId) async {
    state = const AsyncValue.loading();
    try {
      final details = await _repository.getGroupDetails(groupId);
      final ranking = await _repository.getGroupRanking(groupId);
      state = AsyncValue.data(
        GroupDetailsState(details: details, ranking: ranking),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> leaveGroup(String groupId) async {
    _ref.read(loadingProvider.notifier).show(message: "Saliendo del grupo...");
    try {
      await _repository.leaveGroup(groupId);
    } finally {
      _ref.read(loadingProvider.notifier).hide();
    }
  }

  Future<void> updateGroupConfig(String groupId, double threshold) async {
    _ref.read(loadingProvider.notifier).show(message: "Actualizando configuración...");
    try {
      await _repository.updateGroupConfig(groupId, threshold);
      await load(groupId);
    } finally {
      _ref.read(loadingProvider.notifier).hide();
    }
  }

  Future<void> kickMember(String groupId, String targetUserId) async {
    _ref.read(loadingProvider.notifier).show(message: "Eliminando miembro...");
    try {
      await _repository.kickMember(groupId, targetUserId);
      await load(groupId);
    } finally {
      _ref.read(loadingProvider.notifier).hide();
    }
  }

  Future<void> promoteToAdmin(String groupId, String targetUserId) async {
    _ref.read(loadingProvider.notifier).show(message: "Haciendo administrador...");
    try {
      await _repository.promoteToAdmin(groupId, targetUserId);
      await load(groupId);
    } finally {
      _ref.read(loadingProvider.notifier).hide();
    }
  }
}
