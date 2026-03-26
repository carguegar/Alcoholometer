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

    public UsersController(
        CreateUserCommandHandler createHandler,
        UpdateUserCommandHandler updateHandler,
        DeleteUserCommandHandler deleteHandler,
        GetUserByIdQueryHandler getByIdHandler,
        GetAllUsersQueryHandler getAllHandler,
        LoginCommandHandler loginHandler)
    {
        _createHandler = createHandler;
        _updateHandler = updateHandler;
        _deleteHandler = deleteHandler;
        _getByIdHandler = getByIdHandler;
        _loginHandler = loginHandler;
        _getAllHandler = getAllHandler;
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
        try
        {
            var user = await _getByIdHandler.ExecuteAsync(new GetUserByIdQuery(id));
            return Ok(user);
        }
        catch (DomainException ex)
        {
            return NotFound(new { error = ex.Message }); // 404 Not Found 
        }
    }

    // POST: api/users
    [HttpPost]
    [AllowAnonymous]
    public async Task<IActionResult> Create([FromBody] CreateUserCommand command)
    {
        try
        {
            await _createHandler.ExecuteAsync(command);
            return StatusCode(201, new { message = "Usuario creado con éxito." }); // 201 Created
        }
        catch (DomainException ex)
        {
            return BadRequest(new { error = ex.Message }); // 400 Bad Request
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = "Error interno del servidor.", details = ex.Message });
        }
    }

    // PUT: api/users/{id}
    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateUserCommand command)
    {
        try
        {
            // sequirity check
            if (id != command.UserId)
                return BadRequest(new { error = "El ID de la ruta no coincide con el del cuerpo." });

            await _updateHandler.ExecuteAsync(command);
            return Ok(new { message = "Usuario actualizado con éxito." });
        }
        catch (DomainException ex)
        {
            return NotFound(new { error = ex.Message });
        }
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
        try
        {
            var response = await _loginHandler.ExecuteAsync(command);
            
            return Ok(response); 
        }
        catch (Exception ex)
        {
            return Unauthorized(new { error = ex.Message }); 
        }
    }

    [HttpPost("refresh")]
    [AllowAnonymous]
    public async Task<IActionResult> RefreshToken(
        [FromBody] RefreshTokenCommand command, 
        [FromServices] RefreshTokenCommandHandler handler)
    {
        try
        {
            var response = await handler.ExecuteAsync(command);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return Unauthorized(new { error = ex.Message });
        }
    }
}