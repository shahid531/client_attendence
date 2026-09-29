// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/sso_constants.dart';
import 'azure_sso_helper.dart';
import 'azure_sso_result.dart';

/// Generates a cryptographically random PKCE code verifier (64 chars).
String _generateCodeVerifier() {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~';
  final rand = Random.secure();
  return List.generate(64, (_) => chars[rand.nextInt(chars.length)]).join();
}

/// Generates a SHA-256 base64url-encoded PKCE code challenge.
String _generateCodeChallenge(String verifier) {
  final bytes = ascii.encode(verifier);
  final digest = sha256.convert(bytes);
  return base64Url.encode(digest.bytes).replaceAll('=', '');
}

/// Generates a random state string to protect against CSRF attacks.
String _generateRandomState() {
  final rand = Random.secure();
  final values = List<int>.generate(16, (_) => rand.nextInt(256));
  return base64Url.encode(values).replaceAll('=', '');
}

/// Initiates Microsoft SSO on Web using OAuth 2.0 Authorization Code flow with PKCE.
Future<AzureSsoResult> platformSignIn() async {
  final codeVerifier = _generateCodeVerifier();
  final codeChallenge = _generateCodeChallenge(codeVerifier);
  final state = _generateRandomState();

  // Persist PKCE verifier in session storage so it survives redirect if needed
  html.window.sessionStorage['sso_code_verifier'] = codeVerifier;
  html.window.sessionStorage['sso_state'] = state;

  final redirectUri = SsoConstants.redirectUri;
  final scopes = SsoConstants.scopes.join(' ');

  final authUrl = Uri.https(
    'login.microsoftonline.com',
    '/${SsoConstants.tenantId}/oauth2/v2.0/authorize',
    {
      'client_id': SsoConstants.clientId,
      'response_type': 'code',
      'redirect_uri': redirectUri,
      'response_mode': 'query',
      'scope': scopes,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'state': state,
      'prompt': 'select_account',
    },
  ).toString();

  debugPrint('[AzureSsoWeb] Initiating Web OAuth PKCE flow');
  debugPrint('[AzureSsoWeb] Redirect URI: $redirectUri');
  debugPrint('[AzureSsoWeb] Scopes: $scopes');

  // Attempt in-place Popup flow first for best user experience
  final screenWidth = html.window.screen?.width ?? 1200;
  final screenHeight = html.window.screen?.height ?? 800;
  const width = 600;
  const height = 720;
  final left = (screenWidth / 2) - (width / 2);
  final top = (screenHeight / 2) - (height / 2);

  final dynamic popup = html.window.open(
    authUrl,
    'Microsoft_SSO_Login',
    'width=$width,height=$height,top=$top,left=$left,menubar=no,toolbar=no,location=no,status=no',
  );

  if (popup != null) {
    final completer = Completer<String>();
    final dynamic dynPopup = popup;

    Timer.periodic(const Duration(milliseconds: 300), (t) {
      if (dynPopup.closed == true) {
        t.cancel();
        if (!completer.isCompleted) {
          completer.completeError(Exception('Microsoft sign-in window was closed by the user.'));
        }
        return;
      }

      try {
        final String? currentHref = dynPopup.location?.href?.toString();
        if (currentHref != null && currentHref.isNotEmpty) {
          final uri = Uri.tryParse(currentHref);
          if (uri != null && uri.queryParameters.containsKey('code')) {
            t.cancel();
            final code = uri.queryParameters['code']!;
            popup.close();
            if (!completer.isCompleted) {
              completer.complete(code);
            }
          } else if (uri != null && uri.queryParameters.containsKey('error')) {
            t.cancel();
            final errorDesc =
                uri.queryParameters['error_description'] ?? uri.queryParameters['error']!;
            popup.close();
            if (!completer.isCompleted) {
              completer.completeError(Exception('Microsoft SSO Error: $errorDesc'));
            }
          }
        }
      } catch (_) {
        // Cross-origin exception while the popup is on login.microsoftonline.com domain.
        // Expected until Microsoft redirects back to our redirectUri.
      }
    });

    final code = await completer.future;
    return await _exchangeCodeForTokens(
      code: code,
      codeVerifier: codeVerifier,
      redirectUri: redirectUri,
    );
  } else {
    // Popup was blocked by the browser. Fall back to full-page redirect flow.
    debugPrint('[AzureSsoWeb] Popup was blocked by browser. Falling back to page redirect.');
    html.window.location.href = authUrl;
    return Completer<AzureSsoResult>().future; // Window is redirecting
  }
}

