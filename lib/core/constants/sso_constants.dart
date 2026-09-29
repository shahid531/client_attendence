import 'package:flutter/foundation.dart';

/// Azure AD (Microsoft Entra ID) SSO Configuration Constants.
///
/// Supports both Mobile (Android/iOS) and Web (Browser) environments.
class SsoConstants {
  /// Your Azure AD Tenant ID (Directory ID).
  static const String tenantId = '571c8018-2e13-4657-af22-5b95a5e78fcd';

  /// Your Azure AD Application (Client) ID.
  static const String clientId = '0fb470f6-f520-4627-8ec1-ac7d45f808ca';

  /// Your Azure AD Client Secret (kept for backend reference/testing).
  static const String secretId = '';

  /// The Redirect URI configured in Azure Portal -> App Registration -> Authentication -> Android.
  static const String mobileRedirectUri =
      'msauth://com.idealake.client_attendence/2jmj7l5rSw0yVb%2FvlWAYkK%2FYBwk%3D';

  /// Optional override for Web Redirect URI (e.g. 'http://localhost:5000' or 'https://attendence.idealake.com').
  /// If not specified, dynamically defaults to current browser origin.
  static String? customWebRedirectUri;

  /// Web Redirect URI resolving to the browser origin.
  static String get webRedirectUri {
    if (customWebRedirectUri != null && customWebRedirectUri!.isNotEmpty) {
      return customWebRedirectUri!;
    }
    final base = Uri.base;
    final portSuffix = (base.hasPort && base.port != 80 && base.port != 443) ? ':${base.port}' : '';
    return '${base.scheme}://${base.host}$portSuffix';
  }

  /// Platform-aware redirect URI: returns web origin on Flutter Web, and msauth deep-link on Mobile.
  static String get redirectUri => kIsWeb ? webRedirectUri : mobileRedirectUri;

  /// Attendance Backend API Scope configured in Azure Portal -> Expose an API.
  static const String attendanceApiScope = 'api://$clientId/access_as_user';

  /// Standard OAuth Scopes requested from Microsoft.
  static const List<String> scopes = [
    'openid',
    'profile',
    'email',
    'offline_access',
    attendanceApiScope,
  ];

  /// OpenID Discovery URL for this tenant.
  static String get discoveryUrl {
    final tid = tenantId.trim().isNotEmpty ? tenantId.trim() : 'common';
    return 'https://login.microsoftonline.com/$tid/v2.0/.well-known/openid-configuration';
  }

  /// Whether credentials have been configured by the developer.
  static bool get isConfigured {
    return tenantId.trim().isNotEmpty && clientId.trim().isNotEmpty;
  }
}
