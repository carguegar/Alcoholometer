using System.Threading.Tasks;
using Alcoholimetro.Domain.Exceptions;
using Alcoholimetro.Domain.Repositories;

namespace Alcoholimetro.Application.Commands;

public class UpdateDeviceTokenCommandHandler
{
    private readonly IUserRepository _userRepository;

    public UpdateDeviceTokenCommandHandler(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public async Task ExecuteAsync(UpdateDeviceTokenCommand command)
    {
        var user = await _userRepository.GetByIdAsync(command.UserId);
        if (user == null)
            throw new DomainException("User not found.");

        user.DevicePushToken = command.DeviceToken;

        await _userRepository.UpdateAsync(user);
    }
}