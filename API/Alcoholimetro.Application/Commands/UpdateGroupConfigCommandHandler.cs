using System;
using System.Threading.Tasks;
using Alcoholimetro.Domain.Entities;
using Alcoholimetro.Domain.Enums;
using Alcoholimetro.Domain.Exceptions;
using Alcoholimetro.Domain.Repositories;

namespace Alcoholimetro.Application.Commands;

public class UpdateGroupConfigCommandHandler
{
    private readonly IGroupRepository _groupRepository;

    public UpdateGroupConfigCommandHandler(IGroupRepository groupRepository)
    {
        _groupRepository = groupRepository;
    }

    public async Task ExecuteAsync(UpdateGroupConfigCommand command)
    {
        var userGroup = await _groupRepository.GetUserGroupAsync(command.AdminUserId, command.GroupId);
        if (userGroup == null)
            throw new DomainException("You are not a member of this group.");
            
        if (userGroup.Role != GroupRole.Admin)
            throw new DomainException("Only group administrators can modify the configuration.");

        var group = await _groupRepository.GetGroupWithMembersAsync(command.GroupId);
        if (group == null)
            throw new DomainException("Group not found.");

        group.Configuration.AlertThresholdLevel = command.AlertThresholdLevel;

        await _groupRepository.UpdateAsync(group);
    }
}