using Alcoholimetro.Domain.Entities;
using Alcoholimetro.Domain.Enums;
using Alcoholimetro.Domain.Exceptions;
using Alcoholimetro.Domain.Repositories;

namespace Alcoholimetro.Application.Commands;

public class JoinGroupCommandHandler
{
    private readonly IGroupRepository _groupRepository;

    public JoinGroupCommandHandler(IGroupRepository groupRepository)
    {
        _groupRepository = groupRepository;
    }

    public async Task ExecuteAsync(JoinGroupCommand command)
    {
        var group = await _groupRepository.GetByInvitationCodeAsync(command.InvitationCode);
        
        if (group == null)
            throw new NotFoundException("El código de invitación no existe.");


        bool isAlreadyMember = await _groupRepository.IsUserInGroupAsync(command.UserId, group.Id);
        
        if (isAlreadyMember)
            throw new ConflictException("Ya eres miembro de este grupo.");

        var userGroup = new UserGroup
        {
            UserId = command.UserId,
            GroupId = group.Id,
            Role = GroupRole.Member
        };

        await _groupRepository.AddUserToGroupAsync(userGroup);
    }
}