/// Checks if the page loaded with an authorization code from a Microsoft redirect.
Future<AzureSsoResult?> platformCheckRedirectCallback() async {
  final uri = Uri.base;
  if (!uri.queryParameters.containsKey('code')) return null;

  final code = uri.queryParameters['code']!;
  final codeVerifier = html.window.sessionStorage['sso_code_verifier'];
  if (codeVerifier == null || codeVerifier.isEmpty) return null;

  // Clear storage and clean browser URL
  html.window.sessionStorage.remove('sso_code_verifier');
  html.window.sessionStorage.remove('sso_state');
  html.window.history.replaceState(null, '', uri.path);

  return await _exchangeCodeForTokens(
    code: code,
    codeVerifier: codeVerifier,
    redirectUri: SsoConstants.redirectUri,
  );
}

/// Exchanges the PKCE authorization code for Microsoft tokens via direct HTTP POST.
Future<AzureSsoResult> _exchangeCodeForTokens({
  required String code,
  required String codeVerifier,
  required String redirectUri,
}) async {
  debugPrint('[AzureSsoWeb] Exchanging code for tokens with Microsoft Token endpoint...');
  final tokenEndpoint =
      'https://login.microsoftonline.com/${SsoConstants.tenantId}/oauth2/v2.0/token';

  final dio = Dio();
  final response = await dio.post(
    tokenEndpoint,
    options: Options(
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8',
      },
    ),
    data: {
      'client_id': SsoConstants.clientId,
      'redirect_uri': redirectUri,
      'scope': SsoConstants.scopes.join(' '),
      'code': code,
      'code_verifier': codeVerifier,
      'grant_type': 'authorization_code',
    },
  );

  final dynamic rawData = response.data;
  final Map<String, dynamic> data = (rawData is Map<String, dynamic>)
      ? rawData
      : (jsonDecode(rawData.toString()) as Map<String, dynamic>);

  final accessToken = data['access_token']?.toString();
  final idToken = data['id_token']?.toString();
  final refreshToken = data['refresh_token']?.toString();
  final tokenType = data['token_type']?.toString() ?? 'Bearer';
  final scope = data['scope']?.toString() ?? '';
  final expiresIn = data['expires_in'] is int
      ? data['expires_in'] as int
      : int.tryParse(data['expires_in']?.toString() ?? '') ?? 3600;
  final extExpiresIn = data['ext_expires_in'] is int
      ? data['ext_expires_in'] as int
      : int.tryParse(data['ext_expires_in']?.toString() ?? '') ?? expiresIn;
  final refreshTokenExpiresIn = data['refresh_token_expires_in'] is int
      ? data['refresh_token_expires_in'] as int
      : int.tryParse(data['refresh_token_expires_in']?.toString() ?? '') ?? 86399;
  final clientInfo = data['client_info']?.toString() ?? '';
  final tokenExpiration = DateTime.now().add(Duration(seconds: expiresIn));

  final idTokenClaims = decodeJwtClaims(idToken);
  final accessTokenClaims = decodeJwtClaims(accessToken);

  final fullResponseMap = <String, dynamic>{
    'provider': 'Microsoft Azure AD (Entra ID) - Web',
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
    'tokenExpiration': tokenExpiration.toIso8601String(),
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

  debugPrint('==================== [AZURE SSO SUCCESS (WEB)] ====================');
  if (accessTokenClaims.containsKey('aud')) {
    debugPrint('[AzureSsoWeb] Access Token audience (aud): ${accessTokenClaims['aud']}');
  }
  if (accessTokenClaims.containsKey('scp')) {
    debugPrint('[AzureSsoWeb] Access Token scopes (scp): ${accessTokenClaims['scp']}');
  }
  debugPrint('[AzureSsoWeb] ID Token user: ${idTokenClaims['name']} (${idTokenClaims['preferred_username'] ?? idTokenClaims['email'] ?? idTokenClaims['upn']})');
  debugPrint(result.toPrettyJson());
  debugPrint('===================================================================');

  printFullToken(accessToken, label: 'AZURE_SSO_ACCESS_TOKEN');
  printFullToken(idToken, label: 'AZURE_SSO_ID_TOKEN');

  return result;
}
