using Alcoholimetro.Domain.Entities;
using Alcoholimetro.Domain.ValueObjects;


namespace Alcoholimetro.Domain.Repositories;

public interface IUserRepository
{
    Task<User?> GetByIdAsync(Guid id);
    Task<User?> GetByEmailAsync(Email email);
    Task AddAsync(User user);
    Task UpdateAsync(User user);
    Task DeleteAsync(Guid id);
    Task<IEnumerable<User>> GetAllAsync();
    Task<Dictionary<Guid, User>> GetUsersByIdsAsync(IEnumerable<Guid> userIds);
}