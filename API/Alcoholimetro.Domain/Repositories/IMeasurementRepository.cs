using Alcoholimetro.Domain.Entities;

namespace Alcoholimetro.Domain.Repositories;

public interface IMeasurementRepository
{
    Task<List<Measurement>> GetByUserIdAsync(Guid userId);
    Task AddAsync(Measurement measurement);
}