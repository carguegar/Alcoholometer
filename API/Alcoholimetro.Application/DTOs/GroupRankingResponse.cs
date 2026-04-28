namespace Alcoholimetro.Application.DTOs;

public record GroupRankingResponse(
    Guid GroupId,
    string GroupName,
    List<MemberRankingDto> Rankings
);
