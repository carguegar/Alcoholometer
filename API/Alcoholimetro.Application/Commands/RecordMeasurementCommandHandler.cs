using Alcoholimetro.Domain.Entities;
using Alcoholimetro.Domain.Exceptions;
using Alcoholimetro.Domain.Repositories;
using Alcoholimetro.Domain.ValueObjects;
using Alcoholimetro.Domain.Services;
using Alcoholimetro.Application.Services;

namespace Alcoholimetro.Application.Commands;

public class RecordMeasurementCommandHandler
{
    private readonly IUserRepository _userRepository;
    private readonly IMeasurementRepository _measurementRepository;
    private readonly IAlcoholCalculatorService _calculatorService;
    private readonly IGroupRepository _groupRepository;
    private readonly IPushNotificationService _pushNotificationService;

    public RecordMeasurementCommandHandler(
        IUserRepository userRepository, 
        IMeasurementRepository measurementRepository,
        IAlcoholCalculatorService calculatorService,
        IGroupRepository groupRepository,
        IPushNotificationService pushNotificationService)
    {
        _userRepository = userRepository;
        _measurementRepository = measurementRepository;
        _calculatorService = calculatorService;
        _groupRepository = groupRepository;
        _pushNotificationService = pushNotificationService;
    }

    public async Task<AlcoholCalculationResult> ExecuteAsync(RecordMeasurementCommand command)
    {
        // Anonymous User Flow
        if (!command.UserId.HasValue)
        {
            // We assume false for novice driver since we don't know the user
            return _calculatorService.Calculate(command.MeasurementLevel, isNoviceDriver: false);
        }

        // Logged-in User Flow
        var user = await _userRepository.GetByIdAsync(command.UserId.Value) 
            ?? throw new NotFoundException("User not found.");

        var result = _calculatorService.Calculate(
            measurementLevel: command.MeasurementLevel,
            isNoviceDriver: user.IsNoviceDriver,
            weightKg: user.WeightKg,
            biologicalSex: user.BiologicalSex
        );

        
        // Save the measurement to the database
        Latitude lat = new Latitude(command.Lat);
        Longitude lng = new Longitude(command.Lng);
        var measurement = new Measurement
        {
            UserId = user.Id,
            AlcoholLevel = command.MeasurementLevel,
            Location = new Coordinates(lat, lng),
            Timestamp = DateTime.UtcNow
        };

        await _measurementRepository.AddAsync(measurement);

        // Trigger group broadcast if measurement exceeds Group limits
        var userGroups = await _groupRepository.GetGroupsWithMembersByUserIdAsync(user.Id);

        foreach (var group in userGroups)
        {
            var threshold = group.Configuration?.AlertThresholdLevel ?? 0.60;

            if (command.MeasurementLevel >= threshold)
            {
                var otherMemberIds = group.Members
                    .Select(m => m.UserId)
                    .Where(id => id != user.Id)
                    .ToList();

                // Notification to other group members
                if (otherMemberIds.Any())
                {
                    string mapsUrl = $"https://maps.google.com/?q={command.Lat.ToString(System.Globalization.CultureInfo.InvariantCulture)},{command.Lng.ToString(System.Globalization.CultureInfo.InvariantCulture)}";
                    await _pushNotificationService.SendAlertAsync(
                        otherMemberIds, 
                        $"¡Alerta en {group.Name}!", 
                        $"{user.FirstName} ha registrado {command.MeasurementLevel} mg/L. Ubicación: {mapsUrl}"
                    );
                }

                // Notification to the user themselves
                await _pushNotificationService.SendAlertAsync(
                    new List<Guid> { user.Id },
                    $"¡Límite superado en {group.Name}!",
                    $"Has registrado una tasa de {command.MeasurementLevel} mg/L superando el límite del grupo. Por favor, ¡no conduzcas!"
                );
            }
        }

        return result;
    }
}