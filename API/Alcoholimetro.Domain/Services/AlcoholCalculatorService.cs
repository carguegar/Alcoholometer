using Alcoholimetro.Domain.Enums;

namespace Alcoholimetro.Domain.Services;

public class AlcoholCalculatorService : IAlcoholCalculatorService
{
    private const double GeneralLimit = 0.25;
    private const double NoviceLimit = 0.15;
    private const double CriminalLimit = 0.60;
    
    // Generic elimination rate
    private const double DefaultEliminationRate = 0.075;

    public AlcoholCalculationResult Calculate(
        double measurementLevel, 
        bool isNoviceDriver, 
        double? weightKg = null, 
        string? biologicalSex = null)
    {
        if (measurementLevel < 0)
            throw new Exceptions.DomainException("La medición no puede ser negativa.");

        double legalLimit = isNoviceDriver ? NoviceLimit : GeneralLimit;

        if (measurementLevel <= legalLimit)
        {
            return new AlcoholCalculationResult(
                Color: TrafficLightColor.Green,
                Message: "Tasa legal. Puedes conducir, pero recuerda que la mejor tasa es 0.0.",
                EstimatedTimeToGreen: null
            );
        }

        // Personal elimination rate
        double eliminationRate = CalculateEliminationRate(weightKg, biologicalSex);

        double hoursToWait = (measurementLevel - legalLimit) / eliminationRate;
        var timeToGreen = TimeSpan.FromHours(hoursToWait);

        if (measurementLevel >= CriminalLimit)
        {
            return new AlcoholCalculationResult(
                Color: TrafficLightColor.Red,
                Message: "¡PELIGRO! Tasa delictiva. Prohibido conducir. Llama a un taxi.",
                EstimatedTimeToGreen: timeToGreen
            );
        }


        string precisionMode = weightKg.HasValue ? "(Estimación personalizada)" : "(Estimación genérica)";
        
        return new AlcoholCalculationResult(
            Color: TrafficLightColor.Yellow,
            Message: $"Tasa ilegal. Darías positivo. Espera al menos {(int)timeToGreen.TotalHours}h y {timeToGreen.Minutes}m. {precisionMode}",
            EstimatedTimeToGreen: timeToGreen
        );
    }

    // TODO: migrar a enum BiologicalSex global
    private double CalculateEliminationRate(double? weightKg, string? sex)
    {
        if (!weightKg.HasValue || string.IsNullOrWhiteSpace(sex))
        {
            return DefaultEliminationRate; 
        }

        double rate = DefaultEliminationRate;

        var s = sex?.Trim().ToLowerInvariant();
        if (s == "female" || s == "f" || s == "femenino")
        {
            rate = 0.085; 
        }
        else
        {
            rate = 0.075; 
        }

        
        double weightRatio = weightKg.Value / 70.0;
        

        double weightAdjustment = (weightRatio - 1.0) * 0.01; 
        
        rate += weightAdjustment;

        rate = Math.Clamp(rate, 0.05, 0.10);

        return rate;
    }
}