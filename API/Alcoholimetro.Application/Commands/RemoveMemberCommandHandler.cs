using Alcoholimetro.Domain.Exceptions;
using Alcoholimetro.Domain.Repositories;

namespace Alcoholimetro.Application.Commands;

public class RemoveMemberCommandHandler
{
    private readonly IGroupRepository _groupRepository;

    public RemoveMemberCommandHandler(IGroupRepository groupRepository)
    {
        _groupRepository = groupRepository;
    }

    public async Task ExecuteAsync(RemoveMemberCommand command)
    {
        // Check if the target is in the group
        var targetMember = await _groupRepository.GetUserGroupAsync(command.TargetUserId, command.GroupId);
        if (targetMember == null)
            throw new DomainException("El usuario no es miembro de este grupo.");

        // If trying to kick someone else, check if requester is admin
        if (command.RequestingUserId != command.TargetUserId)
        {
            var requestingMember = await _groupRepository.GetUserGroupAsync(command.RequestingUserId, command.GroupId);
            if (requestingMember == null || requestingMember.Role != Alcoholimetro.Domain.Enums.GroupRole.Admin)
            {
                throw new DomainException("No tienes permiso para expulsar a miembros de este grupo.");
            }
        }

        // Remove user from the group
        await _groupRepository.RemoveUserFromGroupAsync(command.TargetUserId, command.GroupId);

        // Check if the group is now empty. If so, delete it.
        var memberCount = await _groupRepository.GetGroupMemberCountAsync(command.GroupId);
        if (memberCount == 0)
        {
            await _groupRepository.DeleteGroupAsync(command.GroupId);
        }
    }
}
