using Alcoholimetro.Domain.Entities;
using Alcoholimetro.Domain.Repositories;
using Alcoholimetro.Domain.ValueObjects;
using Alcoholimetro.Domain.Exceptions;

namespace Alcoholimetro.Application.Commands;

public class RecordMeasurementCommandHandler
{
    private readonly IMeasurementRepository _measurementRepository;
    private readonly IUserRepository _userRepository;

    public RecordMeasurementCommandHandler(IMeasurementRepository measurementRepository, IUserRepository userRepository)
    {
        _measurementRepository = measurementRepository;
        _userRepository = userRepository;
    }

    public async Task ExecuteAsync(RecordMeasurementCommand command)
    {
        // validations user exists
        var user = await _userRepository.GetByIdAsync(command.UserId);
        if (user == null) throw new DomainException("Usuario no encontrado.");

        // value objects for location
        var location = new Coordinates(
            new Latitude(command.Latitude), 
            new Longitude(command.Longitude)
        );

        var measurement = new Measurement
        {
            UserId = command.UserId,
            AlcoholLevel = command.AlcoholLevel,
            Location = location
        };

        await _measurementRepository.AddAsync(measurement);
    }
}