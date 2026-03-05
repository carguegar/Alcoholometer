using System.Text.RegularExpressions;
using Alcoholimetro.Domain.Exceptions;

namespace Alcoholimetro.Domain.ValueObjects;

public record Email
{
    public string Value { get; }

    public Email(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
            throw new InvalidEmailException("empty");

        var emailRegex = new Regex(@"^[^@\s]+@[^@\s]+\.[^@\s]+$");
        if (!emailRegex.IsMatch(value))
            throw new InvalidEmailException(value);

        Value = value;
    }
    public override string ToString() => Value;
}