namespace Alcoholimetro.Application.Commands;

public record CreateUserCommand(
    string FirstName, 
    string LastName, 
    string SecondLastName, 
    string EmailRaw, 
    string Password, 
    DateOnly BirthDate,
    double WeightKg, 
    double HeightCm, 
    string BiologicalSex
);