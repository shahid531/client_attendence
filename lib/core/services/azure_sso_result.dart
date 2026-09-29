import 'dart:convert';

/// Data class holding the complete response from Azure AD SSO.
class AzureSsoResult {
  final String? accessToken;
  final String? idToken;
  final String? refreshToken;
  final DateTime? tokenExpiration;
  final String? tokenType;
  final String? scope;
  final int? expiresIn;
  final int? extExpiresIn;
  final int? refreshTokenExpiresIn;
  final String? clientInfo;
  final Map<String, dynamic> idTokenClaims;
  final Map<String, dynamic>? accessTokenClaims;
  final Map<String, dynamic> fullResponseMap;

  const AzureSsoResult({
    this.accessToken,
    this.idToken,
    this.refreshToken,
    this.tokenExpiration,
    this.tokenType,
    this.scope,
    this.expiresIn,
    this.extExpiresIn,
    this.refreshTokenExpiresIn,
    this.clientInfo,
    required this.idTokenClaims,
    this.accessTokenClaims,
    required this.fullResponseMap,
  });

  /// Pretty printed JSON string of the entire SSO response for backend developers.
  String toPrettyJson() {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(fullResponseMap);
    } catch (_) {
      return fullResponseMap.toString();
    }
  }

  /// User's display name extracted from ID Token claims.
  String get displayName {
    return idTokenClaims['name']?.toString() ?? 'User';
  }

  /// User's email extracted from ID Token claims.
  String get email {
    return idTokenClaims['preferred_username']?.toString() ??
        idTokenClaims['email']?.toString() ??
        idTokenClaims['upn']?.toString() ??
        idTokenClaims['unique_name']?.toString() ??
        '';
  }
}
