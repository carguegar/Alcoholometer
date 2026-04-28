namespace Alcoholimetro.Application.Commands;

public record RecordMeasurementCommand(double MeasurementLevel, Guid? UserId, double Lat, double Lng);