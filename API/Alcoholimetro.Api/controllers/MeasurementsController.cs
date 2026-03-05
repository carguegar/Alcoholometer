using Alcoholimetro.Application.Commands;
using Alcoholimetro.Application.Queries;
using Alcoholimetro.Domain.Exceptions;
using Microsoft.AspNetCore.Mvc;

namespace Alcoholimetro.Api.Controllers;

[ApiController]
[Route("api/[controller]")] // api/measurements
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
    public async Task<IActionResult> Record([FromBody] RecordMeasurementCommand command)
    {
        try
        {
            await _recordHandler.ExecuteAsync(command);
            return StatusCode(201, new { message = "Medición registrada con éxito." });
        }
        catch (DomainException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    // GET: api/measurements/user/{userId}
    [HttpGet("user/{userId:guid}")]
    public async Task<IActionResult> GetByUser(Guid userId)
    {
        var measurements = await _getByUserHandler.ExecuteAsync(new GetMeasurementsByUserIdQuery(userId));
        return Ok(measurements);
    }
}