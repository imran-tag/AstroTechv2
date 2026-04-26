import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/intervention.dart';

class InterventionCard extends StatelessWidget {
  final Intervention intervention;
  final VoidCallback onTap;

  const InterventionCard({
    super.key,
    required this.intervention,
    required this.onTap,
  });

  // ── Status helpers ────────────────────────────────────────

  _StatusConfig get _status {
    switch (intervention.etat) {
      case 'planifie':
        return _StatusConfig(
          color: AppColors.statusPlanifie,
          surface: AppColors.statusPlanifieSurface,
          icon: Icons.schedule_rounded,
          label: 'Planifiée',
        );
      case 'en_cours':
        return _StatusConfig(
          color: AppColors.statusEnCours,
          surface: AppColors.statusEnCoursSurface,
          icon: Icons.play_circle_rounded,
          label: 'En cours',
        );
      case 'termine':
      case 'terminee':
        return _StatusConfig(
          color: AppColors.statusTermine,
          surface: AppColors.statusTermineSurface,
          icon: Icons.check_circle_rounded,
          label: 'Terminée',
        );
      case 'non_validee':
        return _StatusConfig(
          color: AppColors.statusNonValidee,
          surface: AppColors.statusNonValideeSurface,
          icon: Icons.pending_rounded,
          label: 'Non validée',
        );
      default:
        return _StatusConfig(
          color: AppColors.textHint,
          surface: AppColors.surfaceVariant,
          icon: Icons.help_outline_rounded,
          label: intervention.etat ?? 'Inconnu',
        );
    }
  }

  _PriorityConfig get _priority {
    switch (intervention.priorite?.toLowerCase()) {
      case 'urgent':
      case 'urgente':
        return _PriorityConfig(
          color: AppColors.priorityUrgent,
          surface: AppColors.priorityUrgentSurface,
          icon: Icons.priority_high_rounded,
          label: 'Urgent',
          isUrgent: true,
        );
      case 'haute':
      case 'high':
        return _PriorityConfig(
          color: AppColors.priorityHigh,
          surface: AppColors.priorityHighSurface,
          icon: Icons.keyboard_double_arrow_up_rounded,
          label: 'Haute',
          isUrgent: false,
        );
      case 'normale':
      case 'normal':
        return _PriorityConfig(
          color: AppColors.priorityNormal,
          surface: AppColors.priorityNormalSurface,
          icon: Icons.remove_rounded,
          label: 'Normale',
          isUrgent: false,
        );
      default:
        return _PriorityConfig(
          color: AppColors.priorityLow,
          surface: AppColors.priorityLowSurface,
          icon: Icons.keyboard_double_arrow_down_rounded,
          label: 'Basse',
          isUrgent: false,
        );
    }
  }

  static const List<String> _stepLabels = [
    'Trajet', 'Sécurité', 'Travaux', 'Client', 'Technique', 'Clôture',
  ];

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final priority = _priority;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: status.color.withValues(alpha: 0.22), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: status.color.withValues(alpha: 0.08),
        highlightColor: status.color.withValues(alpha: 0.04),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left accent bar ──────────────────────────
              Container(width: 5, color: status.color),

