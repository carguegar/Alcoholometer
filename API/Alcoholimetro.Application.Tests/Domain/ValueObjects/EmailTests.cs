using Alcoholimetro.Domain.Exceptions;
using Alcoholimetro.Domain.ValueObjects;
using FluentAssertions;

namespace Alcoholimetro.Application.Tests.Domain.ValueObjects;

public class EmailTests
{
    [Theory]
    [InlineData("a@b.com")]
    [InlineData("user.name@example.org")]
    [InlineData("u+tag@sub.domain.io")]
    public void Constructor_AcceptsValidEmail(string value)
    {
        var email = new Email(value);
        email.Value.Should().Be(value);
        email.ToString().Should().Be(value);
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData("sin-arroba")]
    [InlineData("a@")]
    [InlineData("@b.com")]
    [InlineData("a@b")]
    public void Constructor_RejectsInvalidEmail(string value)
    {
        var act = () => new Email(value);
        act.Should().Throw<InvalidEmailException>();
    }

    [Fact]
    public void Constructor_RejectsNull()
    {
        var act = () => new Email(null!);
        act.Should().Throw<InvalidEmailException>();
    }
}
