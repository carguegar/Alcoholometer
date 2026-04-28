namespace Alcoholimetro.Application.Queries;

public record GetMeasurementsByUserIdQuery(Guid UserId, int Page, int PageSize);