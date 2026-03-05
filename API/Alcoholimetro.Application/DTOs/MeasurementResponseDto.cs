namespace Alcoholimetro.Application.DTOs;

public record MeasurementResponseDto(
    Guid Id,
    Guid UserId,
    double AlcoholLevel,
    DateTime Timestamp,
    double Latitude,
    double Longitude
);