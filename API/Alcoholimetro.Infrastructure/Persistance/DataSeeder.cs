using Alcoholimetro.Domain.Entities;
using Alcoholimetro.Domain.ValueObjects;

namespace Alcoholimetro.Infrastructure.Persistence;

public static class DataSeeder
{
    public static async Task SeedAsync(AlcoholimetroDbContext context) 
    {
        if (context.Users.Any()) 
        {
            return;
        }

        var user1 = new User
        {
            Id = Guid.NewGuid(),
            FirstName = "Carlos",
            LastName = "García",
            SecondLastName = "Pérez",
            Email = new Email("carlos@test.com"),
            PasswordHash = "HASH_FALSO_123",
            BirthDate = new DateOnly(1998, 5, 20),
            WeightKg = 75.5,
            HeightCm = 180,
            BiologicalSex = "M"
        };

        var user2 = new User
        {
            Id = Guid.NewGuid(),
            FirstName = "Ana",
            LastName = "López",
            SecondLastName = "Sánchez",
            Email = new Email("ana@test.com"),
            PasswordHash = "HASH_FALSO_456",
            BirthDate = new DateOnly(1995, 8, 15),
            WeightKg = 62.0,
            HeightCm = 165,
            BiologicalSex = "F"
        };

        var measurement1 = new Measurement
        {
            Id = Guid.NewGuid(),
            UserId = user1.Id,
            AlcoholLevel = 0.45,
            Timestamp = DateTime.UtcNow.AddHours(-2),
            Location = new Coordinates(new Latitude(40.4168), new Longitude(-3.7038))
        };

        var measurement2 = new Measurement
        {
            Id = Guid.NewGuid(),
            UserId = user1.Id,
            AlcoholLevel = 0.15,
            Timestamp = DateTime.UtcNow,
            Location = new Coordinates(new Latitude(40.4168), new Longitude(-3.7038))
        };

        try
        {
            //copy Api actions so it doesn't explode.
            context.Users.Add(user1);
            await context.SaveChangesAsync();

            context.Users.Add(user2);
            await context.SaveChangesAsync();

            context.Measurements.Add(measurement1);
            await context.SaveChangesAsync();

            context.Measurements.Add(measurement2);
            await context.SaveChangesAsync();

            Console.WriteLine("Data seeding completed successfully.");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error in data seeding: {ex.Message}");
        }
    }
}