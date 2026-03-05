namespace Alcoholimetro.Domain.Exceptions;
public class InvalidLatitudeException : DomainException
{
    public InvalidLatitudeException(double lat) 
        : base($"The latitude ({lat}) is out of range.") { }
}