using Alcoholimetro.Domain.Exceptions;
using Alcoholimetro.Domain.ValueObjects;
using FluentAssertions;

namespace Alcoholimetro.Application.Tests.Domain.ValueObjects;

public class LatitudeTests
{
    [Theory]
    [InlineData(-90.0)]
    [InlineData(-45.5)]
    [InlineData(0.0)]
    [InlineData(45.5)]
    [InlineData(90.0)]
    public void Constructor_AcceptsValuesInRange(double value)
    {
        var lat = new Latitude(value);
        lat.Value.Should().Be(value);
    }

    [Theory]
    [InlineData(-90.0001)]
    [InlineData(-91.0)]
    [InlineData(91.0)]
    [InlineData(180.0)]
    [InlineData(double.PositiveInfinity)]
    [InlineData(double.NegativeInfinity)]
    public void Constructor_RejectsValuesOutOfRange(double value)
    {
        var act = () => new Latitude(value);
        act.Should().Throw<InvalidLatitudeException>();
    }

    // NOTE: NaN is currently NOT rejected by the value object (NaN comparisons return false).
    // Documented here as known gap; not a test requirement to enforce until VO adds explicit NaN guard.
}
