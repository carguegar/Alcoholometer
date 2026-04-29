import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/groups/data/groups_repository.dart';
import 'package:app/features/groups/domain/group_models.dart';

final groupsControllerProvider =
    StateNotifierProvider<GroupsController, AsyncValue<List<GroupSummaryModel>>>(
        (ref) {
  final repository = ref.watch(groupsRepositoryProvider);
  return GroupsController(repository);
});

class GroupsController
    extends StateNotifier<AsyncValue<List<GroupSummaryModel>>> {
  GroupsController(this._repository) : super(const AsyncValue.loading()) {
    loadGroups();
  }

  final GroupsRepository _repository;

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
    final result = await _repository.createGroup(
      name: name,
      description: description,
    );
    await loadGroups();
    return result;
  }

  Future<void> joinGroup(String invitationCode) async {
    await _repository.joinGroup(invitationCode);
    await loadGroups();
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
    return GroupDetailsController(repository)..load(groupId);
  },
);

class GroupDetailsController
    extends StateNotifier<AsyncValue<GroupDetailsState>> {
  GroupDetailsController(this._repository) : super(const AsyncValue.loading());

  final GroupsRepository _repository;

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
    await _repository.leaveGroup(groupId);
  }

  Future<void> updateGroupConfig(String groupId, double threshold) async {
    await _repository.updateGroupConfig(groupId, threshold);
    await load(groupId);
  }

  Future<void> kickMember(String groupId, String targetUserId) async {
    await _repository.kickMember(groupId, targetUserId);
    await load(groupId);
  }

  Future<void> promoteToAdmin(String groupId, String targetUserId) async {
    await _repository.promoteToAdmin(groupId, targetUserId);
    await load(groupId);
  }
}
