namespace Alcoholimetro.Domain.Exceptions;
public class InvalidLongitudeException : DomainException
{
    public InvalidLongitudeException(double lon) 
        : base($"The longitude ({lon}) is out of range.") { }
}