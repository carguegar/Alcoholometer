namespace Alcoholimetro.Application.Commands;

public record UpdateUserCommand(
    Guid UserId, 
    double WeightKg, 
    double HeightCm
);