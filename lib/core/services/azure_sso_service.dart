import 'dart:convert';
import 'package:dio/dio.dart';
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
  final Map<String, dynamic>? graphUserProfile;
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
    this.graphUserProfile,
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

  /// User's display name extracted from Graph API or ID Token claims.
  String get displayName {
    return graphUserProfile?['displayName']?.toString() ??
        idTokenClaims['name']?.toString() ??
        'User';
  }

  /// User's email extracted from Graph API or ID Token claims.
  String get email {
    return graphUserProfile?['mail']?.toString() ??
        graphUserProfile?['userPrincipalName']?.toString() ??
        idTokenClaims['preferred_username']?.toString() ??
        idTokenClaims['email']?.toString() ??
        '';
  }
}

/// Service that handles OAuth 2.0 PKCE authentication with Azure AD / Microsoft Entra ID.
class AzureSsoService {
  final FlutterAppAuth _appAuth;
  final Dio _dio;

  AzureSsoService({FlutterAppAuth? appAuth, Dio? dio})
      : _appAuth = appAuth ?? const FlutterAppAuth(),
        _dio = dio ?? Dio();

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

      // 1. Decode ID Token JWT claims
      final idTokenClaims = _decodeJwtClaims(idToken);

      // 2. Fetch User Profile from Microsoft Graph if access token exists
      Map<String, dynamic>? graphUserProfile;
      if (accessToken != null && accessToken.isNotEmpty) {
        graphUserProfile = await _fetchGraphUserProfile(accessToken);
      }

      // 3. Compile full response map for the backend team
      final fullResponseMap = <String, dynamic>{
        'provider': 'Microsoft Azure AD (Entra ID)',
        'tenantId': SsoConstants.tenantId,
        'clientId': SsoConstants.clientId,
        'token_type': tokenType,
        'scope': scope,
        'expires_in': expiresIn,
        'ext_expires_in': extExpiresIn,
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'refresh_token_expires_in': refreshTokenExpiresIn,
        'id_token': idToken,
        'client_info': clientInfo,
        'tokenExpiration': tokenExpiration?.toIso8601String(),
        'idTokenClaims': idTokenClaims,
        'graphUserProfile': graphUserProfile,
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
        graphUserProfile: graphUserProfile,
        fullResponseMap: fullResponseMap,
      );

      debugPrint('==================== [AZURE SSO SUCCESS] ====================');
      debugPrint(result.toPrettyJson());
      debugPrint('=============================================================');

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

  /// Fetch user profile from Microsoft Graph API v1.0.
  Future<Map<String, dynamic>?> _fetchGraphUserProfile(String accessToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://graph.microsoft.com/v1.0/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      return response.data;
    } catch (e) {
      debugPrint('[AzureSsoService] Graph API error: $e');
      return null;
    }
  }
}
