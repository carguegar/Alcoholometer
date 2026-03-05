using Alcoholimetro.Domain.Exceptions;

namespace Alcoholimetro.Domain.ValueObjects;
public record Longitude
{
    public double Value { get; }

    public Longitude(double value)
    {
        if (value < -180 || value > 180)
            throw new InvalidLongitudeException(value);

        Value = value;
    }
}