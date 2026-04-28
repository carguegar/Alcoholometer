using Alcoholimetro.Application.Authentication;
using Alcoholimetro.Application.DTOs;
using Alcoholimetro.Domain.Exceptions;
using Alcoholimetro.Domain.Repositories;

namespace Alcoholimetro.Application.Commands;

public record LoginResponse(string AccessToken, string RefreshToken);
public class LoginCommandHandler
{
    private readonly IUserRepository _userRepository;
    private readonly IJwtProvider _jwtProvider; // tokken provider

    public LoginCommandHandler(IUserRepository userRepository, IJwtProvider jwtProvider)
    {
        _userRepository = userRepository;
        _jwtProvider = jwtProvider;
    }

    public async Task<LoginResponse> ExecuteAsync(LoginCommand command)
    {
        var user = await _userRepository.GetByEmailAsync(command.EmailRaw);
        if (user == null)
            throw new DomainException("Credenciales incorrectas.");

        bool isPasswordValid = BCrypt.Net.BCrypt.Verify(command.Password, user.PasswordHash);
        
        if (!isPasswordValid)
            throw new DomainException("Credenciales incorrectas.");

        var accessToken = _jwtProvider.Generate(user); 
        var rawRefreshToken = _jwtProvider.GenerateRefreshToken(); 
        var hashedRefreshToken = _jwtProvider.HashRefreshToken(rawRefreshToken);

        user.RefreshToken = hashedRefreshToken;
        user.RefreshTokenExpiryTime = DateTime.UtcNow.AddDays(60); 

        await _userRepository.UpdateAsync(user);

        return new LoginResponse(accessToken, rawRefreshToken);
    }
}