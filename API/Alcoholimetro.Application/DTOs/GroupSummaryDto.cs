namespace Alcoholimetro.Application.DTOs;

public record GroupSummaryDto(
    Guid GroupId,
    string GroupName,
    string Role
);