using Alcoholimetro.Domain.ValueObjects;
namespace Alcoholimetro.Application.Commands;

public record LoginCommand(Email EmailRaw, string Password);