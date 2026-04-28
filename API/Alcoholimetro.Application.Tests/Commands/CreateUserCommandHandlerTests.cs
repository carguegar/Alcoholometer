using Alcoholimetro.Application.Commands;
using Alcoholimetro.Domain.Entities;
using Alcoholimetro.Domain.Exceptions;
using Alcoholimetro.Domain.Repositories;
using Alcoholimetro.Domain.ValueObjects;
using FluentAssertions;
using Moq;

namespace Alcoholimetro.Application.Tests.Commands;

public class CreateUserCommandHandlerTests
{
    private readonly Mock<IUserRepository> _userRepo = new();

    private CreateUserCommandHandler CreateSut() => new(_userRepo.Object);

    private static CreateUserCommand BuildCommand(string password = "Abc12345", string email = "alice@example.com") => new(
        FirstName: "Alice",
        LastName: "Doe",
        SecondLastName: "Smith",
        EmailRaw: email,
        Password: password,
        BirthDate: new DateOnly(1990, 1, 1),
        WeightKg: 65,
        HeightCm: 170,
        BiologicalSex: "Female",
        DrivingLicenseIssueDate: null
    );

    [Theory]
    [InlineData("")]
    [InlineData("Abc1234")]   // 7 chars
    [InlineData("Abcdefgh")]  // no digit
    [InlineData("12345678")]  // no letter
    public async Task ExecuteAsync_WithInvalidPassword_ThrowsDomainException(string password)
    {
        var sut = CreateSut();

        var act = async () => await sut.ExecuteAsync(BuildCommand(password: password));

        await act.Should().ThrowAsync<DomainException>();
        _userRepo.Verify(r => r.AddAsync(It.IsAny<User>()), Times.Never);
    }

    [Fact]
    public async Task ExecuteAsync_WithNullPassword_ThrowsDomainException()
    {
        var sut = CreateSut();

        var act = async () => await sut.ExecuteAsync(BuildCommand(password: null!));

        await act.Should().ThrowAsync<DomainException>();
    }

    [Fact]
    public async Task ExecuteAsync_WithValidData_PersistsUser_AndReturnsId()
    {
        var sut = CreateSut();
        _userRepo.Setup(r => r.GetByEmailAsync(It.IsAny<Email>())).ReturnsAsync((User?)null);

        var id = await sut.ExecuteAsync(BuildCommand());

        id.Should().NotBe(Guid.Empty);
        _userRepo.Verify(r => r.AddAsync(It.Is<User>(u =>
            u.Id == id &&
            u.Email.Value == "alice@example.com" &&
            !string.IsNullOrEmpty(u.PasswordHash) &&
            u.PasswordHash != "Abc12345")), Times.Once);
    }

    [Fact]
    public async Task ExecuteAsync_WhenEmailAlreadyExists_ThrowsDomainException()
    {
        var sut = CreateSut();
        _userRepo
            .Setup(r => r.GetByEmailAsync(It.IsAny<Email>()))
            .ReturnsAsync(new User { Email = new Email("alice@example.com") });

        var act = async () => await sut.ExecuteAsync(BuildCommand());

        await act.Should().ThrowAsync<DomainException>()
            .WithMessage("*ya existe*");
        _userRepo.Verify(r => r.AddAsync(It.IsAny<User>()), Times.Never);
    }

    [Fact]
    public async Task ExecuteAsync_WithInvalidEmail_ThrowsInvalidEmailException()
    {
        var sut = CreateSut();

        var act = async () => await sut.ExecuteAsync(BuildCommand(email: "no-arroba"));

        await act.Should().ThrowAsync<InvalidEmailException>();
        _userRepo.Verify(r => r.AddAsync(It.IsAny<User>()), Times.Never);
    }
}
