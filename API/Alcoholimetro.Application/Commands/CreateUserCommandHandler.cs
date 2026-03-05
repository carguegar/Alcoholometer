using Alcoholimetro.Domain.Entities;
using Alcoholimetro.Domain.Repositories;
using Alcoholimetro.Domain.ValueObjects;
using Alcoholimetro.Domain.Exceptions;

namespace Alcoholimetro.Application.Commands;

public class CreateUserCommandHandler
{
    private readonly IUserRepository _userRepository;

    public CreateUserCommandHandler(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public async Task ExecuteAsync(CreateUserCommand command)
    {
        var email = new Email(command.EmailRaw); 

        var existingUser = await _userRepository.GetByEmailAsync(email);
        if (existingUser != null) 
            throw new DomainException("Un usuario con este email ya existe.");

        var user = new User
        {
            FirstName = command.FirstName,
            LastName = command.LastName,
            SecondLastName = command.SecondLastName,
            Email = email, 
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(command.Password),
            BirthDate = command.BirthDate,
            WeightKg = command.WeightKg,
            HeightCm = command.HeightCm,
            BiologicalSex = command.BiologicalSex
        };

        await _userRepository.AddAsync(user);
    }
}