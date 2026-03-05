namespace Alcoholimetro.Application.Commands;

public record RecordMeasurementCommand(
    Guid UserId, 
    double AlcoholLevel, 
    double Latitude, 
    double Longitude
);