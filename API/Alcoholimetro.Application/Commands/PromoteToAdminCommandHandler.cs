using Alcoholimetro.Domain.Enums;
using Alcoholimetro.Domain.Exceptions;
using Alcoholimetro.Domain.Repositories;

namespace Alcoholimetro.Application.Commands;

public class PromoteToAdminCommandHandler
{
    private readonly IGroupRepository _groupRepository;

    public PromoteToAdminCommandHandler(IGroupRepository groupRepository)
    {
        _groupRepository = groupRepository;
    }

    public async Task ExecuteAsync(PromoteToAdminCommand command)
    {
        var requestingMember = await _groupRepository.GetUserGroupAsync(command.RequestingUserId, command.GroupId);
        if (requestingMember == null || requestingMember.Role != GroupRole.Admin)
            throw new DomainException("Only admins can promote members.");

        var group = await _groupRepository.GetGroupWithMembersAsync(command.GroupId);
        if (group == null)
            throw new DomainException("Group not found.");

        var target = group.Members.FirstOrDefault(m => m.UserId == command.TargetUserId);
        if (target == null)
            throw new DomainException("Target user is not a member of the group.");

        if (target.Role == GroupRole.Admin)
            return;

        target.Role = GroupRole.Admin;
        await _groupRepository.UpdateAsync(group);
    }
}
