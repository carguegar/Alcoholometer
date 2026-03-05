namespace Alcoholimetro.Domain.ValueObjects;

public record Coordinates
{
    public Latitude Lat { get; }
    public Longitude Lon { get; }
    public Coordinates(Latitude lat, Longitude lon)
    {
        Lat = lat;
        Lon = lon;
    }
}