              // ── Card body ────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(
                      intervention: intervention,
                      status: status,
                      priority: priority,
                    ),
                    _InfoSection(intervention: intervention),
                    if (intervention.isStarted || intervention.currentStep > 1)
                      _WorkflowSection(
                        intervention: intervention,
                        status: status,
                        stepLabels: _stepLabels,
                      ),
                    if (intervention.techniciens != null &&
                        intervention.techniciens!.isNotEmpty)
                      _TechnicianSection(
                          techniciens: intervention.techniciens!),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final Intervention intervention;
  final _StatusConfig status;
  final _PriorityConfig priority;

  const _Header({
    required this.intervention,
    required this.status,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    final totalPhotos =
        intervention.photosBeforeCount + intervention.photosAfterCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      color: status.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Number · Type · Status chip ──────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _NumberBadge(numero: intervention.numero, color: status.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  intervention.type,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(status: status),
            ],
          ),

          const SizedBox(height: 9),

          // ── Title ────────────────────────────────────
          Text(
            intervention.titre,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: -0.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 9),

          // ── Priority · Photos · Affaire chips ────────
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _PriorityChip(priority: priority),
              if (totalPhotos > 0) _PhotosChip(count: totalPhotos),
              if (intervention.affaireReference != null &&
                  intervention.affaireReference!.isNotEmpty)
                _AffaireChip(reference: intervention.affaireReference!),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Info Section ─────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final Intervention intervention;

  const _InfoSection({required this.intervention});

  @override
  Widget build(BuildContext context) {
    final hasClient = intervention.clientNom != null &&
        intervention.clientNom!.isNotEmpty;
    final hasAddress = intervention.address != null &&
        intervention.address!.fullAddress.isNotEmpty;
    final hasAccess = intervention.address?.accessInfo.isNotEmpty ?? false;
    final hasDescription = intervention.description != null &&
        intervention.description!.isNotEmpty;
    final hasDate = intervention.datePrevue != null;
    final hasDuration = intervention.dureePrevueHeures != null;
    final hasInterruption =
        intervention.interruptions != null &&
        intervention.interruptions!.any((i) => i.isActive);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Client ───────────────────────────────────
          if (hasClient) ...[
            _InfoRow(
              icon: Icons.business_rounded,
              iconColor: AppColors.accent,
              child: Text(
                intervention.clientNom!,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ── Date + Duration ──────────────────────────
          if (hasDate || hasDuration)
            Row(
              children: [
                if (hasDate)
                  Expanded(
                    child: _InfoRow(
                      icon: Icons.event_rounded,
                      iconColor: AppColors.primary,
                      child: Text(
                        DateFormatter.formatDateTime(intervention.datePrevue),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                if (hasDuration) ...[
                  if (hasDate) const SizedBox(width: 10),
                  _DurationBadge(
                    heures: intervention.dureePrevueHeures!,
                    minutes: intervention.dureePrevueMinutes ?? 0,
                  ),
                ],
              ],
            ),

          // ── Address ──────────────────────────────────
          if (hasAddress) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.location_on_rounded,
              iconColor: const Color(0xFF7B1FA2),
              child: Text(
                intervention.address!.fullAddress,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          // ── Access info ──────────────────────────────
          if (hasAccess) ...[
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.vpn_key_rounded,
              iconColor: AppColors.textHint,
              child: Text(
                intervention.address!.accessInfo,
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          // ── Active interruption banner ───────────────
          if (hasInterruption) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pause_circle_rounded,
                      size: 15, color: AppColors.warning),
                  const SizedBox(width: 6),
                  const Text(
                    'Interruption en cours',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Description ──────────────────────────────
          if (hasDescription) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.notes_rounded,
                    size: 15,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      intervention.description!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Workflow Section ─────────────────────────────────────────

class _WorkflowSection extends StatelessWidget {
  final Intervention intervention;
  final _StatusConfig status;
  final List<String> stepLabels;

  const _WorkflowSection({
    required this.intervention,
    required this.status,
    required this.stepLabels,
  });

  @override
  Widget build(BuildContext context) {
    final current = intervention.currentStep.clamp(1, 6);
    final label =
        current <= stepLabels.length ? stepLabels[current - 1] : 'Étape $current';
    final percent = ((current - 1) / 6 * 100).round();

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status.color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_rounded, size: 14, color: status.color),
              const SizedBox(width: 6),
              Text(
                'Étape $current / 6',
                style: TextStyle(
                  color: status.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '· $label',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '$percent %',
                style: TextStyle(
                  color: status.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Segmented progress bar
          Row(
            children: List.generate(6, (i) {
              final step = i + 1;
              final done = step < current;
              final active = step == current;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: i < 5 ? 3 : 0),
                  decoration: BoxDecoration(
                    color: done
                        ? status.color
                        : active
                            ? status.color.withValues(alpha: 0.45)
                            : AppColors.divider,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Technician Section ───────────────────────────────────────

class _TechnicianSection extends StatelessWidget {
  final List<InterventionTechnician> techniciens;

  const _TechnicianSection({required this.techniciens});

  @override
  Widget build(BuildContext context) {
    final visible = techniciens.take(4).toList();
    final overflow = (techniciens.length - 4).clamp(0, 99);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Row(
        children: [
          const Icon(
            Icons.engineering_rounded,
            size: 15,
            color: AppColors.textHint,
          ),
          const SizedBox(width: 8),
          ...visible.map(
            (t) => Padding(
              padding: const EdgeInsets.only(right: 5),
              child: _AvatarChip(name: t.fullName),
            ),
          ),
          if (overflow > 0)
            _OverflowAvatar(count: overflow),
        ],
      ),
    );
  }
}

// ── Small Widgets ─────────────────────────────────────────────

class _NumberBadge extends StatelessWidget {
  final int numero;
  final Color color;

  const _NumberBadge({required this.numero, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        '#$numero',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final _StatusConfig status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final _PriorityConfig priority;

  const _PriorityChip({required this.priority});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: priority.isUrgent ? priority.color : priority.surface,
        borderRadius: BorderRadius.circular(7),
        border: priority.isUrgent
            ? null
            : Border.all(color: priority.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            priority.icon,
            size: 12,
            color: priority.isUrgent ? Colors.white : priority.color,
          ),
          const SizedBox(width: 4),
          Text(
            priority.label,
            style: TextStyle(
              color: priority.isUrgent ? Colors.white : priority.color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotosChip extends StatelessWidget {
  final int count;

  const _PhotosChip({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFCE93D8).withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.photo_library_rounded,
              size: 12, color: Color(0xFF7B1FA2)),
          const SizedBox(width: 4),
          Text(
            '$count photo${count > 1 ? "s" : ""}',
            style: const TextStyle(
              color: Color(0xFF7B1FA2),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AffaireChip extends StatelessWidget {
  final String reference;

  const _AffaireChip({required this.reference});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
            color: AppColors.statusPlanifie.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.folder_outlined,
              size: 12, color: AppColors.statusPlanifie),
          const SizedBox(width: 4),
          Text(
            reference,
            style: const TextStyle(
              color: AppColors.statusPlanifie,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }
}

class _DurationBadge extends StatelessWidget {
  final int heures;
  final int minutes;

  const _DurationBadge({required this.heures, required this.minutes});

  @override
  Widget build(BuildContext context) {
    final label = minutes > 0
        ? '${heures}h${minutes.toString().padLeft(2, '0')}'
        : '${heures}h';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_rounded, size: 13, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarChip extends StatelessWidget {
  final String name;

  const _AvatarChip({required this.name});

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color get _color {
    final hash = name.codeUnits.fold(0, (a, b) => a + b);
    return AppColors.avatarPalette[hash % AppColors.avatarPalette.length];
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: name,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: _color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Center(
          child: Text(
            _initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _OverflowAvatar extends StatelessWidget {
  final int count;

  const _OverflowAvatar({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          '+$count',
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Config objects ────────────────────────────────────────────

class _StatusConfig {
  final Color color;
  final Color surface;
  final IconData icon;
  final String label;

  const _StatusConfig({
    required this.color,
    required this.surface,
    required this.icon,
    required this.label,
  });
}

class _PriorityConfig {
  final Color color;
  final Color surface;
  final IconData icon;
  final String label;
  final bool isUrgent;

  const _PriorityConfig({
    required this.color,
    required this.surface,
    required this.icon,
    required this.label,
    required this.isUrgent,
  });
}
