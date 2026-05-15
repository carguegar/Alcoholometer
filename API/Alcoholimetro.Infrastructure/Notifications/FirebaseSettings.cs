namespace Alcoholimetro.Infrastructure.Notifications;

public class FirebaseSettings
{
    public const string SectionName = "Firebase";
    public string ProjectId { get; set; } = "alcoholimetro-1f6ab";
    public string? CredentialsPath { get; set; } // optional; if null, falls back to GOOGLE_APPLICATION_CREDENTIALS
}
