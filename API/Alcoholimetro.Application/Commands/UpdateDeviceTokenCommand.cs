using System;

namespace Alcoholimetro.Application.Commands;

public record UpdateDeviceTokenCommand(Guid UserId, string DeviceToken);