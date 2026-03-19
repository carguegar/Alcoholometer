using Alcoholimetro.Application.DTOs;
using Alcoholimetro.Domain.Entities;
using Alcoholimetro.Domain.Repositories;

namespace Alcoholimetro.Application.Queries;

public class GetAllUsersQueryHandler
{
    private readonly IUserRepository _userRepository;

    public GetAllUsersQueryHandler(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public async Task<IEnumerable<UserResponseDto>> ExecuteAsync()
    {
        var users = await _userRepository.GetAllAsync();

        // map each User entity to UserResponseDto
        return users.Select(user => new UserResponseDto(
            Id: user.Id,
            FullName: $"{user.FirstName} {user.LastName} {user.SecondLastName}".Trim(),
            Email: user.Email.Value,
            Age: user.Age,
            WeightKg: user.WeightKg,
            HeightCm: user.HeightCm,
            BiologicalSex: user.BiologicalSex,
            IsNoviceDriver: user.IsNoviceDriver

        ));
    }
}