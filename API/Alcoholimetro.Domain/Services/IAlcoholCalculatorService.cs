namespace Alcoholimetro.Domain.Services;

public interface IAlcoholCalculatorService
{
    AlcoholCalculationResult Calculate(
        double measurementLevel, 
        bool isNoviceDriver, 
        double? weightKg = null, 
        string? biologicalSex = null);
}