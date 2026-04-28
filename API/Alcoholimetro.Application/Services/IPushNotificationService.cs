namespace Alcoholimetro.Application.Services;

public interface IPushNotificationService
{
    Task SendAlertAsync(IEnumerable<Guid> userIdsToNotify, string title, string message);
}
