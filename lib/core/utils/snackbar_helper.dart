import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Centralized SnackBar & Notification helper to maintain consistent design across the app.
class SnackbarHelper {
  /// Shows a floating Success SnackBar with green background and icon
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.successEmerald,
      icon: Icons.check_circle_outline_rounded,
      duration: duration,
      action: action,
    );
  }

  /// Shows a floating Error SnackBar with red background and icon
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.dangerRose,
      icon: Icons.error_outline_rounded,
      duration: duration,
      action: action,
    );
  }

  /// Shows a floating Warning SnackBar with amber background and icon
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.warningAmber,
      icon: Icons.warning_amber_rounded,
      duration: duration,
      action: action,
    );
  }

  /// Shows a floating Info SnackBar with primary navy/blue background and icon
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.primaryNavy,
      icon: Icons.info_outline_rounded,
      duration: duration,
      action: action,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: duration,
        action: action,
      ),
    );
  }
}
