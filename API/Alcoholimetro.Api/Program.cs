using System.Text;
using Alcoholimetro.Api.Middlewares;
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
builder.Services.Configure<FirebaseSettings>(builder.Configuration.GetSection(FirebaseSettings.SectionName));
builder.Services.AddHttpClient();

// Use real FCM in Production, or in Development when credentials are configured.
// Fall back to MockPushNotificationService in Development when no credentials exist.
var firebaseCredPath = builder.Configuration["Firebase:CredentialsPath"];
var googleAppCredEnv = Environment.GetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS");
var hasFirebaseCredentials = !string.IsNullOrWhiteSpace(firebaseCredPath)
    || !string.IsNullOrWhiteSpace(googleAppCredEnv);

if (hasFirebaseCredentials || !builder.Environment.IsDevelopment())
{
    builder.Services.AddScoped<IPushNotificationService, FcmHttpV1PushNotificationService>();
}
else
{
    builder.Services.AddScoped<IPushNotificationService, MockPushNotificationService>();
}

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

// CORS: orígenes permitidos vienen de Cors:AllowedOrigins (vacío en Development = fallback permisivo SOLO-DEV)
var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? Array.Empty<string>();
builder.Services.AddCors(options =>
{
    options.AddPolicy("DefaultCorsPolicy", policy =>
    {
        if (allowedOrigins.Length == 0 && builder.Environment.IsDevelopment())
        {
            // DEV-ONLY fallback
            policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader();
        }
        else
        {
            policy.WithOrigins(allowedOrigins).AllowAnyHeader().AllowAnyMethod().AllowCredentials();
        }
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

app.UseMiddleware<ExceptionHandlingMiddleware>();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi(); 
    
    app.UseSwaggerUI(options => 
    {
        options.SwaggerEndpoint("/openapi/v1.json", "API v1");
    });
}

if (!app.Environment.IsDevelopment())
{
    app.UseHsts();
}

app.Use(async (ctx, next) =>
{
    ctx.Response.Headers["X-Content-Type-Options"] = "nosniff";
    ctx.Response.Headers["X-Frame-Options"] = "DENY";
    ctx.Response.Headers["Referrer-Policy"] = "no-referrer";
    await next();
});

app.UseHttpsRedirection();

app.UseCors("DefaultCorsPolicy");

app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();