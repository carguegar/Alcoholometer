using System.Security.Claims;
using Alcoholimetro.Application.Authentication;
using Alcoholimetro.Domain.Repositories;
using Alcoholimetro.Domain.Exceptions;

namespace Alcoholimetro.Application.Commands;

public class RefreshTokenCommandHandler
{
    private readonly IUserRepository _userRepository;
    private readonly IJwtProvider _jwtProvider;

    public RefreshTokenCommandHandler(IUserRepository userRepository, IJwtProvider jwtProvider)
    {
        _userRepository = userRepository;
        _jwtProvider = jwtProvider;
    }

    public async Task<LoginResponse> ExecuteAsync(RefreshTokenCommand command)
    {
        // extract user id from expired access token
        var principal = _jwtProvider.GetPrincipalFromExpiredToken(command.AccessToken);
        
        if (principal == null)
            throw new DomainException("Access Token inválido.");

        var userIdString = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        if (!Guid.TryParse(userIdString, out Guid userId))
            throw new DomainException("Access Token inválido.");

        var user = await _userRepository.GetByIdAsync(userId);

        var hashedInputToken = _jwtProvider.HashRefreshToken(command.RefreshToken);
        
        if (user == null || 
            user.RefreshToken != hashedInputToken || 
            user.RefreshTokenExpiryTime <= DateTime.UtcNow)
        {
            throw new DomainException("Petición de Refresh Token inválida o expirada. Vuelva a iniciar sesión.");
        }

        var newAccessToken = _jwtProvider.Generate(user);
        var newRawRefreshToken = _jwtProvider.GenerateRefreshToken();
        var newHashedRefreshToken = _jwtProvider.HashRefreshToken(newRawRefreshToken);

        user.RefreshToken = newHashedRefreshToken;
        user.RefreshTokenExpiryTime = DateTime.UtcNow.AddDays(60);

        await _userRepository.UpdateAsync(user);

        return new LoginResponse(newAccessToken, newRawRefreshToken);
    }
}