namespace Alcoholimetro.Application.Commands;

public record RemoveMemberCommand(Guid RequestingUserId, Guid TargetUserId, Guid GroupId);
