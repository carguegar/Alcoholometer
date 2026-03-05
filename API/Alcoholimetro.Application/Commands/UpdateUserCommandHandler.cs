using Alcoholimetro.Domain.Repositories;
using Alcoholimetro.Domain.Exceptions;

namespace Alcoholimetro.Application.Commands;

public class UpdateUserCommandHandler
{
    private readonly IUserRepository _userRepository;

    public UpdateUserCommandHandler(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public async Task ExecuteAsync(UpdateUserCommand command)
    {
        // find user by id
        var user = await _userRepository.GetByIdAsync(command.UserId);
        
        if (user == null) 
            throw new DomainException($"No se encontró el usuario");

        // modify the user with the new data
        user.WeightKg = command.WeightKg;
        user.HeightCm = command.HeightCm;

        // save the changes
        await _userRepository.UpdateAsync(user);
    }
}