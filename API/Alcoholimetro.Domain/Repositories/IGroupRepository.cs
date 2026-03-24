using Alcoholimetro.Domain.Entities;

namespace Alcoholimetro.Domain.Repositories;

public interface IGroupRepository
{
    Task AddAsync(Group group);
    Task<Group?> GetByInvitationCodeAsync(string code);
    Task AddUserToGroupAsync(UserGroup userGroup);
    Task<bool> IsUserInGroupAsync(Guid userId, Guid groupId);
}