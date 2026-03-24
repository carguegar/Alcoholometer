namespace Alcoholimetro.Application.Commands;

public record CreateGroupCommand(Guid CreatorId, string Name, string Description);
