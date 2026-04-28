using System.Net;
using System.Text.Json;
using Alcoholimetro.Domain.Exceptions;

namespace Alcoholimetro.Api.Middlewares;

public class GlobalExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionMiddleware> _logger;

    public GlobalExceptionMiddleware(RequestDelegate next, ILogger<GlobalExceptionMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "An unhandled exception has occurred.");
            await HandleExceptionAsync(context, ex);
        }
    }

    private static Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        context.Response.ContentType = "application/problem+json";
        
        var statusCode = (int)HttpStatusCode.InternalServerError;
        var title = "An internal server error occurred.";
        var detail = exception.Message;

        if (exception is DomainException domainException)
        {
            statusCode = (int)HttpStatusCode.BadRequest;
            title = "Bad Request";
            detail = domainException.Message;
        }
        else if (exception is NotFoundException notFoundException)
        {
            statusCode = (int)HttpStatusCode.NotFound;
            title = "Not Found";
            detail = notFoundException.Message;
        }
        else if (exception is ConflictException conflictException)
        {
            statusCode = (int)HttpStatusCode.Conflict;
            title = "Conflict";
            detail = conflictException.Message;
        }
        else
        {
            // For general exceptions
            title = "Internal Server Error";
            detail = "An unexpected error occurred.";
        }

        context.Response.StatusCode = statusCode;

        var response = new Microsoft.AspNetCore.Mvc.ProblemDetails
        {
            Status = statusCode,
            Title = title,
            Detail = detail,
            Instance = context.Request.Path
        };

        var options = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
        var json = JsonSerializer.Serialize(response, options);

        return context.Response.WriteAsync(json);
    }
}
