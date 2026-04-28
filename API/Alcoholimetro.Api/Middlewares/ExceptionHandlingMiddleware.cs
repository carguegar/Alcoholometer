using System.Text.Json;
using Alcoholimetro.Domain.Exceptions;
using Microsoft.AspNetCore.Mvc;

namespace Alcoholimetro.Api.Middlewares;

public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;
    private readonly IHostEnvironment _env;

    public ExceptionHandlingMiddleware(
        RequestDelegate next,
        ILogger<ExceptionHandlingMiddleware> logger,
        IHostEnvironment env)
    {
        _next = next;
        _logger = logger;
        _env = env;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (OperationCanceledException) when (context.RequestAborted.IsCancellationRequested)
        {
            // Cliente canceló — no logear como error
            if (!context.Response.HasStarted) context.Response.StatusCode = 499;
            return;
        }
        catch (Exception ex)
        {
            await HandleExceptionAsync(context, ex);
        }
    }

    private Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        int statusCode;
        string title;
        string? type = null;

        switch (exception)
        {
            case DomainException:
                statusCode = StatusCodes.Status400BadRequest;
                title = "Bad Request";
                type = "https://tools.ietf.org/html/rfc7231#section-6.5.1";
                break;
            case UnauthorizedAccessException:
                statusCode = StatusCodes.Status401Unauthorized;
                title = "Unauthorized";
                type = "https://tools.ietf.org/html/rfc7235#section-3.1";
                break;
            case KeyNotFoundException:
                statusCode = StatusCodes.Status404NotFound;
                title = "Not Found";
                type = "https://tools.ietf.org/html/rfc7231#section-6.5.4";
                break;
            default:
                statusCode = StatusCodes.Status500InternalServerError;
                title = "Internal Server Error";
                type = "https://tools.ietf.org/html/rfc7231#section-6.6.1";
                _logger.LogError(exception, "Unhandled exception for {Path}", context.Request.Path);
                break;
        }

        var problem = new ProblemDetails
        {
            Status = statusCode,
            Title = title,
            Type = type,
            Instance = context.Request.Path,
        };

        if (_env.IsDevelopment())
        {
            problem.Detail = exception.ToString();
        }
        else if (statusCode != StatusCodes.Status500InternalServerError)
        {
            problem.Detail = exception.Message;
        }

        context.Response.StatusCode = statusCode;
        context.Response.ContentType = "application/problem+json";

        var options = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
        return context.Response.WriteAsync(JsonSerializer.Serialize(problem, options));
    }
}
