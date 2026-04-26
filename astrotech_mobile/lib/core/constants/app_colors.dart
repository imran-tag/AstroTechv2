import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF003E82);
  static const Color primaryDark = Color(0xFF002952);
  static const Color primaryLight = Color(0xFF1565C0);

  // Secondary / Accent
  static const Color accent = Color(0xFF0099CC);
  static const Color accentDark = Color(0xFF006B8F);

  // Semantic
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFE65100);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFB71C1C);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF1565C0);
  static const Color infoLight = Color(0xFFE3F2FD);

  // Surfaces — M3 tonal scale
  static const Color background = Color(0xFFF5F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F3F8);
  static const Color surfaceContainer = Color(0xFFEEF2F8);
  static const Color surfaceContainerHigh = Color(0xFFE5EBF5);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF0D1B2A);
  static const Color textSecondary = Color(0xFF52616F);
  static const Color textHint = Color(0xFFA0AEBF);

  // Borders / Dividers
  static const Color divider = Color(0xFFDDE3EE);
  static const Color cardBorder = Color(0xFFE4EAF5);
  static const Color cardShadow = Color(0x14003E82);

  // Priority — status-derived tonal
  static const Color priorityUrgent = Color(0xFFB71C1C);
  static const Color priorityUrgentSurface = Color(0xFFFFEBEE);
  static const Color priorityHigh = Color(0xFFE65100);
  static const Color priorityHighSurface = Color(0xFFFFF3E0);
  static const Color priorityNormal = Color(0xFF2E7D32);
  static const Color priorityNormalSurface = Color(0xFFE8F5E9);
  static const Color priorityLow = Color(0xFF546E7A);
  static const Color priorityLowSurface = Color(0xFFECEFF1);

  // Status
  static const Color statusPlanifie = Color(0xFF1565C0);
  static const Color statusPlanifieSurface = Color(0xFFE3F2FD);
  static const Color statusEnCours = Color(0xFFE65100);
  static const Color statusEnCoursSurface = Color(0xFFFFF3E0);
  static const Color statusTermine = Color(0xFF2E7D32);
  static const Color statusTermineSurface = Color(0xFFE8F5E9);
  static const Color statusNonValidee = Color(0xFF546E7A);
  static const Color statusNonValideeSurface = Color(0xFFECEFF1);

  // Workflow steps
  static const Color stepComplete = Color(0xFF2E7D32);
  static const Color stepCurrent = Color(0xFF003E82);
  static const Color stepPending = Color(0xFFCFD8DC);

  // Connectivity
  static const Color offline = Color(0xFF546E7A);
  static const Color online = Color(0xFF2E7D32);
  static const Color syncing = Color(0xFFE65100);

  // Technician avatar palette (deterministic by name hash)
  static const List<Color> avatarPalette = [
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFF6A1B9A),
    Color(0xFFAD1457),
    Color(0xFF00838F),
    Color(0xFFE65100),
    Color(0xFF4527A0),
    Color(0xFF283593),
  ];
}
