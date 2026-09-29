import '../constants/sso_constants.dart';
import 'azure_sso_helper.dart' as helper;
import 'azure_sso_result.dart';
import 'azure_sso_platform_mobile.dart'
    if (dart.library.html) 'azure_sso_platform_web.dart';

export 'azure_sso_result.dart';

/// Unified service providing Microsoft Single Sign-On across both Mobile and Web platforms.
class AzureSsoService {
  /// Initiates the Microsoft Single Sign-On flow.
  ///
  /// On Mobile (Android/iOS): Uses native AppAuth with Custom Tabs and deep linking.
  /// On Web (Browsers): Uses in-place OAuth 2.0 PKCE with Microsoft Token API.
  Future<AzureSsoResult> signIn() async {
    if (!SsoConstants.isConfigured) {
      throw Exception(
        'SSO is not yet configured.\n\n'
        'Please enter your Tenant ID and Client ID in:\n'
        'lib/core/constants/sso_constants.dart',
      );
    }
    return await platformSignIn();
  }

  /// Checks if the application loaded via an OAuth redirect callback on Web.
  /// Returns null on mobile platforms or if no code is present.
  Future<AzureSsoResult?> checkRedirectCallback() async {
    return await platformCheckRedirectCallback();
  }

  /// Safely prints the full token without truncation by Android Logcat, IDE buffers, or terminal limits.
  static void printFullToken(String? token, {String label = 'ACCESS_TOKEN'}) {
    helper.printFullToken(token, label: label);
  }

  /// Decodes JWT claims payload without external libraries.
  static Map<String, dynamic> decodeJwtClaims(String? token) {
    return helper.decodeJwtClaims(token);
  }
}
