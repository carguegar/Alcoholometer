namespace Alcoholimetro.Application.Queries;

public record GetGroupDetailsQuery(Guid GroupId, Guid RequestingUserId);