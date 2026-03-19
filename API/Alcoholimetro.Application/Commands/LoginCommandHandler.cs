using Alcoholimetro.Application.Authentication;
using Alcoholimetro.Domain.Exceptions;
using Alcoholimetro.Domain.Repositories;
using Alcoholimetro.Domain.ValueObjects;

namespace Alcoholimetro.Application.Commands;

public class LoginCommandHandler
{
    private readonly IUserRepository _userRepository;
    private readonly IJwtProvider _jwtProvider; // tokken provider

    public LoginCommandHandler(IUserRepository userRepository, IJwtProvider jwtProvider)
    {
        _userRepository = userRepository;
        _jwtProvider = jwtProvider;
    }

    public async Task<string> ExecuteAsync(LoginCommand command)
    {
        var email = new Email(command.EmailRaw);

        var user = await _userRepository.GetByEmailAsync(email);
        
        if (user == null)
        {
            throw new DomainException("Credenciales incorrectas.");
        }

        bool isPasswordValid = BCrypt.Net.BCrypt.Verify(command.Password, user.PasswordHash);
        
        if (!isPasswordValid)
        {
            throw new DomainException("Credenciales incorrectas.");
        }

        string token = _jwtProvider.Generate(user);

        return token;
    }
}