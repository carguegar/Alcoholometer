namespace Alcoholimetro.Domain.Entities;

public class Group
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    
    // El código único que los usuarios escribirán en la app para unirse (ej. "FIESTA2026")
    public string InvitationCode { get; set; } = string.Empty; 
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Relación 1:1 con su configuración
    public GroupConfiguration Configuration { get; set; } = new();

    // Relación 1:N con la tabla intermedia de miembros
    public List<UserGroup> Members { get; set; } = new();
}