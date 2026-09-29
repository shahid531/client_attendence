import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import '../constants/sso_constants.dart';
import 'azure_sso_helper.dart';
import 'azure_sso_result.dart';

/// Initiates Microsoft SSO on Mobile (Android & iOS) using native FlutterAppAuth.
Future<AzureSsoResult> platformSignIn() async {
  const appAuth = FlutterAppAuth();
  debugPrint('[AzureSsoMobile] Initiating Mobile OAuth PKCE with discovery: ${SsoConstants.discoveryUrl}');
  debugPrint('[AzureSsoMobile] Mobile Redirect URI: ${SsoConstants.redirectUri}');

  final response = await appAuth.authorizeAndExchangeCode(
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

  final idTokenClaims = decodeJwtClaims(idToken);
  final accessTokenClaims = decodeJwtClaims(accessToken);

  final fullResponseMap = <String, dynamic>{
    'provider': 'Microsoft Azure AD (Entra ID) - Mobile',
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

  debugPrint('==================== [AZURE SSO SUCCESS (MOBILE)] ====================');
  if (accessTokenClaims.containsKey('aud')) {
    debugPrint('[AzureSsoMobile] Access Token audience (aud): ${accessTokenClaims['aud']}');
  }
  if (accessTokenClaims.containsKey('scp')) {
    debugPrint('[AzureSsoMobile] Access Token scopes (scp): ${accessTokenClaims['scp']}');
  }
  debugPrint('[AzureSsoMobile] ID Token user: ${idTokenClaims['name']} (${idTokenClaims['preferred_username'] ?? idTokenClaims['email'] ?? idTokenClaims['upn']})');
  debugPrint(result.toPrettyJson());
  debugPrint('======================================================================');

  printFullToken(accessToken, label: 'AZURE_SSO_ACCESS_TOKEN');
  printFullToken(idToken, label: 'AZURE_SSO_ID_TOKEN');

  return result;
}

/// No-op on mobile platforms.
Future<AzureSsoResult?> platformCheckRedirectCallback() async => null;
