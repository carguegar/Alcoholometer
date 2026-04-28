using Alcoholimetro.Application.DTOs;
using Alcoholimetro.Domain.Exceptions;
using Alcoholimetro.Domain.Repositories;

namespace Alcoholimetro.Application.Queries;

public class GetGroupDetailsQueryHandler
{
    private readonly IGroupRepository _groupRepository;

    public GetGroupDetailsQueryHandler(IGroupRepository groupRepository)
    {
        _groupRepository = groupRepository;
    }

    public async Task<GroupDetailsDto> ExecuteAsync(GetGroupDetailsQuery query)
    {
        // Verify membership
        var isMember = await _groupRepository.IsUserInGroupAsync(query.RequestingUserId, query.GroupId);
        if (!isMember)
            throw new DomainException("You are not a member of this group.");

        var group = await _groupRepository.GetGroupWithMembersAsync(query.GroupId);
        if (group == null)
            throw new DomainException("Group not found.");

        var members = group.Members.Select(m => new GroupMemberDto(
            UserId: m.UserId,
            FirstName: m.User?.FirstName ?? "Unknown",
            LastName: m.User?.LastName ?? "User",
            Role: m.Role.ToString()
        )).ToList();

        return new GroupDetailsDto(
            GroupId: group.Id,
            Name: group.Name,
            InvitationCode: group.InvitationCode,
            AlertThresholdLevel: group.Configuration.AlertThresholdLevel,
            Members: members
        );
    }
}