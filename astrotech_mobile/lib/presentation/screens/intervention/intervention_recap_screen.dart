import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/intervention.dart';
import '../../blocs/workflow/workflow_bloc.dart';

class InterventionRecapScreen extends StatelessWidget {
  final Intervention intervention;
  final WorkflowInProgress workflowState;
  final DateTime completedAt;

  const InterventionRecapScreen({
    super.key,
    required this.intervention,
    required this.workflowState,
    required this.completedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Rapport d\'intervention'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () => _closeRecap(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
            label: const Text('Fermer', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SuccessHeader(
              intervention: intervention,
              completedAt: completedAt,
              startedAt: intervention.workflow?.startedAt,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _InfoCard(intervention: intervention),
                  const SizedBox(height: 16),
                  _ChecklistSection(
                    title: 'Checklist Sécurité',
                    icon: Icons.health_and_safety_rounded,
                    accentColor: AppColors.warning,
                    items: const [
                      AppStrings.securityItem1,
                      AppStrings.securityItem2,
                      AppStrings.securityItem3,
                    ],
                    values: workflowState.securityChecklist,
                  ),
                  if (workflowState.photosBefore.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _PhotosSection(
                      title: 'Photos avant intervention',
                      icon: Icons.camera_alt_rounded,
                      accentColor: AppColors.statusPlanifie,
                      photos: workflowState.photosBefore,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _ChecklistSection(
                    title: 'Contrôle Qualité',
                    icon: Icons.verified_rounded,
                    accentColor: AppColors.info,
                    items: const [
                      AppStrings.qcItem1,
                      AppStrings.qcItem2,
                      AppStrings.qcItem3,
                    ],
                    values: workflowState.qualityControl,
                  ),
                  const SizedBox(height: 16),
                  _ObservationsSection(workflowState: workflowState),
                  const SizedBox(height: 16),
                  _TechnicalSection(workflowState: workflowState),
                  if (workflowState.photosAfter.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _PhotosSection(
                      title: 'Photos après intervention',
                      icon: Icons.camera_alt_rounded,
                      accentColor: AppColors.success,
                      photos: workflowState.photosAfter,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _SignatureLine(
                    label: 'Signature Technicien',
                    isSigned: workflowState.hasTechnicianSignature,
                    icon: Icons.engineering_rounded,
                    accentColor: AppColors.primary,
                  ),
                  if (workflowState.interruptions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _InterruptionsSection(interruptions: workflowState.interruptions),
                  ],
                  const SizedBox(height: 16),
                  _TimeSection(
                    startedAt: intervention.workflow?.startedAt,
                    completedAt: completedAt,
                    travelDurationMinutes: intervention.workflow?.travelDurationMinutes,
                    interruptions: workflowState.interruptions,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _closeRecap(context),
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text(
                      'Retour à la liste',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _closeRecap(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

// ── Success Header ────────────────────────────────────────────

class _SuccessHeader extends StatelessWidget {
  final Intervention intervention;
  final DateTime completedAt;
  final DateTime? startedAt;

  const _SuccessHeader({
    required this.intervention,
    required this.completedAt,
    this.startedAt,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm', 'fr');
    Duration? totalDuration;
    if (startedAt != null) {
      totalDuration = completedAt.difference(startedAt!);
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 44,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Intervention Terminée',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '#${intervention.numero} — ${intervention.titre}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time_rounded, color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                Text(
                  dateFormat.format(completedAt),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (totalDuration != null) ...[
            const SizedBox(height: 8),
            Text(
              'Durée totale : ${_formatDuration(totalDuration)}',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}min';
    return '${m}min';
  }
}

// ── Info Card ─────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final Intervention intervention;

  const _InfoCard({required this.intervention});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Informations',
      icon: Icons.info_outline_rounded,
      accentColor: AppColors.primary,
      child: Column(
        children: [
          _InfoRow(icon: Icons.category_rounded, label: 'Type', value: intervention.type),
          if (intervention.clientNom != null && intervention.clientNom!.isNotEmpty)
            _InfoRow(icon: Icons.person_rounded, label: 'Client', value: intervention.clientNom!),
          if (intervention.address != null && intervention.address!.fullAddress.isNotEmpty)
            _InfoRow(
              icon: Icons.location_on_rounded,
              label: 'Adresse',
              value: intervention.address!.fullAddress,
            ),
          if (intervention.address != null && intervention.address!.accessInfo.isNotEmpty)
            _InfoRow(
              icon: Icons.vpn_key_rounded,
              label: 'Accès',
              value: intervention.address!.accessInfo,
            ),
          if (intervention.affaireReference != null)
            _InfoRow(
              icon: Icons.folder_rounded,
              label: 'Affaire',
              value: intervention.affaireReference!,
            ),
          if (intervention.datePrevue != null)
            _InfoRow(
              icon: Icons.calendar_today_rounded,
              label: 'Date prévue',
              value: DateFormat('dd/MM/yyyy', 'fr').format(intervention.datePrevue!),
            ),
          if (intervention.priorite != null)
            _InfoRow(
              icon: Icons.flag_rounded,
              label: 'Priorité',
              value: intervention.priorityLabel,
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Checklist Section ─────────────────────────────────────────

class _ChecklistSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<String> items;
  final List<bool> values;

  const _ChecklistSection({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.items,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    final checkedCount = values.where((v) => v).length;

    return _SectionCard(
      title: title,
      icon: icon,
      accentColor: accentColor,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: checkedCount == items.length
              ? AppColors.success.withValues(alpha: 0.12)
              : AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$checkedCount/${items.length}',
          style: TextStyle(
            color: checkedCount == items.length ? AppColors.success : AppColors.warning,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final checked = i < values.length && values[i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: checked
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.error.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    checked ? Icons.check_rounded : Icons.close_rounded,
                    size: 14,
                    color: checked ? AppColors.success : AppColors.error,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    items[i],
                    style: TextStyle(
                      fontSize: 14,
                      color: checked ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: checked ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Photos Section ────────────────────────────────────────────

class _PhotosSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<InterventionPhoto> photos;

  const _PhotosSection({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.photos,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      icon: icon,
      accentColor: accentColor,
      trailing: _CountBadge(count: photos.length, color: accentColor),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          return _PhotoThumbnail(
            photo: photos[index],
            onTap: () => _showPhotoFullscreen(context, photos, index),
          );
        },
      ),
    );
  }

  void _showPhotoFullscreen(
    BuildContext context,
    List<InterventionPhoto> photos,
    int initialIndex,
  ) {
    showDialog(
      context: context,
      builder: (_) => _PhotoFullscreenDialog(
        photos: photos,
        initialIndex: initialIndex,
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final InterventionPhoto photo;
  final VoidCallback onTap;

  const _PhotoThumbnail({required this.photo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (photo.localPath != null) {
      image = Image.file(
        File(photo.localPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } else {
      final serverRoot = ApiConstants.baseUrl
          .replaceAll('/api/v1/affaires', '')
          .replaceAll('/api/v1', '');
      image = Image.network(
        '$serverRoot${photo.filePath}',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: image,
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Icon(Icons.broken_image_rounded, color: AppColors.textHint),
    );
  }
}

class _PhotoFullscreenDialog extends StatefulWidget {
  final List<InterventionPhoto> photos;
  final int initialIndex;

  const _PhotoFullscreenDialog({
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<_PhotoFullscreenDialog> createState() => _PhotoFullscreenDialogState();
}

class _PhotoFullscreenDialogState extends State<_PhotoFullscreenDialog> {
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_current];
    Widget image;
    if (photo.localPath != null) {
      image = Image.file(File(photo.localPath!), fit: BoxFit.contain);
    } else {
      final serverRoot = ApiConstants.baseUrl
          .replaceAll('/api/v1/affaires', '')
          .replaceAll('/api/v1', '');
      image = Image.network('$serverRoot${photo.filePath}', fit: BoxFit.contain);
    }

    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text('Photo ${_current + 1}/${widget.photos.length}'),
        ),
        body: Column(
          children: [
            Expanded(child: InteractiveViewer(child: Center(child: image))),
            if (widget.photos.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _current > 0
                          ? () => setState(() => _current--)
                          : null,
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                    ),
                    Text(
                      '${_current + 1} / ${widget.photos.length}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    IconButton(
                      onPressed: _current < widget.photos.length - 1
                          ? () => setState(() => _current++)
                          : null,
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Observations Section ──────────────────────────────────────

class _ObservationsSection extends StatelessWidget {
  final WorkflowInProgress workflowState;

  const _ObservationsSection({required this.workflowState});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Observations Client',
      icon: Icons.chat_bubble_outline_rounded,
      accentColor: AppColors.statusEnCours,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (workflowState.clientRating != null) ...[
            Row(
              children: [
                const Text(
                  'Évaluation',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                ...List.generate(5, (i) {
                  return Icon(
                    i < (workflowState.clientRating ?? 0)
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 20,
                    color: Colors.amber,
                  );
                }),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (workflowState.clientObservations.isNotEmpty) ...[
            const Text(
              'Observations',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.surfaceVariant),
              ),
              child: Text(
                workflowState.clientObservations,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          _SignatureLine(
            label: 'Signature Client',
            isSigned: workflowState.hasClientSignature,
            icon: Icons.person_rounded,
            accentColor: AppColors.statusEnCours,
          ),
        ],
      ),
    );
  }
}

// ── Technical Section ─────────────────────────────────────────

class _TechnicalSection extends StatelessWidget {
  final WorkflowInProgress workflowState;

  const _TechnicalSection({required this.workflowState});

  @override
  Widget build(BuildContext context) {
    final choice = workflowState.technicalObservationsChoice;
    final branches = workflowState.completedBranches;

    return _SectionCard(
      title: 'Observations Techniques',
      icon: Icons.build_rounded,
      accentColor: AppColors.textSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Choice badge
          if (choice != null) ...[
            Row(
              children: [
                const Text(
                  'Décision :',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                _ChoiceBadge(choice: choice),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Completed branches
          if (branches.isNotEmpty) ...[
            const Text(
              'Branches complétées :',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: branches.map((b) => _BranchChip(branch: b)).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Additional Work
          if (branches.contains('additional_work')) ...[
            _BranchBlock(
              title: 'Travaux Supplémentaires',
              icon: Icons.handyman_rounded,
              color: AppColors.statusEnCours,
              children: [
                if (workflowState.additionalWorkDescription.isNotEmpty)
                  _TextBlock(
                    label: 'Description',
                    text: workflowState.additionalWorkDescription,
                  ),
                if (workflowState.additionalWorkPhotos.isNotEmpty)
                  _MiniPhotoGrid(photos: workflowState.additionalWorkPhotos),
                _SignatureLine(
                  label: 'Signature',
                  isSigned: workflowState.hasAdditionalWorkSignature,
                  icon: Icons.draw_rounded,
                  accentColor: AppColors.statusEnCours,
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Quote
          if (branches.contains('quote')) ...[
            _BranchBlock(
              title: 'Devis',
              icon: Icons.request_quote_rounded,
              color: Colors.purple,
              children: [
                if (workflowState.quoteComment.isNotEmpty)
                  _TextBlock(label: 'Commentaire', text: workflowState.quoteComment),
                if (workflowState.quotePhotos.isNotEmpty)
                  _MiniPhotoGrid(photos: workflowState.quotePhotos),
                _SignatureLine(
                  label: 'Signature',
                  isSigned: workflowState.hasQuoteSignature,
                  icon: Icons.draw_rounded,
                  accentColor: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Delivery Note
          if (branches.contains('delivery_note')) ...[
            _BranchBlock(
              title: 'Bon de Livraison',
              icon: Icons.receipt_long_rounded,
              color: Colors.orange,
              children: [
                if (workflowState.deliveryNotePhotos.isNotEmpty)
                  _MiniPhotoGrid(photos: workflowState.deliveryNotePhotos),
              ],
            ),
          ],

          if (choice == 'finish' && branches.isEmpty)
            const Text(
              'Intervention terminée directement sans travaux supplémentaires.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }
}

class _ChoiceBadge extends StatelessWidget {
  final String choice;

  const _ChoiceBadge({required this.choice});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (choice) {
      'finish' => ('Terminé', AppColors.success),
      'additional_work' => ('Travaux supp.', AppColors.statusEnCours),
      'quote' => ('Devis', Colors.purple),
      'delivery_note' => ('Bon livraison', Colors.orange),
      _ => (choice, AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BranchChip extends StatelessWidget {
  final String branch;

  const _BranchChip({required this.branch});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (branch) {
      'additional_work' => ('Travaux supp.', AppColors.statusEnCours),
      'quote' => ('Devis', Colors.purple),
      'delivery_note' => ('Bon livraison', Colors.orange),
      _ => (branch, AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchBlock extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _BranchBlock({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _TextBlock extends StatelessWidget {
  final String label;
  final String text;

  const _TextBlock({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _MiniPhotoGrid extends StatelessWidget {
  final List<InterventionPhoto> photos;

  const _MiniPhotoGrid({required this.photos});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${photos.length} photo${photos.length > 1 ? 's' : ''}',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final photo = photos[i];
              Widget img;
              if (photo.localPath != null) {
                img = Image.file(File(photo.localPath!), fit: BoxFit.cover);
              } else {
                final serverRoot = ApiConstants.baseUrl
                    .replaceAll('/api/v1/affaires', '')
                    .replaceAll('/api/v1', '');
                img = Image.network(
                  '$serverRoot${photo.filePath}',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.image, size: 24, color: AppColors.textHint),
                  ),
                );
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(width: 72, child: img),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

// ── Signature Line ────────────────────────────────────────────

class _SignatureLine extends StatelessWidget {
  final String label;
  final bool isSigned;
  final IconData icon;
  final Color accentColor;

  const _SignatureLine({
    required this.label,
    required this.isSigned,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isSigned
            ? AppColors.success.withValues(alpha: 0.08)
            : AppColors.textHint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSigned
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.textHint.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isSigned ? AppColors.success : AppColors.textHint),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isSigned ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isSigned ? AppColors.success : AppColors.textHint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isSigned ? 'Signé ✓' : 'Non signé',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Interruptions Section ─────────────────────────────────────

class _InterruptionsSection extends StatelessWidget {
  final List<InterventionInterruption> interruptions;

  const _InterruptionsSection({required this.interruptions});

  @override
  Widget build(BuildContext context) {
    final totalMinutes = interruptions
        .where((i) => i.durationMinutes != null)
        .fold(0, (sum, i) => sum + (i.durationMinutes ?? 0));

    return _SectionCard(
      title: 'Interruptions',
      icon: Icons.pause_circle_outline_rounded,
      accentColor: AppColors.warning,
      trailing: _CountBadge(count: interruptions.length, color: AppColors.warning),
      child: Column(
        children: [
          ...interruptions.map((interruption) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _reasonIcon(interruption.reason),
                      size: 14,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _reasonLabel(interruption.reason),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (interruption.durationMinutes != null)
                    Text(
                      '${interruption.durationMinutes}min',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            );
          }),
          if (totalMinutes > 0) ...[
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total interruptions',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$totalMinutes min',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _reasonIcon(String reason) {
    switch (reason) {
      case 'material_purchase':
        return Icons.shopping_cart_rounded;
      case 'lunch_break':
        return Icons.restaurant_rounded;
      default:
        return Icons.pause_rounded;
    }
  }

  String _reasonLabel(String reason) {
    switch (reason) {
      case 'material_purchase':
        return 'Achat de matériel';
      case 'lunch_break':
        return 'Pause déjeuner';
      default:
        return 'Autre';
    }
  }
}

// ── Time Section ──────────────────────────────────────────────

class _TimeSection extends StatelessWidget {
  final DateTime? startedAt;
  final DateTime completedAt;
  final int? travelDurationMinutes;
  final List<InterventionInterruption> interruptions;

  const _TimeSection({
    this.startedAt,
    required this.completedAt,
    this.travelDurationMinutes,
    required this.interruptions,
  });

  @override
  Widget build(BuildContext context) {
    final totalDuration =
        startedAt != null ? completedAt.difference(startedAt!) : null;
    final interruptionMinutes = interruptions
        .where((i) => i.durationMinutes != null)
        .fold(0, (sum, i) => sum + (i.durationMinutes ?? 0));

    return _SectionCard(
      title: 'Récapitulatif Temps',
      icon: Icons.schedule_rounded,
      accentColor: AppColors.primary,
      child: Column(
        children: [
          if (startedAt != null)
            _TimeRow(
              label: 'Début',
              value: DateFormat('HH:mm', 'fr').format(startedAt!),
            ),
          _TimeRow(
            label: 'Fin',
            value: DateFormat('HH:mm', 'fr').format(completedAt),
          ),
          if (totalDuration != null) ...[
            const Divider(height: 16),
            _TimeRow(
              label: 'Durée totale',
              value: _fmt(totalDuration),
              bold: true,
            ),
          ],
          if (travelDurationMinutes != null && travelDurationMinutes! > 0)
            _TimeRow(
              label: 'Temps de trajet',
              value: '${travelDurationMinutes}min',
            ),
          if (interruptionMinutes > 0)
            _TimeRow(
              label: 'Interruptions',
              value: '${interruptionMinutes}min',
            ),
          if (totalDuration != null && interruptionMinutes > 0) ...[
            const Divider(height: 16),
            _TimeRow(
              label: 'Temps effectif',
              value: _fmt(totalDuration - Duration(minutes: interruptionMinutes)),
              bold: true,
              valueColor: AppColors.success,
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}min';
    return '${m}min';
  }
}

class _TimeRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _TimeRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? (bold ? AppColors.textPrimary : AppColors.textSecondary),
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Helpers ────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;

  const _CountBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 17, color: accentColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
