namespace Alcoholimetro.Application.DTOs;

public record GroupDetailsDto(
    Guid GroupId,
    string Name,
    string InvitationCode,
    double AlertThresholdLevel,
    List<GroupMemberDto> Members
);