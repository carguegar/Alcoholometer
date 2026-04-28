using Alcoholimetro.Domain.Enums;
using Alcoholimetro.Domain.Services;
using FluentAssertions;

namespace Alcoholimetro.Application.Tests.Services;

public class AlcoholCalculatorServiceTests
{
    private const double WeightKg = 70.0;
    private const double IllegalLevel = 0.50; // above general limit (0.25), below criminal (0.60)

    private readonly AlcoholCalculatorService _sut = new();

    [Fact]
    public void Calculate_BelowLegalLimit_ReturnsGreen()
    {
        var result = _sut.Calculate(measurementLevel: 0.10, isNoviceDriver: false);

        result.Color.Should().Be(TrafficLightColor.Green);
        result.EstimatedTimeToGreen.Should().BeNull();
    }

    [Fact]
    public void Calculate_AboveCriminalLimit_ReturnsRed()
    {
        var result = _sut.Calculate(measurementLevel: 0.80, isNoviceDriver: false);

        result.Color.Should().Be(TrafficLightColor.Red);
        result.EstimatedTimeToGreen.Should().NotBeNull();
    }

    [Fact]
    public void Calculate_AboveLegalBelowCriminal_ReturnsYellow()
    {
        var result = _sut.Calculate(measurementLevel: IllegalLevel, isNoviceDriver: false);

        result.Color.Should().Be(TrafficLightColor.Yellow);
        result.EstimatedTimeToGreen.Should().NotBeNull();
    }

    [Fact]
    public void Calculate_NoviceDriver_HasLowerLegalLimitThanGeneral()
    {
        // 0.20 is illegal for novice (limit 0.15) but legal for general (limit 0.25)
        var novice = _sut.Calculate(0.20, isNoviceDriver: true);
        var general = _sut.Calculate(0.20, isNoviceDriver: false);

        novice.Color.Should().Be(TrafficLightColor.Yellow);
        general.Color.Should().Be(TrafficLightColor.Green);
    }

    // Female elimination rate (0.085) > male rate (0.075) ⇒ female recovers faster
    [Fact]
    public void Female_RecoversFasterThan_Male()
    {
        var male = _sut.Calculate(IllegalLevel, false, WeightKg, "Male");
        var female = _sut.Calculate(IllegalLevel, false, WeightKg, "Female");

        male.EstimatedTimeToGreen.Should().NotBeNull();
        female.EstimatedTimeToGreen.Should().NotBeNull();
        female.EstimatedTimeToGreen!.Value.Should().BeLessThan(male.EstimatedTimeToGreen!.Value);
    }

    // Backs the S03 fix: case/locale-insensitive female detection.
    [Theory]
    [InlineData("Female")]
    [InlineData("female")]
    [InlineData("F")]
    [InlineData("f")]
    [InlineData("Femenino")]
    [InlineData("femenino")]
    public void Calculate_FemaleVariants_UseFemaleEliminationRate(string sex)
    {
        var canonical = _sut.Calculate(IllegalLevel, false, WeightKg, "female");
        var variant = _sut.Calculate(IllegalLevel, false, WeightKg, sex);

        variant.EstimatedTimeToGreen.Should().Be(canonical.EstimatedTimeToGreen);
    }

    [Theory]
    [InlineData("Male")]
    [InlineData("male")]
    [InlineData("unknown")]
    [InlineData("")]
    [InlineData(null)]
    public void Calculate_NonFemaleOrInvalidValues_UseMaleDefaultRate(string? sex)
    {
        var male = _sut.Calculate(IllegalLevel, false, WeightKg, "Male");
        var actual = _sut.Calculate(IllegalLevel, false, WeightKg, sex);

        // Null/empty short-circuit to default rate (no weight adjustment); compare via category, not exact time.
        if (string.IsNullOrWhiteSpace(sex))
        {
            actual.Color.Should().Be(TrafficLightColor.Yellow);
            actual.EstimatedTimeToGreen.Should().NotBeNull();
        }
        else
        {
            actual.EstimatedTimeToGreen.Should().Be(male.EstimatedTimeToGreen);
        }
    }
}
