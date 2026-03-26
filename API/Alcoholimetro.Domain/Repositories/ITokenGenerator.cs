namespace Alcoholimetro.Domain.Repositories; // O Services

public interface ITokenGenerator
{
    string GenerateAccessToken(Guid userId, string email);
    string GenerateRefreshToken();
}