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

        // Mapeamos de Entidad a DTO (Ocultando el PasswordHash y juntando el nombre)
        return new UserResponseDto(
            Id: user.Id,
            FullName: $"{user.FirstName} {user.LastName} {user.SecondLastName}".Trim(),
            Email: user.Email.Value, // Sacamos el string del Value Object
            Age: user.Age, // Usamos la propiedad calculada
            WeightKg: user.WeightKg,
            HeightCm: user.HeightCm,
            BiologicalSex: user.BiologicalSex,
            IsNoviceDriver: user.IsNoviceDriver,
            HasLicense: user.DriverLicenseDate.HasValue
        );
    }
}