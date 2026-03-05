using Alcoholimetro.Domain.Repositories;

namespace Alcoholimetro.Application.Commands;

public class DeleteUserCommandHandler
{
    private readonly IUserRepository _userRepository;

    public DeleteUserCommandHandler(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public async Task ExecuteAsync(DeleteUserCommand command)
    {
        await _userRepository.DeleteAsync(command.UserId);
    }
}