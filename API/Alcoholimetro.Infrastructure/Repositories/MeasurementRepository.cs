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

    public async Task<List<Measurement>> GetByUserIdAsync(Guid userId, int page, int pageSize)
    {
        return await _context.Measurements
            .AsNoTracking()
            .Where(m => m.UserId == userId)
            .OrderByDescending(m => m.Timestamp) // order by date, most recent first
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();
    }

    public async Task AddAsync(Measurement measurement)
    {
        await _context.Measurements.AddAsync(measurement);
        await _context.SaveChangesAsync();
    }

    public async Task<List<Measurement>> GetGroupHighScoresAsync(Guid groupId, DateTime? startDate, DateTime? endDate)
    {
        var groupUsersQuery = _context.UserGroups
            .Where(ug => ug.GroupId == groupId)
            .Select(ug => ug.UserId);

        var measurementsQuery = _context.Measurements
            .AsNoTracking()
            .Where(m => groupUsersQuery.Contains(m.UserId));

        if (startDate.HasValue)
            measurementsQuery = measurementsQuery.Where(m => m.Timestamp >= startDate.Value);

        if (endDate.HasValue)
            measurementsQuery = measurementsQuery.Where(m => m.Timestamp <= endDate.Value);

        var topRecords = await measurementsQuery
            .GroupBy(m => m.UserId)
            .Select(g => g.OrderByDescending(x => x.AlcoholLevel).FirstOrDefault())
            .ToListAsync();

        return topRecords.Where(r => r != null).ToList()!;
    }
}