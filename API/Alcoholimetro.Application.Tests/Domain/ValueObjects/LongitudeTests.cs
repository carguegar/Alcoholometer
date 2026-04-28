using Alcoholimetro.Domain.Exceptions;
using Alcoholimetro.Domain.ValueObjects;
using FluentAssertions;

namespace Alcoholimetro.Application.Tests.Domain.ValueObjects;

public class LongitudeTests
{
    [Theory]
    [InlineData(-180.0)]
    [InlineData(-90.0)]
    [InlineData(0.0)]
    [InlineData(90.0)]
    [InlineData(180.0)]
    public void Constructor_AcceptsValuesInRange(double value)
    {
        var lon = new Longitude(value);
        lon.Value.Should().Be(value);
    }

    [Theory]
    [InlineData(-180.0001)]
    [InlineData(-181.0)]
    [InlineData(181.0)]
    [InlineData(360.0)]
    [InlineData(double.PositiveInfinity)]
    [InlineData(double.NegativeInfinity)]
    public void Constructor_RejectsValuesOutOfRange(double value)
    {
        var act = () => new Longitude(value);
        act.Should().Throw<InvalidLongitudeException>();
    }

    // NOTE: NaN is currently NOT rejected by the value object (NaN comparisons return false).
}
