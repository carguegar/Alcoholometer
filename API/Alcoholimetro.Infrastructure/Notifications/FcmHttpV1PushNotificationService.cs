using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Alcoholimetro.Application.Services;
using Alcoholimetro.Domain.Repositories;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Alcoholimetro.Infrastructure.Notifications;

public class FcmHttpV1PushNotificationService : IPushNotificationService
{
    private const string FirebaseMessagingScope = "https://www.googleapis.com/auth/firebase.messaging";
    private const int MaxConcurrentSends = 10;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull,
    };

    private readonly FirebaseSettings _settings;
    private readonly IUserRepository _userRepository;
    private readonly ILogger<FcmHttpV1PushNotificationService> _logger;
    private readonly IHttpClientFactory _httpClientFactory;

    private readonly SemaphoreSlim _credentialLock = new(1, 1);
    private GoogleCredential? _credential;
    private bool _credentialUnavailableLogged;

    public FcmHttpV1PushNotificationService(
        IOptions<FirebaseSettings> settings,
        IUserRepository userRepository,
        ILogger<FcmHttpV1PushNotificationService> logger,
        IHttpClientFactory httpClientFactory)
    {
        _settings = settings.Value;
        _userRepository = userRepository;
        _logger = logger;
        _httpClientFactory = httpClientFactory;
    }

    public async Task SendAlertAsync(IEnumerable<Guid> userIdsToNotify, string title, string message)
    {
        try
        {
            var credential = await GetCredentialAsync();
            if (credential is null)
            {
                return; // already logged once
            }

            string accessToken;
            try
            {
                accessToken = await credential.UnderlyingCredential.GetAccessTokenForRequestAsync();
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "FCM: failed to acquire access token; skipping push notifications.");
                return;
            }

            var tokens = new List<string>();
            foreach (var userId in userIdsToNotify)
            {
                try
                {
                    var user = await _userRepository.GetByIdAsync(userId);
                    var pushToken = user?.DevicePushToken;
                    if (!string.IsNullOrWhiteSpace(pushToken))
                    {
                        tokens.Add(pushToken!);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "FCM: failed to load user {UserId} for push notification.", userId);
                }
            }

            if (tokens.Count == 0)
            {
                return;
            }

            using var semaphore = new SemaphoreSlim(MaxConcurrentSends, MaxConcurrentSends);
            var url = $"https://fcm.googleapis.com/v1/projects/{_settings.ProjectId}/messages:send";

            var sendTasks = tokens.Select(token => SendOneAsync(token, title, message, accessToken, url, semaphore));
            await Task.WhenAll(sendTasks);
        }
        catch (Exception ex)
        {
            // Never let exceptions propagate to the caller.
            _logger.LogWarning(ex, "FCM: unexpected error while sending push notifications.");
        }
    }

    private async Task SendOneAsync(string deviceToken, string title, string body, string accessToken, string url, SemaphoreSlim semaphore)
    {
        await semaphore.WaitAsync();
        try
        {
            var payload = new
            {
                message = new
                {
                    token = deviceToken,
                    notification = new
                    {
                        title,
                        body,
                    },
                },
            };

            var json = JsonSerializer.Serialize(payload, JsonOptions);
            using var request = new HttpRequestMessage(HttpMethod.Post, url)
            {
                Content = new StringContent(json, Encoding.UTF8, "application/json"),
            };
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

            var client = _httpClientFactory.CreateClient();
            using var response = await client.SendAsync(request);
            if (!response.IsSuccessStatusCode)
            {
                string responseBody = string.Empty;
                try
                {
                    responseBody = await response.Content.ReadAsStringAsync();
                }
                catch
                {
                    // ignore
                }

                if (responseBody.Length > 400)
                {
                    responseBody = responseBody.Substring(0, 400);
                }

                _logger.LogWarning(
                    "FCM send failed. Status: {StatusCode}. Body: {Body}",
                    (int)response.StatusCode,
                    responseBody);
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "FCM: exception sending push notification.");
        }
        finally
        {
            semaphore.Release();
        }
    }

    private async Task<GoogleCredential?> GetCredentialAsync()
    {
        if (_credential is not null)
        {
            return _credential;
        }

        await _credentialLock.WaitAsync();
        try
        {
            if (_credential is not null)
            {
                return _credential;
            }

            GoogleCredential credential;
            try
            {
                if (!string.IsNullOrWhiteSpace(_settings.CredentialsPath))
                {
                    if (!File.Exists(_settings.CredentialsPath))
                    {
                        LogCredentialUnavailableOnce(
                            $"FCM: credentials file not found at '{_settings.CredentialsPath}'. Push notifications disabled.");
                        return null;
                    }

                    using var stream = File.OpenRead(_settings.CredentialsPath);
                    credential = GoogleCredential.FromStream(stream);
                }
                else
                {
                    credential = await GoogleCredential.GetApplicationDefaultAsync();
                }
            }
            catch (Exception ex)
            {
                LogCredentialUnavailableOnce(
                    "FCM: unable to obtain Google credentials. Push notifications disabled. Error: " + ex.Message);
                return null;
            }

            _credential = credential.CreateScoped(FirebaseMessagingScope);
            return _credential;
        }
        finally
        {
            _credentialLock.Release();
        }
    }

    private void LogCredentialUnavailableOnce(string message)
    {
        if (_credentialUnavailableLogged)
        {
            return;
        }

        _credentialUnavailableLogged = true;
        _logger.LogWarning(message);
    }
}
