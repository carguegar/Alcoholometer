using Alcoholimetro.Domain.Entities;

namespace Alcoholimetro.Domain.Repositories;

public interface IMeasurementRepository
{
    Task<List<Measurement>> GetByUserIdAsync(Guid userId, int page, int pageSize);
    Task AddAsync(Measurement measurement);
    Task<List<Measurement>> GetGroupHighScoresAsync(Guid groupId, DateTime? startDate, DateTime? endDate);
}