using Alcoholimetro.Domain.ValueObjects;

namespace Alcoholimetro.Domain.Entities;

public class User
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string SecondLastName { get; set; } = string.Empty;
    //using value object for email to ensure validation and encapsulation of email logic
    public Email Email { get; set; } = null!; 
    
    public string PasswordHash { get; set; } = string.Empty; 
    public DateOnly BirthDate { get; set; }
    public double WeightKg { get; set; }
    public double HeightCm { get; set; }
    public string BiologicalSex { get; set; } = string.Empty; 
    public DateOnly? DriverLicenseDate { get; set; }
    public List<Measurement> Measurements { get; set; } = new();
    //El token de Firebase/Apple para mandarle notificaciones Push al móvil
    public string? DevicePushToken { get; set; }
    public string? RefreshToken { get; set; }
    public DateTime? RefreshTokenExpiryTime { get; set; }
    public List<UserGroup> UserGroups { get; set; } = new();

    public int Age 
    {
        get 
        {
            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            var age = today.Year - BirthDate.Year;
            if (BirthDate > today.AddYears(-age)) age--;
            return age;
        }
    }
    public bool IsNoviceDriver 
    {
        get 
        {
            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            return DriverLicenseDate.HasValue && DriverLicenseDate.Value.AddYears(2) >= today;
        }
    }
}