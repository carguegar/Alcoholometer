using Alcoholimetro.Application.DTOs;
using Alcoholimetro.Domain.Repositories;

namespace Alcoholimetro.Application.Queries;

public class GetMeasurementsByUserIdQueryHandler
{
    private readonly IMeasurementRepository _measurementRepository;

    public GetMeasurementsByUserIdQueryHandler(IMeasurementRepository measurementRepository)
    {
        _measurementRepository = measurementRepository;
    }

    public async Task<IEnumerable<MeasurementResponseDto>> ExecuteAsync(GetMeasurementsByUserIdQuery query)
    {
        var measurements = await _measurementRepository.GetByUserIdAsync(query.UserId, query.Page, query.PageSize);

        return measurements.Select(m => new MeasurementResponseDto(
            Id: m.Id,
            UserId: m.UserId,
            AlcoholLevel: m.AlcoholLevel,
            Timestamp: m.Timestamp,
            Latitude: m.Location.Lat.Value,
            Longitude: m.Location.Lon.Value
        ));
    }
}