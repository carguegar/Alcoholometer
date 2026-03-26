using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Alcoholimetro.Application.Commands;
using System.Security.Claims; // read claims from JWT

namespace Alcoholimetro.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] 
public class GroupsController : ControllerBase
{
    private readonly CreateGroupCommandHandler _createHandler;
    private readonly JoinGroupCommandHandler _joinHandler;

    public GroupsController(
        CreateGroupCommandHandler createHandler, 
        JoinGroupCommandHandler joinHandler)
    {
        _createHandler = createHandler;
        _joinHandler = joinHandler;
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

        return Ok(new 
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
        
        try 
        {
            await _joinHandler.ExecuteAsync(command);
            return Ok(new { message = "Te has unido al grupo correctamente." });
        }
        catch(Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}

// DTOs for swagger ease of use
public record CreateGroupRequest(string Name, string Description);
public record JoinGroupRequest(string InvitationCode);