import 'dart:convert';

/// Extracts the user ID (sub claim) from a JWT access token without
/// requiring any external JWT library.
String? extractUserIdFromToken(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    final payload = parts[1];
    // Add padding if needed
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final Map<String, dynamic> claims = json.decode(decoded) as Map<String, dynamic>;

    // ASP.NET Core uses 'sub' for user ID in JWT
    return claims['sub'] as String?;
  } catch (_) {
    return null;
  }
}
