using Alcoholimetro.Application.Commands;
using Alcoholimetro.Application.Queries;
using Alcoholimetro.Domain.Exceptions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;

namespace Alcoholimetro.Api.Controllers;

[ApiController]
[Route("api/[controller]")] // api/users
[Authorize]
public class UsersController : ControllerBase
{
    private readonly CreateUserCommandHandler _createHandler;
    private readonly UpdateUserCommandHandler _updateHandler;
    private readonly DeleteUserCommandHandler _deleteHandler;
    private readonly GetUserByIdQueryHandler _getByIdHandler;
    private readonly GetAllUsersQueryHandler _getAllHandler;
    private readonly LoginCommandHandler _loginHandler;
    private readonly UpdateDeviceTokenCommandHandler _updateDeviceTokenHandler;

    public UsersController(
        CreateUserCommandHandler createHandler,
        UpdateUserCommandHandler updateHandler,
        DeleteUserCommandHandler deleteHandler,
        GetUserByIdQueryHandler getByIdHandler,
        GetAllUsersQueryHandler getAllHandler,
        LoginCommandHandler loginHandler,
        UpdateDeviceTokenCommandHandler updateDeviceTokenHandler)
    {
        _createHandler = createHandler;
        _updateHandler = updateHandler;
        _deleteHandler = deleteHandler;
        _getByIdHandler = getByIdHandler;
        _getAllHandler = getAllHandler;
        _loginHandler = loginHandler;
        _updateDeviceTokenHandler = updateDeviceTokenHandler;
    }

    // GET: api/users
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var users = await _getAllHandler.ExecuteAsync();
        return Ok(users); // 200 OK 
    }

    // GET: api/users/{id}
    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var user = await _getByIdHandler.ExecuteAsync(new GetUserByIdQuery(id));
        return Ok(user);
    }

    // POST: api/users
    [HttpPost]
    [AllowAnonymous]
    public async Task<IActionResult> Create([FromBody] CreateUserCommand command)
    {
        await _createHandler.ExecuteAsync(command);
        return CreatedAtAction(nameof(GetById), new { id = command.EmailRaw }, new { message = "Usuario creado con éxito." });
    }

    // PUT: api/users/{id}
    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateUserCommand command)
    {
        if (id != command.UserId)
            return BadRequest(new { error = "El ID de la ruta no coincide con el del cuerpo." });

        await _updateHandler.ExecuteAsync(command);
        return Ok(new { message = "Usuario actualizado con éxito." });
    }

    // DELETE: api/users/{id}
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        await _deleteHandler.ExecuteAsync(new DeleteUserCommand(id));
        return NoContent(); // 204 No Content
    }

    [HttpPost("login")]
    [AllowAnonymous] 
    public async Task<IActionResult> Login([FromBody] LoginCommand command)
    {
        var response = await _loginHandler.ExecuteAsync(command);
        return Ok(response);
    }

    [HttpPost("refresh")]
    [AllowAnonymous]
    public async Task<IActionResult> RefreshToken(
        [FromBody] RefreshTokenCommand command, 
        [FromServices] RefreshTokenCommandHandler handler)
    {
        var response = await handler.ExecuteAsync(command);
        return Ok(response);
    }
    [HttpPut("device-token")]
    public async Task<IActionResult> UpdateDeviceToken([FromBody] string deviceToken)
    {
        var userIdString = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdString, out Guid userId)) 
            return Unauthorized(new { error = "Token inválido." });

        var command = new UpdateDeviceTokenCommand(userId, deviceToken);
        await _updateDeviceTokenHandler.ExecuteAsync(command);
        return Ok(new { message = "Device token actualizado con éxito." });
    }}