using Alcoholimetro.Domain.Entities;
using Alcoholimetro.Domain.Enums;

namespace Alcoholimetro.Domain.Repositories;

public interface IGroupRepository
{
    Task AddAsync(Group group);
    Task<Group?> GetByInvitationCodeAsync(string code);
    Task AddUserToGroupAsync(UserGroup userGroup);
    Task<bool> IsUserInGroupAsync(Guid userId, Guid groupId);
    Task<string?> GetGroupNameByIdAsync(Guid groupId);
    Task<List<Group>> GetGroupsWithMembersByUserIdAsync(Guid userId);
    Task<List<UserGroup>> GetUserGroupsByUserIdAsync(Guid userId);
    Task<Group?> GetGroupWithMembersAsync(Guid groupId);
    Task RemoveUserFromGroupAsync(Guid userId, Guid groupId);
    Task<int> GetGroupMemberCountAsync(Guid groupId);
    Task DeleteGroupAsync(Guid groupId);
    Task UpdateAsync(Group group);
    Task<UserGroup?> GetUserGroupAsync(Guid userId, Guid groupId);
    Task UpdateUserGroupRoleAsync(Guid userId, Guid groupId, GroupRole newRole);
}