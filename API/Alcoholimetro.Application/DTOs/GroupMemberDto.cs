namespace Alcoholimetro.Application.DTOs;

public record GroupMemberDto(
    Guid UserId,
    string FirstName,
    string LastName,
    string Role
);