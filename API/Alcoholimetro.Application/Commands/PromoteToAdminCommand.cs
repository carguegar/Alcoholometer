namespace Alcoholimetro.Application.Commands;

public record PromoteToAdminCommand(Guid RequestingUserId, Guid TargetUserId, Guid GroupId);
