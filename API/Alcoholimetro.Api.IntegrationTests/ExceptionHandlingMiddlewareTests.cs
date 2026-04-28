using System.Text.Json;
using Alcoholimetro.Api.Middlewares;
using Alcoholimetro.Domain.Exceptions;
using FluentAssertions;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging.Abstractions;

namespace Alcoholimetro.Api.IntegrationTests;

public class ExceptionHandlingMiddlewareTests
{
    private static async Task<(int statusCode, string contentType, string body)> InvokeWith(Exception toThrow, string envName = "Production")
    {
        var context = new DefaultHttpContext();
        var responseBody = new MemoryStream();
        context.Response.Body = responseBody;
        context.Request.Path = "/test";

        RequestDelegate next = _ => throw toThrow;
        var middleware = new ExceptionHandlingMiddleware(
            next,
            NullLogger<ExceptionHandlingMiddleware>.Instance,
            new TestHostEnvironment { EnvironmentName = envName });

        await middleware.InvokeAsync(context);

        responseBody.Position = 0;
        var body = await new StreamReader(responseBody).ReadToEndAsync();
        return (context.Response.StatusCode, context.Response.ContentType ?? string.Empty, body);
    }

    [Fact]
    public async Task DomainException_Maps_To_400_ProblemDetails()
    {
        var (status, contentType, body) = await InvokeWith(new DomainException("bad input"));

        status.Should().Be(StatusCodes.Status400BadRequest);
        contentType.Should().Be("application/problem+json");
        var json = JsonDocument.Parse(body).RootElement;
        json.GetProperty("status").GetInt32().Should().Be(400);
        json.GetProperty("title").GetString().Should().Be("Bad Request");
    }

    [Fact]
    public async Task UnauthorizedAccessException_Maps_To_401()
    {
        var (status, contentType, _) = await InvokeWith(new UnauthorizedAccessException("nope"));

        status.Should().Be(StatusCodes.Status401Unauthorized);
        contentType.Should().Be("application/problem+json");
    }

    [Fact]
    public async Task KeyNotFoundException_Maps_To_404()
    {
        var (status, contentType, _) = await InvokeWith(new KeyNotFoundException("missing"));

        status.Should().Be(StatusCodes.Status404NotFound);
        contentType.Should().Be("application/problem+json");
    }

    [Fact]
    public async Task GenericException_Maps_To_500()
    {
        var (status, contentType, body) = await InvokeWith(new InvalidOperationException("boom"));

        status.Should().Be(StatusCodes.Status500InternalServerError);
        contentType.Should().Be("application/problem+json");
        // In Production, generic 500 should not leak detail.
        var json = JsonDocument.Parse(body).RootElement;
        json.TryGetProperty("detail", out _).Should().BeFalse();
    }

    [Fact]
    public async Task Development_IncludesExceptionDetail()
    {
        var (_, _, body) = await InvokeWith(new InvalidOperationException("boom"), envName: "Development");

        var json = JsonDocument.Parse(body).RootElement;
        json.GetProperty("detail").GetString().Should().Contain("InvalidOperationException");
    }

    private sealed class TestHostEnvironment : IHostEnvironment
    {
        public string EnvironmentName { get; set; } = "Production";
        public string ApplicationName { get; set; } = "Alcoholimetro.Api";
        public string ContentRootPath { get; set; } = AppContext.BaseDirectory;
        public IFileProvider ContentRootFileProvider { get; set; } = new NullFileProvider();
    }
}
