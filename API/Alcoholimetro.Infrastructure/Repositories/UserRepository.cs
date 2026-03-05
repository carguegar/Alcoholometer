using Alcoholimetro.Domain.Entities;
using Alcoholimetro.Domain.Repositories;
using Alcoholimetro.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Alcoholimetro.Domain.ValueObjects;

namespace Alcoholimetro.Infrastructure.Repositories;

public class UserRepository : IUserRepository //implement the IUserRepository interface
{
    private readonly AlcoholimetroDbContext _context;

    public UserRepository(AlcoholimetroDbContext context)
    {
        _context = context;
    }

    public async Task<User?> GetByIdAsync(Guid id)
    {
        return await _context.Users.FindAsync(id);
    }

    public async Task<User?> GetByEmailAsync(Email email)
    {
        return await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
    }

    public async Task<IEnumerable<User>> GetAllAsync()
    {
        // AsNoTracking() is used to improve performance when we only want to read data without modifying it
        return await _context.Users.AsNoTracking().ToListAsync();
    }

    public async Task AddAsync(User user)
    {
        await _context.Users.AddAsync(user);
        await _context.SaveChangesAsync();
    }

    public async Task UpdateAsync(User user)
    {
        _context.Users.Update(user);
        await _context.SaveChangesAsync();
    }

    public async Task DeleteAsync(Guid id)
    {
        var user = await GetByIdAsync(id);
        if (user != null)
        {
            _context.Users.Remove(user);
            await _context.SaveChangesAsync();
        }
    }
}