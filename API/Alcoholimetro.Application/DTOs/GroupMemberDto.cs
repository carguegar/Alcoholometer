namespace Alcoholimetro.Application.DTOs;

public record GroupMemberDto(
    Guid UserId,
    string FirstName,
    string LastName,
    string Role,
    DateOnly? BirthDate,
    double HeightCm,
    double WeightKg,
    string BiologicalSex
);