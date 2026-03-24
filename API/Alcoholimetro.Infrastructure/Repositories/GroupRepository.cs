using Alcoholimetro.Domain.Entities;
using Alcoholimetro.Domain.Repositories;
using Alcoholimetro.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Alcoholimetro.Infrastructure.Repositories;

public class GroupRepository : IGroupRepository
{
    private readonly AlcoholimetroDbContext _context;

    public GroupRepository(AlcoholimetroDbContext context)
    {
        _context = context;
    }

    public async Task AddAsync(Group group)
    {
        await _context.Groups.AddAsync(group);
        await _context.SaveChangesAsync();
    }

    public async Task<Group?> GetByInvitationCodeAsync(string code)
    {
        return await _context.Groups
            .FirstOrDefaultAsync(g => g.InvitationCode.ToUpper() == code.ToUpper());
    }

    public async Task AddUserToGroupAsync(UserGroup userGroup)
    {
        await _context.UserGroups.AddAsync(userGroup);
        await _context.SaveChangesAsync();
    }

    public async Task<bool> IsUserInGroupAsync(Guid userId, Guid groupId)
    {
        return await _context.UserGroups
            .AnyAsync(ug => ug.UserId == userId && ug.GroupId == groupId);
    }
}