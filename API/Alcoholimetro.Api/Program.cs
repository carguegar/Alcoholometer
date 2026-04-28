using System.Text;
using Alcoholimetro.Application.Authentication;
using Alcoholimetro.Application.Commands;
using Alcoholimetro.Application.Queries;
using Alcoholimetro.Application.Services;
using Alcoholimetro.Domain.Repositories;
using Alcoholimetro.Domain.Services;
using Alcoholimetro.Infrastructure.Authentication;
using Alcoholimetro.Infrastructure.Notifications;
using Alcoholimetro.Infrastructure.Persistence;
using Alcoholimetro.Infrastructure.Repositories;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IMeasurementRepository, MeasurementRepository>();
builder.Services.AddScoped<IGroupRepository, GroupRepository>();
builder.Services.AddScoped<IAlcoholCalculatorService, AlcoholCalculatorService>();
builder.Services.AddScoped<IPushNotificationService, MockPushNotificationService>();

builder.Services.AddScoped<CreateUserCommandHandler>();
builder.Services.AddScoped<UpdateUserCommandHandler>();
builder.Services.AddScoped<DeleteUserCommandHandler>();
builder.Services.AddScoped<GetUserByIdQueryHandler>();
builder.Services.AddScoped<GetAllUsersQueryHandler>();
builder.Services.AddScoped<RecordMeasurementCommandHandler>();
builder.Services.AddScoped<GetMeasurementsByUserIdQueryHandler>();
builder.Services.AddScoped<LoginCommandHandler>();
builder.Services.AddScoped<CreateGroupCommandHandler>();
builder.Services.AddScoped<JoinGroupCommandHandler>();
builder.Services.AddScoped<RefreshTokenCommandHandler>();
builder.Services.AddScoped<GetGroupRankingQueryHandler>();
builder.Services.AddScoped<GetUserGroupsQueryHandler>();
builder.Services.AddScoped<GetGroupDetailsQueryHandler>();
builder.Services.AddScoped<RemoveMemberCommandHandler>();
builder.Services.AddScoped<UpdateDeviceTokenCommandHandler>();
builder.Services.AddScoped<UpdateGroupConfigCommandHandler>();
builder.Services.AddScoped<PromoteToAdminCommandHandler>();

builder.Services.AddScoped<IJwtProvider, JwtProvider>();
builder.Services.AddControllers();

// CORS: Permitir peticiones desde Flutter Web (navegadores)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutterWeb", policy =>
    {
        policy
            .AllowAnyOrigin()
            .AllowAnyMethod()
            .AllowAnyHeader();
    });
});
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") 
    ?? throw new InvalidOperationException("CRÍTICO: Falta la cadena de conexión 'DefaultConnection' en appsettings o User Secrets.");

builder.Services.AddDbContext<AlcoholimetroDbContext>(options =>
    options.UseNpgsql(connectionString));
    
var jwtSecret = builder.Configuration["Jwt:Secret"] 
    ?? throw new InvalidOperationException("CRÍTICO: Falta el secreto 'Jwt:Secret' en la configuración o User Secrets.");
//JWT config
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options => {
        options.TokenValidationParameters = new TokenValidationParameters {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret))
        };
    });
    
builder.Services.AddAuthorization();

builder.Services.AddOpenApi(options =>
{
    options.AddDocumentTransformer((document, context, cancellationToken) =>
    {
        document.Components ??= new OpenApiComponents();
        document.Components.SecuritySchemes ??= new Dictionary<string, IOpenApiSecurityScheme>();

        document.Components.SecuritySchemes.Add("Bearer", new OpenApiSecurityScheme
        {
            Type = SecuritySchemeType.Http,
            Scheme = "bearer",
            BearerFormat = "JWT",
            Description = "Introduce tu token JWT aquí."
        });

        document.Security = [
            new OpenApiSecurityRequirement
            {
                { new OpenApiSecuritySchemeReference("Bearer"), [] }
            }
        ];

        document.SetReferenceHostDocument();
        return Task.CompletedTask;
    });
});
var app = builder.Build();

app.UseMiddleware<Alcoholimetro.Api.Middlewares.GlobalExceptionMiddleware>();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi(); 
    
    app.UseSwaggerUI(options => 
    {
        options.SwaggerEndpoint("/openapi/v1.json", "API v1");
    });
}

app.UseHttpsRedirection();

app.UseCors("AllowFlutterWeb");

app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();