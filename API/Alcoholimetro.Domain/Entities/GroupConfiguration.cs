namespace Alcoholimetro.Domain.Entities;

public class GroupConfiguration
{
    public bool IsAlertActive { get; set; } = false;
    public double AlertThresholdLevel { get; set; }

    public bool IsMandatoryMeasurementActive { get; set; } = false;

    public TimeSpan? MandatoryStartTime { get; set; }
    public TimeSpan? MandatoryEndTime { get; set; }
}