namespace Alcoholimetro.Application.DTOs;

public record UserResponseDto(
    Guid Id,
    string FullName,
    string Email,
    int Age,
    double WeightKg,
    double HeightCm,
    string BiologicalSex,
    bool IsNoviceDriver
);