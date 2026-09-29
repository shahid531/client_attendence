import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import '../constants/sso_constants.dart';

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

/// Service that handles OAuth 2.0 PKCE authentication with Azure AD / Microsoft Entra ID.
class AzureSsoService {
  final FlutterAppAuth _appAuth;

  AzureSsoService({FlutterAppAuth? appAuth})
      : _appAuth = appAuth ?? const FlutterAppAuth();

  /// Initiates the Microsoft Single Sign-On flow.
  ///
  /// Opens the system browser / Custom Tab for sign-in, exchanges the auth code
  /// using PKCE, decodes token claims, and queries Microsoft Graph for user profile.
  Future<AzureSsoResult> signIn() async {
    if (!SsoConstants.isConfigured) {
      throw Exception(
        'SSO is not yet configured.\n\n'
        'Please enter your Tenant ID and Client ID in:\n'
        'lib/core/constants/sso_constants.dart',
      );
    }

    try {
      debugPrint('[AzureSsoService] Initiating OAuth PKCE with discovery: ${SsoConstants.discoveryUrl}');

      final response =
          await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          SsoConstants.clientId.trim(),
          SsoConstants.redirectUri.trim(),
          discoveryUrl: SsoConstants.discoveryUrl,
          scopes: SsoConstants.scopes,
          promptValues: ['select_account'],
        ),
      );

      final accessToken = response.accessToken;
      final idToken = response.idToken;
      final refreshToken = response.refreshToken;
      final tokenExpiration = response.accessTokenExpirationDateTime;
      final tokenAdditional = response.tokenAdditionalParameters ?? {};

      final tokenType = response.tokenType ?? tokenAdditional['token_type']?.toString() ?? 'Bearer';
      final scope = tokenAdditional['scope']?.toString() ??
          (response.scopes != null && response.scopes!.isNotEmpty
              ? response.scopes!.join(' ')
              : SsoConstants.scopes.join(' '));
      final expiresIn = int.tryParse(tokenAdditional['expires_in']?.toString() ?? '') ??
          (tokenExpiration != null ? tokenExpiration.difference(DateTime.now()).inSeconds : 3600);
      final extExpiresIn = int.tryParse(tokenAdditional['ext_expires_in']?.toString() ?? '') ?? expiresIn;
      final refreshTokenExpiresIn =
          int.tryParse(tokenAdditional['refresh_token_expires_in']?.toString() ?? '') ?? 86399;
      final clientInfo = tokenAdditional['client_info']?.toString() ?? '';

      // 1. Decode ID Token & Access Token JWT claims
      final idTokenClaims = _decodeJwtClaims(idToken);
      final accessTokenClaims = _decodeJwtClaims(accessToken);

      // 2. Compile full response map for the backend team
      final fullResponseMap = <String, dynamic>{
        'provider': 'Microsoft Azure AD (Entra ID)',
        'tenantId': SsoConstants.tenantId,
        'clientId': SsoConstants.clientId,
        'token_type': tokenType,
        'scope': scope,
        'expires_in': expiresIn,
        'ext_expires_in': extExpiresIn,
        'accessToken': accessToken,
        'refresh_token': refreshToken,
        'refresh_token_expires_in': refreshTokenExpiresIn,
        'id_token': idToken,
        'client_info': clientInfo,
        'tokenExpiration': tokenExpiration?.toIso8601String(),
        'idTokenClaims': idTokenClaims,
        if (accessTokenClaims.isNotEmpty) 'accessTokenClaims': accessTokenClaims,
      };

      final result = AzureSsoResult(
        accessToken: accessToken,
        idToken: idToken,
        refreshToken: refreshToken,
        tokenExpiration: tokenExpiration,
        tokenType: tokenType,
        scope: scope,
        expiresIn: expiresIn,
        extExpiresIn: extExpiresIn,
        refreshTokenExpiresIn: refreshTokenExpiresIn,
        clientInfo: clientInfo,
        idTokenClaims: idTokenClaims,
        accessTokenClaims: accessTokenClaims,
        fullResponseMap: fullResponseMap,
      );

      debugPrint('==================== [AZURE SSO SUCCESS] ====================');
      if (accessTokenClaims.containsKey('aud')) {
        debugPrint('[AzureSsoService] Access Token audience (aud): ${accessTokenClaims['aud']}');
      }
      if (accessTokenClaims.containsKey('scp')) {
        debugPrint('[AzureSsoService] Access Token scopes (scp): ${accessTokenClaims['scp']}');
      }
      debugPrint('[AzureSsoService] ID Token user: ${idTokenClaims['name']} (${idTokenClaims['preferred_username'] ?? idTokenClaims['email'] ?? idTokenClaims['upn']})');
      debugPrint(result.toPrettyJson());
      debugPrint('=============================================================');

      // Print the complete, untruncated Access Token and ID Token
      printFullToken(accessToken, label: 'AZURE_SSO_ACCESS_TOKEN');
      printFullToken(idToken, label: 'AZURE_SSO_ID_TOKEN');

      return result;
    } catch (e) {
      debugPrint('[AzureSsoService] Error during SSO: $e');
      rethrow;
    }
  }

  /// Decode JWT claims payload without external libraries.
  Map<String, dynamic> _decodeJwtClaims(String? jwtToken) {
    if (jwtToken == null || jwtToken.isEmpty) return {};
    try {
      final parts = jwtToken.split('.');
      if (parts.length != 3) return {};

      // Normalize Base64 URL padding
      String payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      final decodedBytes = base64Decode(payload);
      final decodedString = utf8.decode(decodedBytes);
      final Map<String, dynamic> claims = jsonDecode(decodedString);
      return claims;
    } catch (e) {
      debugPrint('[AzureSsoService] Failed to decode JWT: $e');
      return {};
    }
  }

  /// Safely prints the full token without truncation by Android Logcat, IDE buffers, or terminal limits.
  static void printFullToken(String? token, {String label = 'ACCESS_TOKEN'}) {
    if (token == null || token.isEmpty) {
      debugPrint('==================== [$label is NULL / EMPTY] ====================');
      return;
    }

    debugPrint('');
    debugPrint('==================== [FULL $label START] ====================');
    debugPrint('[$label] Length: ${token.length} characters');

    // 1. dart:developer log for IDE debug console & DevTools (unlimited line length)
    dev.log(token, name: label);

    // 2. Chunked logcat/terminal printing to prevent 1024-byte truncation
    const chunkSize = 500;
    int chunkIndex = 1;
    final totalChunks = (token.length / chunkSize).ceil();
    for (int i = 0; i < token.length; i += chunkSize) {
      final end = (i + chunkSize < token.length) ? i + chunkSize : token.length;
      debugPrint('[$label Part $chunkIndex/$totalChunks] ${token.substring(i, end)}');
      chunkIndex++;
    }

    debugPrint('==================== [FULL $label END] ====================');
    debugPrint('');
  }
}
