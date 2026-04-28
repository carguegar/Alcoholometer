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

    public async Task UpdateAsync(Group group)
    {
        _context.Groups.Update(group);
        await _context.SaveChangesAsync();
    }

    public async Task<UserGroup?> GetUserGroupAsync(Guid userId, Guid groupId)
    {
        return await _context.UserGroups
            .FirstOrDefaultAsync(ug => ug.UserId == userId && ug.GroupId == groupId);
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

    public async Task<string?> GetGroupNameByIdAsync(Guid groupId)
    {
        return await _context.Groups
            .Where(g => g.Id == groupId)
            .Select(g => g.Name)
            .FirstOrDefaultAsync();
    }

    public async Task<List<Group>> GetGroupsWithMembersByUserIdAsync(Guid userId)
    {
        var groupIds = await _context.UserGroups
            .AsNoTracking()
            .Where(ug => ug.UserId == userId)
            .Select(ug => ug.GroupId)
            .ToListAsync();

        return await _context.Groups
            .AsNoTracking()
            .Include(g => g.Configuration)
            .Include(g => g.Members)
            .Where(g => groupIds.Contains(g.Id))
            .ToListAsync();
    }

    public async Task<List<UserGroup>> GetUserGroupsByUserIdAsync(Guid userId)
    {
        return await _context.UserGroups
            .AsNoTracking()
            .Include(ug => ug.Group)
            .Where(ug => ug.UserId == userId)
            .ToListAsync();
    }

    public async Task<Group?> GetGroupWithMembersAsync(Guid groupId)
    {
        return await _context.Groups
            .Include(g => g.Members)
                .ThenInclude(m => m.User)
            .FirstOrDefaultAsync(g => g.Id == groupId);
    }

    public async Task RemoveUserFromGroupAsync(Guid userId, Guid groupId)
    {
        var userGroup = await _context.UserGroups
            .FirstOrDefaultAsync(ug => ug.UserId == userId && ug.GroupId == groupId);
        
        if (userGroup != null)
        {
            _context.UserGroups.Remove(userGroup);
            await _context.SaveChangesAsync();
        }
    }

    public async Task<int> GetGroupMemberCountAsync(Guid groupId)
    {
        return await _context.UserGroups
            .CountAsync(ug => ug.GroupId == groupId);
    }

    public async Task DeleteGroupAsync(Guid groupId)
    {
        var group = await _context.Groups.FindAsync(groupId);
        if (group != null)
        {
            _context.Groups.Remove(group);
            await _context.SaveChangesAsync();
        }
    }
}