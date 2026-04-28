using Alcoholimetro.Application.DTOs;
using Alcoholimetro.Domain.Repositories;
using Alcoholimetro.Domain.Entities;
using Alcoholimetro.Domain.Exceptions;
using Alcoholimetro.Domain.ValueObjects;

namespace Alcoholimetro.Application.Queries;

public class GetGroupRankingQueryHandler
{
    private readonly IGroupRepository _groupRepository;
    private readonly IMeasurementRepository _measurementRepository;
    private readonly IUserRepository _userRepository;

    public GetGroupRankingQueryHandler(
        IGroupRepository groupRepository,
        IMeasurementRepository measurementRepository,
        IUserRepository userRepository)
    {
        _groupRepository = groupRepository;
        _measurementRepository = measurementRepository;
        _userRepository = userRepository;
    }

    public async Task<GroupRankingResponse> ExecuteAsync(GetGroupRankingQuery query)
    {
        // 1. Validate user belongs to the group
        var isMember = await _groupRepository.IsUserInGroupAsync(query.RequestingUserId, query.GroupId);

        if (!isMember)
            throw new DomainException("The requesting user is not a member of this group.");

        // 2. Fetch group name
        var groupName = await _groupRepository.GetGroupNameByIdAsync(query.GroupId);

        if (groupName == null)
            throw new DomainException("Group not found.");

        // 3. Filter Measurements by group members and dates
        var topRecords = await _measurementRepository.GetGroupHighScoresAsync(query.GroupId, query.StartDate, query.EndDate);

        // 4. Get user details
        var userIds = topRecords.Select(r => r.UserId).ToList();
        var usersDict = await _userRepository.GetUsersByIdsAsync(userIds);

        var rankings = new List<MemberRankingDto>();

        foreach (var record in topRecords)
        {
            if (usersDict.TryGetValue(record.UserId, out var userInfo))
            {
                rankings.Add(new MemberRankingDto(
                    UserId: record.UserId,
                    FirstName: userInfo.FirstName,
                    LastName: userInfo.LastName,
                    RecordAlcoholLevel: record.AlcoholLevel,
                    RecordTimestamp: record.Timestamp,
                    RecordLat: record.Location.Lat.Value,
                    RecordLng: record.Location.Lon.Value
                ));
            }
        }

        // 5. Order descending by record alcohol level
        rankings = rankings.OrderByDescending(r => r.RecordAlcoholLevel).ToList();

        return new GroupRankingResponse(query.GroupId, groupName, rankings);
    }
}
