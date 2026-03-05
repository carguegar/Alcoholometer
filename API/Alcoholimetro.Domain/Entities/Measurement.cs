using Alcoholimetro.Domain.ValueObjects;

namespace Alcoholimetro.Domain.Entities;

public class Measurement
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; } 
    public double AlcoholLevel { get; set; } 
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    
    public Coordinates Location { get; set; } = null!;
    // user navigation property for easier access to user data when needed, can be null if not loaded    
    public User? User { get; set; }
}