import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/intervention.dart';
import '../../../injection_container.dart';
import '../../blocs/intervention/intervention_bloc.dart';
import '../../blocs/workflow/workflow_bloc.dart';
import '../workflow/workflow_screen.dart';

class InterventionDetailScreen extends StatefulWidget {
  final int interventionId;

  const InterventionDetailScreen({
    super.key,
    required this.interventionId,
  });

  @override
  State<InterventionDetailScreen> createState() => _InterventionDetailScreenState();
}

class _InterventionDetailScreenState extends State<InterventionDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<InterventionBloc>().add(
          LoadInterventionDetail(id: widget.interventionId, forceRefresh: true),
        );
  }

  void _startWorkflow(Intervention intervention) {
    // Update status to "en_cours" if not already
    if (intervention.etat != 'en_cours' && intervention.etat != 'termine') {
      context.read<InterventionBloc>().add(
            UpdateStatus(
              interventionId: intervention.id,
              status: 'en_cours',
            ),
          );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (_) => getIt<WorkflowBloc>()..add(InitializeWorkflow(intervention)),
          child: WorkflowScreen(intervention: intervention),
        ),
      ),
    ).then((_) {
      // Refresh when returning
      context.read<InterventionBloc>().add(
            LoadInterventionDetail(id: widget.interventionId, forceRefresh: true),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail intervention'),
      ),
      body: BlocBuilder<InterventionBloc, InterventionState>(
        builder: (context, state) {
          if (state is InterventionLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is InterventionError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<InterventionBloc>().add(
                            LoadInterventionDetail(id: widget.interventionId),
                          );
                    },
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            );
          }

          if (state is! InterventionDetailLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final intervention = state.intervention;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                intervention.titre,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            _buildStatusBadge(intervention.etat),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildPriorityBadge(intervention.priorite),
                            const SizedBox(width: 8),
                            Text(
                              '#${intervention.numero}',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            const Spacer(),
                            Text(
                              intervention.type,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Date & Duration
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          Icons.calendar_today,
                          'Date prévue',
                          DateFormatter.formatDateTime(intervention.datePrevue),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.timer_outlined,
                          'Durée estimée',
                          DateFormatter.formatDuration(
                            intervention.dureePrevueHeures,
                            intervention.dureePrevueMinutes,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Address
                if (intervention.address != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Adresse',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            intervention.address!.fullAddress,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          if (intervention.address!.accessInfo.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              intervention.address!.accessInfo,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Description
                if (intervention.description != null &&
                    intervention.description!.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(intervention.description!),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Workflow progress
                if (intervention.workflow != null || intervention.isStarted) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Progression',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          _buildWorkflowProgress(intervention),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Client info
                if (intervention.clientNom != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildInfoRow(
                        Icons.person_outline,
                        'Client',
                        intervention.clientNom!,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Affaire info
                if (intervention.affaireTitre != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildInfoRow(
                        Icons.folder_outlined,
                        'Affaire',
                        '${intervention.affaireReference ?? ''} - ${intervention.affaireTitre}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Team
                if (intervention.techniciens != null &&
                    intervention.techniciens!.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Équipe',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ...intervention.techniciens!.map(
                            (tech) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.person, size: 20),
                                  const SizedBox(width: 8),
                                  Text(tech.fullName),
                                  if (tech.role != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '(${tech.role})',
                                      style: TextStyle(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          );
        },
      ),
      floatingActionButton: BlocBuilder<InterventionBloc, InterventionState>(
        builder: (context, state) {
          if (state is! InterventionDetailLoaded) return const SizedBox.shrink();

          final intervention = state.intervention;

          // Don't show button if completed
          if (intervention.etat == 'termine') {
            return FloatingActionButton.extended(
              onPressed: () => _startWorkflow(intervention),
              backgroundColor: AppColors.success,
              icon: const Icon(Icons.visibility),
              label: const Text('Voir le workflow'),
            );
          }

          return FloatingActionButton.extended(
            onPressed: () => _startWorkflow(intervention),
            backgroundColor: AppColors.primary,
            icon: Icon(
              intervention.isStarted ? Icons.play_arrow : Icons.play_arrow,
            ),
            label: Text(
              intervention.isStarted
                  ? AppStrings.continueIntervention
                  : AppStrings.startIntervention,
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color color;
    String label;

    switch (status) {
      case 'planifie':
        color = AppColors.statusPlanifie;
        label = AppStrings.statusPlanifie;
        break;
      case 'en_cours':
        color = AppColors.statusEnCours;
        label = AppStrings.statusEnCours;
        break;
      case 'termine':
        color = AppColors.statusTermine;
        label = AppStrings.statusTermine;
        break;
      case 'non_validee':
        color = AppColors.statusNonValidee;
        label = AppStrings.statusNonValidee;
        break;
      default:
        color = AppColors.textHint;
        label = status ?? 'Inconnu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildPriorityBadge(String? priority) {
    Color color;

    switch (priority?.toLowerCase()) {
      case 'urgent':
      case 'urgente':
        color = AppColors.priorityUrgent;
        break;
      case 'haute':
      case 'high':
        color = AppColors.priorityHigh;
        break;
      case 'normale':
      case 'normal':
        color = AppColors.priorityNormal;
        break;
      default:
        color = AppColors.priorityLow;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority ?? 'Normal',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkflowProgress(Intervention intervention) {
    final currentStep = intervention.currentStep;

    return Row(
      children: List.generate(6, (index) {
        final step = index + 1;
        final isComplete = step < currentStep;
        final isCurrent = step == currentStep;

        return Expanded(
          child: Container(
            height: 8,
            margin: EdgeInsets.only(right: index < 5 ? 4 : 0),
            decoration: BoxDecoration(
              color: isComplete
                  ? AppColors.stepComplete
                  : isCurrent
                      ? AppColors.stepCurrent
                      : AppColors.stepPending,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}
