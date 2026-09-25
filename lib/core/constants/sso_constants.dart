/// Azure AD (Microsoft Entra ID) SSO Configuration Constants.
///
/// Fill in your Tenant ID, Client ID, and Secret ID below.
class SsoConstants {
  /// Your Azure AD Tenant ID (Directory ID).
  /// Example: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
  static const String tenantId = '571c8018-2e13-4657-af22-5b95a5e78fcd';

  /// Your Azure AD Application (Client) ID.
  /// Example: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
  static const String clientId = '0fb470f6-f520-4627-8ec1-ac7d45f808ca';

  /// Your Azure AD Client Secret (Secret ID / Value).
  /// Note: The mobile app uses OAuth 2.0 PKCE, but this field is kept here
  /// for your backend developer reference and testing.
  static const String secretId = '';

  /// The Redirect URI configured in Azure Portal -> App Registration -> Authentication -> Android.
  //static const String redirectUri = 'msauth://com.idealake.client_attendence/tbtv1SZ9Br0moPeYUQ5kOZAgBKc%3D';
  static const String redirectUri = 'msauth://com.idealake.client_attendence/2jmj7l5rSw0yVb%2FvlWAYkK%2FYBwk%3D';

  /// Standard OAuth Scopes requested from Microsoft.
  static const List<String> scopes = [
    'openid',
    'profile',
    'email',
    'offline_access',
    'User.Read',
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
