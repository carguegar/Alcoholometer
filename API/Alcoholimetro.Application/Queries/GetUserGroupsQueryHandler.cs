using Alcoholimetro.Application.DTOs;
using Alcoholimetro.Domain.Repositories;

namespace Alcoholimetro.Application.Queries;

public class GetUserGroupsQueryHandler
{
    private readonly IGroupRepository _groupRepository;

    public GetUserGroupsQueryHandler(IGroupRepository groupRepository)
    {
        _groupRepository = groupRepository;
    }

    public async Task<List<GroupSummaryDto>> ExecuteAsync(GetUserGroupsQuery query)
    {
        var userGroups = await _groupRepository.GetUserGroupsByUserIdAsync(query.UserId);

        return userGroups.Select(ug => new GroupSummaryDto(
            GroupId: ug.GroupId,
            GroupName: ug.Group?.Name ?? "Unknown",
            Role: ug.Role.ToString()
        )).ToList();
    }
}