using Alcoholimetro.Application.Services;
using Microsoft.Extensions.Logging;

namespace Alcoholimetro.Infrastructure.Notifications;

public class MockPushNotificationService : IPushNotificationService
{
    private readonly ILogger<MockPushNotificationService> _logger;

    public MockPushNotificationService(ILogger<MockPushNotificationService> logger)
    {
        _logger = logger;
    }

    public Task SendAlertAsync(IEnumerable<Guid> userIdsToNotify, string title, string message)
    {
        _logger.LogInformation(
            "Push Notification triggered for {Count} users. Title: '{Title}', Message: '{Message}'",
            userIdsToNotify.Count(),
            title,
            message);
            
        _logger.LogInformation("[MOCK] In a real-world scenario, we would lookup 'DevicePushToken' from standard User repository and send via FCM/APNs here.");

        return Task.CompletedTask;
    }
}
