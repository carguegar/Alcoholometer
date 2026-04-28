namespace Alcoholimetro.Application.Queries;

public record GetGroupRankingQuery(
    Guid GroupId,
    Guid RequestingUserId,
    DateTime? StartDate,
    DateTime? EndDate
);
