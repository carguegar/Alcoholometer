using Alcoholimetro.Application.Commands;
using Alcoholimetro.Application.Queries;
using Alcoholimetro.Domain.Repositories;
using Alcoholimetro.Infrastructure.Persistence;
using Alcoholimetro.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// supabase congig
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<AlcoholimetroDbContext>(options =>
    options.UseNpgsql(connectionString, npgsqlOptions => 
    {
        // Avoid EF core to group multiple inserts into a single batch, which can cause issues with Supabase's Pooler
        npgsqlOptions.MaxBatchSize(1); 
    }));

//Inyección de Dependencias - Repositorios (Infraestructura)
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IMeasurementRepository, MeasurementRepository>();

// deppendency injections (Aplicación)
//commands
builder.Services.AddScoped<CreateUserCommandHandler>();
builder.Services.AddScoped<UpdateUserCommandHandler>();
builder.Services.AddScoped<DeleteUserCommandHandler>();
builder.Services.AddScoped<RecordMeasurementCommandHandler>();

// queries
builder.Services.AddScoped<GetUserByIdQueryHandler>();
builder.Services.AddScoped<GetAllUsersQueryHandler>();
builder.Services.AddScoped<GetMeasurementsByUserIdQueryHandler>();

// controllers and swagger
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();//swagger documentation

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
    app.MapOpenApi();
}

app.UseHttpsRedirection();

app.MapControllers();

// data seeding
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        // Pedimos el DbContext
        var context = services.GetRequiredService<AlcoholimetroDbContext>();
        
        // Ejecutamos la semilla
        await DataSeeder.SeedAsync(context);
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Error al ejecutar el data seeding: {ex.Message}");
    }
}

app.Run();