using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Alcoholimetro.Application.Commands;
using Alcoholimetro.Application.Queries;
using System.Security.Claims; // read claims from JWT

namespace Alcoholimetro.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] 
public class GroupsController : ControllerBase
{
    private readonly CreateGroupCommandHandler _createHandler;
    private readonly JoinGroupCommandHandler _joinHandler;
    private readonly GetGroupRankingQueryHandler _getGroupRankingHandler;
    private readonly GetUserGroupsQueryHandler _getUserGroupsHandler;
    private readonly GetGroupDetailsQueryHandler _getGroupDetailsHandler;
    private readonly RemoveMemberCommandHandler _removeMemberHandler;
    private readonly PromoteToAdminCommandHandler _promoteToAdminHandler;
    private readonly UpdateGroupConfigCommandHandler _updateGroupConfigHandler;

    public GroupsController(
        CreateGroupCommandHandler createHandler, 
        JoinGroupCommandHandler joinHandler,
        GetGroupRankingQueryHandler getGroupRankingHandler,
        GetUserGroupsQueryHandler getUserGroupsHandler,
        GetGroupDetailsQueryHandler getGroupDetailsHandler,
        RemoveMemberCommandHandler removeMemberHandler,
        PromoteToAdminCommandHandler promoteToAdminHandler,
        UpdateGroupConfigCommandHandler updateGroupConfigHandler)
    {
        _createHandler = createHandler;
        _joinHandler = joinHandler;
        _getGroupRankingHandler = getGroupRankingHandler;
        _getUserGroupsHandler = getUserGroupsHandler;
        _getGroupDetailsHandler = getGroupDetailsHandler;
        _removeMemberHandler = removeMemberHandler;
        _promoteToAdminHandler = promoteToAdminHandler;
        _updateGroupConfigHandler = updateGroupConfigHandler;
    }

    // POST: api/groups
    [HttpPost]
    public async Task<IActionResult> CreateGroup([FromBody] CreateGroupRequest request)
    {
        // extract user ID from JWT token
        var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdString, out Guid userId)) 
            return Unauthorized(new { error = "Token inválido o usuario no encontrado." });

        var command = new CreateGroupCommand(userId, request.Name, request.Description);
        
        var group = await _createHandler.ExecuteAsync(command);

        return CreatedAtAction(nameof(GetGroupDetails), new { groupId = group.Id }, new 
        { 
            message = "Grupo creado con éxito.", 
            groupId = group.Id, 
            invitationCode = group.InvitationCode 
        });
    }

    // POST: api/groups/join
    [HttpPost("join")]
    public async Task<IActionResult> JoinGroup([FromBody] JoinGroupRequest request)
    {
        var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdString, out Guid userId)) 
            return Unauthorized(new { error = "Token inválido." });

        var command = new JoinGroupCommand(userId, request.InvitationCode);
        
        await _joinHandler.ExecuteAsync(command);
        return Ok(new { message = "Te has unido al grupo correctamente." });
    }

    // GET: api/groups/{groupId}/ranking
    [HttpGet("{groupId}/ranking")]
    public async Task<IActionResult> GetGroupRanking(
        [FromRoute] Guid groupId, 
        [FromQuery] DateTime? startDate, 
        [FromQuery] DateTime? endDate)
    {
        var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdString, out Guid userId)) 
            return Unauthorized(new { error = "Token inválido." });

        var query = new GetGroupRankingQuery(groupId, userId, startDate, endDate);
        var response = await _getGroupRankingHandler.ExecuteAsync(query);
        return Ok(response);
    }

    // GET: api/groups
    [HttpGet]
    public async Task<IActionResult> GetUserGroups()
    {
        var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdString, out Guid userId)) 
            return Unauthorized(new { error = "Token inválido." });

        var query = new GetUserGroupsQuery(userId);
        var response = await _getUserGroupsHandler.ExecuteAsync(query);
        return Ok(response);
    }

    // GET: api/groups/{groupId}
    [HttpGet("{groupId}")]
    public async Task<IActionResult> GetGroupDetails(Guid groupId)
    {
        var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdString, out Guid userId)) 
            return Unauthorized(new { error = "Token inválido." });

        var query = new GetGroupDetailsQuery(groupId, userId);
        var response = await _getGroupDetailsHandler.ExecuteAsync(query);
        return Ok(response);
    }

    // DELETE: api/groups/{groupId}/leave
    [HttpDelete("{groupId}/leave")]
    public async Task<IActionResult> LeaveGroup(Guid groupId)
    {
        var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdString, out Guid userId)) 
            return Unauthorized(new { error = "Token inválido." });

        var command = new RemoveMemberCommand(userId, userId, groupId);
        await _removeMemberHandler.ExecuteAsync(command);
        return Ok(new { message = "Has abandonado el grupo correctamente." });
    }

    // DELETE: api/groups/{groupId}/members/{targetUserId}
    [HttpDelete("{groupId}/members/{targetUserId}")]
    public async Task<IActionResult> KickMember(Guid groupId, Guid targetUserId)
    {
        var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdString, out Guid userId)) 
            return Unauthorized(new { error = "Token inválido." });

        var command = new RemoveMemberCommand(userId, targetUserId, groupId);
        await _removeMemberHandler.ExecuteAsync(command);
        return Ok(new { message = "Miembro expulsado correctamente." });
    }

    // PUT: api/groups/{groupId}/members/{targetUserId}/admin
    [HttpPut("{groupId}/members/{targetUserId}/admin")]
    public async Task<IActionResult> PromoteToAdmin(Guid groupId, Guid targetUserId)
    {
        var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdString, out Guid userId)) 
            return Unauthorized(new { error = "Token inválido." });

        var command = new PromoteToAdminCommand(userId, targetUserId, groupId);
        await _promoteToAdminHandler.ExecuteAsync(command);
        return Ok(new { message = "Miembro ascendido a administrador." });
    }

    // PUT: api/groups/{groupId}/config
    [HttpPut("{groupId}/config")]
    public async Task<IActionResult> UpdateGroupConfig(Guid groupId, [FromBody] double alertThresholdLevel)
    {
        var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdString, out Guid userId)) 
            return Unauthorized(new { error = "Token inválido." });

        var command = new UpdateGroupConfigCommand(groupId, userId, alertThresholdLevel);
        await _updateGroupConfigHandler.ExecuteAsync(command);
        return Ok(new { message = "Configuración del grupo actualizada correctamente." });
    }
}

// DTOs for swagger ease of use
public record CreateGroupRequest(string Name, string Description);
public record JoinGroupRequest(string InvitationCode);