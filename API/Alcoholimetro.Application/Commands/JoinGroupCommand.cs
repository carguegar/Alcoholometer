namespace Alcoholimetro.Application.Commands;
public record JoinGroupCommand(Guid UserId, string InvitationCode);