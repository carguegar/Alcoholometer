using System;

namespace Alcoholimetro.Application.Commands;

public record UpdateGroupConfigCommand(Guid GroupId, Guid AdminUserId, double AlertThresholdLevel);