using Alcoholimetro.Application.Commands;
using Alcoholimetro.Application.Services;
using Alcoholimetro.Domain.Entities;
using Alcoholimetro.Domain.Enums;
using Alcoholimetro.Domain.Exceptions;
using Alcoholimetro.Domain.Repositories;
using Alcoholimetro.Domain.Services;
using Alcoholimetro.Domain.ValueObjects;
using FluentAssertions;
using Moq;

namespace Alcoholimetro.Application.Tests.Commands;

public class RecordMeasurementCommandHandlerTests
{
    private readonly Mock<IUserRepository> _userRepo = new();
    private readonly Mock<IMeasurementRepository> _measurementRepo = new();
    private readonly Mock<IAlcoholCalculatorService> _calculator = new();
    private readonly Mock<IGroupRepository> _groupRepo = new();
    private readonly Mock<IPushNotificationService> _push = new();

    private RecordMeasurementCommandHandler CreateSut() =>
        new(_userRepo.Object, _measurementRepo.Object, _calculator.Object, _groupRepo.Object, _push.Object);

    private static User BuildUser(Guid id) => new()
    {
        Id = id,
        FirstName = "Ada",
        LastName = "Lovelace",
        SecondLastName = "Byron",
        Email = new Email("ada@example.com"),
        PasswordHash = "hash",
        BirthDate = new DateOnly(1990, 1, 1),
        WeightKg = 65,
        HeightCm = 170,
        BiologicalSex = "Female",
    };

    [Fact]
    public async Task ExecuteAsync_WithoutUserId_DoesNotPersist_AndUsesGenericCalculation()
    {
        var sut = CreateSut();
        var command = new RecordMeasurementCommand(0.10, UserId: null, Lat: 0, Lng: 0);
        var expected = new AlcoholCalculationResult(TrafficLightColor.Green, "ok", null);

        _calculator.Setup(c => c.Calculate(0.10, false, null, null)).Returns(expected);

        var result = await sut.ExecuteAsync(command);

        result.Should().Be(expected);
        _userRepo.Verify(r => r.GetByIdAsync(It.IsAny<Guid>()), Times.Never);
        _measurementRepo.Verify(r => r.AddAsync(It.IsAny<Measurement>()), Times.Never);
    }

    [Fact]
    public async Task ExecuteAsync_WhenUserNotFound_Throws()
    {
        var sut = CreateSut();
        var userId = Guid.NewGuid();
        _userRepo.Setup(r => r.GetByIdAsync(userId)).ReturnsAsync((User?)null);

        var act = async () => await sut.ExecuteAsync(new RecordMeasurementCommand(0.30, userId, 0, 0));

        await act.Should().ThrowAsync<NotFoundException>();
        _measurementRepo.Verify(r => r.AddAsync(It.IsAny<Measurement>()), Times.Never);
    }

    [Fact]
    public async Task ExecuteAsync_WhenUserExists_PersistsMeasurement()
    {
        var sut = CreateSut();
        var userId = Guid.NewGuid();
        var user = BuildUser(userId);
        var calcResult = new AlcoholCalculationResult(TrafficLightColor.Yellow, "wait", TimeSpan.FromHours(1));

        _userRepo.Setup(r => r.GetByIdAsync(userId)).ReturnsAsync(user);
        _calculator
            .Setup(c => c.Calculate(0.40, user.IsNoviceDriver, user.WeightKg, user.BiologicalSex))
            .Returns(calcResult);
        _groupRepo.Setup(r => r.GetGroupsWithMembersByUserIdAsync(userId)).ReturnsAsync(new List<Group>());

        var result = await sut.ExecuteAsync(new RecordMeasurementCommand(0.40, userId, 40.0, -3.7));

        result.Should().Be(calcResult);
        _measurementRepo.Verify(r => r.AddAsync(It.Is<Measurement>(m =>
            m.UserId == userId &&
            Math.Abs(m.AlcoholLevel - 0.40) < 1e-9 &&
            Math.Abs(m.Location.Lat.Value - 40.0) < 1e-9 &&
            Math.Abs(m.Location.Lon.Value - (-3.7)) < 1e-9)), Times.Once);
        _push.Verify(p => p.SendAlertAsync(It.IsAny<IEnumerable<Guid>>(), It.IsAny<string>(), It.IsAny<string>()), Times.Never);
    }

    [Fact]
    public async Task ExecuteAsync_WithInvalidCoordinates_ThrowsDomainException()
    {
        var sut = CreateSut();
        var userId = Guid.NewGuid();
        var user = BuildUser(userId);

        _userRepo.Setup(r => r.GetByIdAsync(userId)).ReturnsAsync(user);
        _calculator
            .Setup(c => c.Calculate(It.IsAny<double>(), It.IsAny<bool>(), It.IsAny<double?>(), It.IsAny<string?>()))
            .Returns(new AlcoholCalculationResult(TrafficLightColor.Green, "ok", null));

        var act = async () => await sut.ExecuteAsync(new RecordMeasurementCommand(0.10, userId, 999, 0));

        await act.Should().ThrowAsync<InvalidLatitudeException>();
        _measurementRepo.Verify(r => r.AddAsync(It.IsAny<Measurement>()), Times.Never);
    }
}
