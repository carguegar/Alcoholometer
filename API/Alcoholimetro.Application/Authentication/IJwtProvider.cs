using Alcoholimetro.Domain.Entities;
using System.Security.Claims;

namespace Alcoholimetro.Application.Authentication;

public interface IJwtProvider
{
    string Generate(User user); 
    string GenerateRefreshToken();
    ClaimsPrincipal GetPrincipalFromExpiredToken(string token);
    string HashRefreshToken(string token);
}