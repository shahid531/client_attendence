import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/version_util.dart';
import '../../domain/entities/app_version_info.dart';

class ForceUpdateDialog extends StatelessWidget {
  final AppUpdateType updateType;
  final String currentVersion;
  final AppVersionInfo versionInfo;
  final VoidCallback? onDismissOptional;

  const ForceUpdateDialog({
    super.key,
    required this.updateType,
    required this.currentVersion,
    required this.versionInfo,
    this.onDismissOptional,
  });

  static Future<void> show(
    BuildContext context, {
    required AppUpdateType updateType,
    required String currentVersion,
    required AppVersionInfo versionInfo,
    VoidCallback? onDismissOptional,
  }) async {
    final isForce = updateType == AppUpdateType.force;
    return showDialog<void>(
      context: context,
      barrierDismissible: !isForce,
      builder: (BuildContext dialogContext) {
        return ForceUpdateDialog(
          updateType: updateType,
          currentVersion: currentVersion,
          versionInfo: versionInfo,
          onDismissOptional: onDismissOptional,
        );
      },
    );
  }

  Future<void> _launchUpdateUrl(BuildContext context) async {
    final urlString = versionInfo.appLink.trim();
    if (urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Update link is not configured yet.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final uri = Uri.tryParse(urlString);
    if (uri != null) {
      try {
        final canLaunch = await canLaunchUrl(uri);
        if (canLaunch) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          // Attempt direct launch anyway
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch update URL: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isForce = updateType == AppUpdateType.force;

    return PopScope(
      canPop: !isForce,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 10,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Header
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isForce
                      ? AppColors.primaryNavy.withValues(alpha: 0.08)
                      : Colors.blue.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isForce ? Icons.system_update_rounded : Icons.update_rounded,
                  size: 40,
                  color: isForce ? AppColors.primaryNavy : Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                isForce ? 'App Update Required' : 'New Version Available',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Version Tags
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'v$currentVersion',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'v${versionInfo.latestVersion}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Description / Message
              Text(
                versionInfo.updateMessage.isNotEmpty
                    ? versionInfo.updateMessage
                    : (isForce
                        ? 'A critical update is required to continue using the application. Please update to the latest version.'
                        : 'A newer version of the app is available with latest features and bug fixes.'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () => _launchUpdateUrl(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.download_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Update Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isForce) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onDismissOptional?.call();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: Colors.grey.shade700,
                      ),
                      child: const Text(
                        'Later',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
