using Alcoholimetro.Application.Commands;
using Alcoholimetro.Application.Queries;
using Alcoholimetro.Domain.Exceptions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

namespace Alcoholimetro.Api.Controllers;

[ApiController]
[Route("api/[controller]")] // api/measurements
[Authorize]
public class MeasurementsController : ControllerBase
{
    private readonly RecordMeasurementCommandHandler _recordHandler;
    private readonly GetMeasurementsByUserIdQueryHandler _getByUserHandler;

    public MeasurementsController(
        RecordMeasurementCommandHandler recordHandler,
        GetMeasurementsByUserIdQueryHandler getByUserHandler)
    {
        _recordHandler = recordHandler;
        _getByUserHandler = getByUserHandler;
    }

    // POST: api/measurements
   [HttpPost]
    [AllowAnonymous]
    public async Task<IActionResult> RecordMeasurement([FromBody] RecordMeasurementRequest request)
    {
        Guid? userId = null;

        // Check if the request came with a valid JWT Token
        if (User.Identity?.IsAuthenticated == true)
        {
            var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (Guid.TryParse(userIdString, out Guid parsedId))
            {
                userId = parsedId;
            }
        }

        var command = new RecordMeasurementCommand(
            request.MeasurementLevel, 
            userId, 
            request.Lat, 
            request.Lng
        );

        var result = await _recordHandler.ExecuteAsync(command);
        return StatusCode(201, result);
    }
    // DTO for the incoming JSON
    public record RecordMeasurementRequest(double MeasurementLevel, double Lat, double Lng);

    // GET: api/measurements/user/{userId}
    [HttpGet("user/{userId:guid}")]
    public async Task<IActionResult> GetByUser(
        [FromRoute] Guid userId, 
        [FromQuery] int page = 1, 
        [FromQuery] int pageSize = 20)
    {
        var measurements = await _getByUserHandler.ExecuteAsync(
            new GetMeasurementsByUserIdQuery(userId, page, pageSize)
        );
        return Ok(measurements);
    }
}