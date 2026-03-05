using Alcoholimetro.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Alcoholimetro.Domain.ValueObjects;


namespace Alcoholimetro.Infrastructure.Persistence;

public class AlcoholimetroDbContext : DbContext
{
    // options to configure the database connection, etc. from program.cs
    public AlcoholimetroDbContext(DbContextOptions<AlcoholimetroDbContext> options) : base(options)
    {
    }

    // tablas de BBDD
    public DbSet<User> Users { get; set; }
    public DbSet<Measurement> Measurements { get; set; }

    // tables configuration
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        //User-Measurement
        modelBuilder.Entity<Measurement>()
            .HasOne(m => m.User)
            .WithMany(u => u.Measurements)
            .HasForeignKey(m => m.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // user config
        modelBuilder.Entity<User>(entity => 
        {
            // ef should ignore age because it's a calculated property, not stored in the database
            entity.Ignore(u => u.Age);

            // mail traduction to string for the database, and back to Email when reading from the database
            entity.Property(u => u.Email)
                .HasConversion(
                    email => email.Value,
                    value => new Email(value)
                )
                .HasColumnName("Email");
        });

        // measurement config
        modelBuilder.Entity<Measurement>()
            .OwnsOne(m => m.Location, locationInfo =>
            {
                // same as Email, but for the Latitude and Longitude properties of the Coordinates Value Object
                locationInfo.Property(c => c.Lat)
                    .HasConversion(
                        lat => lat.Value, 
                        value => new Latitude(value) 
                    )
                    .HasColumnName("Latitude");

                locationInfo.Property(c => c.Lon)
                    .HasConversion(
                        lon => lon.Value, 
                        value => new Longitude(value) 
                    )
                    .HasColumnName("Longitude");
            });
    }
}