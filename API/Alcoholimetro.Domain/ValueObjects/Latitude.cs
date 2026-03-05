using Alcoholimetro.Domain.Exceptions;

namespace Alcoholimetro.Domain.ValueObjects;

public record Latitude
{
    public double Value { get; }

    public Latitude(double value)
    {
        if (value < -90 || value > 90)
            throw new InvalidLatitudeException(value);

        Value = value;
    }
}