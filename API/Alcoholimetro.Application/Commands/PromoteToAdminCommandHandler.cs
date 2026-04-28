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
        // verify target member
        var targetMember = await _groupRepository.GetUserGroupAsync(command.TargetUserId, command.GroupId);
        if (targetMember == null)
            throw new DomainException("El usuario no es miembro de este grupo.");

        // verify requester
        var requestingMember = await _groupRepository.GetUserGroupAsync(command.RequestingUserId, command.GroupId);
        if (requestingMember == null || requestingMember.Role != Alcoholimetro.Domain.Enums.GroupRole.Admin)
        {
            throw new DomainException("Solo los administradores pueden ascender a otros miembros.");
        }

        // promote
        targetMember.Role = Alcoholimetro.Domain.Enums.GroupRole.Admin;
        
        // Note: we need an UpdateUserGroupAsync or just UpdateAsync on Group 
        // to save the changes if EF core is not tracking it automatically here.
        // Actually, since IGroupRepository has UpdateAsync(Group group), 
        // we might need to load the group and update it. Let's load the group.
        var group = await _groupRepository.GetGroupWithMembersAsync(command.GroupId);
        if (group != null)
        {
            var userGroup = group.Members.FirstOrDefault(m => m.UserId == command.TargetUserId);
            if (userGroup != null) 
            {
                userGroup.Role = Alcoholimetro.Domain.Enums.GroupRole.Admin;
                await _groupRepository.UpdateAsync(group);
            }
        }
    }
}
