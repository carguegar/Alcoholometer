using Alcoholimetro.Application.DTOs;
using Alcoholimetro.Domain.Repositories;
using Alcoholimetro.Domain.Exceptions;

namespace Alcoholimetro.Application.Queries;

public class GetUserByIdQueryHandler
{
    private readonly IUserRepository _userRepository;

    public GetUserByIdQueryHandler(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public async Task<UserResponseDto> ExecuteAsync(GetUserByIdQuery query)
    {
        var user = await _userRepository.GetByIdAsync(query.UserId);
        
        if (user == null)
            throw new DomainException($"No se encontró el usuario con ID: {query.UserId}");

        // map the User entity to UserResponseDto
        return new UserResponseDto(
            Id: user.Id,
            FullName: $"{user.FirstName} {user.LastName} {user.SecondLastName}".Trim(),
            Email: user.Email.Value, // string from the Email value object
            Age: user.Age,
            WeightKg: user.WeightKg,
            HeightCm: user.HeightCm,
            BiologicalSex: user.BiologicalSex
        );
    }
}