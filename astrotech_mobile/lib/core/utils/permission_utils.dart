import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/app_colors.dart';

class PermissionUtils {
  PermissionUtils._();

  /// Show a dialog explaining the permission is permanently denied
  /// and offering to open iOS Settings to enable it manually.
  static Future<void> showSettingsDialog(
    BuildContext context, {
    required String permissionLabel,
    required String reason,
  }) async {
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.warningLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.warning,
            size: 28,
          ),
        ),
        title: Text('Accès à $permissionLabel refusé'),
        content: Text(
          '$reason\n\nVeuillez autoriser l\'accès dans les Réglages de votre appareil.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            icon: const Icon(Icons.settings_rounded, size: 16),
            label: const Text('Ouvrir Réglages'),
            style: FilledButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
