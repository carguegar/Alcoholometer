using Alcoholimetro.Domain.Entities;
using Alcoholimetro.Domain.Enums;
using Alcoholimetro.Domain.Repositories;
using Alcoholimetro.Application.Commands;
public class CreateGroupCommandHandler
{
    private readonly IGroupRepository _groupRepository;

    public CreateGroupCommandHandler(IGroupRepository groupRepository)
    {
        _groupRepository = groupRepository;
    }

    public async Task<Group> ExecuteAsync(CreateGroupCommand command)
    {
        string uniqueCode;
        bool isUnique = false;

        do
        {
            uniqueCode = GenerateCode();
            var existingGroup = await _groupRepository.GetByInvitationCodeAsync(uniqueCode);
            
            if (existingGroup == null)
            {
                isUnique = true;
            }
        } while (!isUnique);

        var group = new Group
        {
            Name = command.Name,
            Description = command.Description,
            InvitationCode = uniqueCode
        };

        await _groupRepository.AddAsync(group);

        var userGroup = new UserGroup
        {
            UserId = command.CreatorId,
            GroupId = group.Id,
            Role = GroupRole.Admin
        };
        
        await _groupRepository.AddUserToGroupAsync(userGroup);

        return group; 
    }

    private string GenerateCode()
    {
        const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        var random = new Random();
        return new string(Enumerable.Repeat(chars, 6)
            .Select(s => s[random.Next(s.Length)]).ToArray());
    }
}