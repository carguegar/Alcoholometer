using Alcoholimetro.Domain.Entities;
using Alcoholimetro.Domain.Repositories;
using Alcoholimetro.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Alcoholimetro.Infrastructure.Repositories;

public class MeasurementRepository : IMeasurementRepository
{
    private readonly AlcoholimetroDbContext _context;

    public MeasurementRepository(AlcoholimetroDbContext context)
    {
        _context = context;
    }

    public async Task<List<Measurement>> GetByUserIdAsync(Guid userId)
    {
        return await _context.Measurements
            .Where(m => m.UserId == userId)
            .OrderByDescending(m => m.Timestamp) // order by date, most recent first
            .ToListAsync();
    }

    public async Task AddAsync(Measurement measurement)
    {
        await _context.Measurements.AddAsync(measurement);
        await _context.SaveChangesAsync();
    }
}