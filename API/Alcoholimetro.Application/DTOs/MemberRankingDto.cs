namespace Alcoholimetro.Application.DTOs;

public record MemberRankingDto(
    Guid UserId,
    string FirstName,
    string LastName,
    double RecordAlcoholLevel,
    DateTime RecordTimestamp,
    double RecordLat,
    double RecordLng
);
