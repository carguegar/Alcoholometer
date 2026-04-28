using Alcoholimetro.Domain.Enums;

namespace Alcoholimetro.Domain.Services;

// Usamos un 'record' porque es perfecto para devolver datos inmutables
public record AlcoholCalculationResult(
    TrafficLightColor Color, 
    string Message, 
    TimeSpan? EstimatedTimeToGreen
);