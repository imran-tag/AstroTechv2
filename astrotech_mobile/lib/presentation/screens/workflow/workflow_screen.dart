import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/intervention.dart';
import '../../../domain/entities/workflow_step.dart';
import '../../blocs/workflow/workflow_bloc.dart';
import 'steps/security_checklist_step.dart';
import 'steps/photos_before_step.dart';
import 'steps/photos_after_step.dart';
import 'steps/quality_control_step.dart';
import 'steps/observations_step.dart';
import 'steps/technical_observations_step.dart';
import 'steps/technician_signature_step.dart';
import 'steps/additional_work_description_step.dart';
import 'steps/additional_work_photos_step.dart';
import 'steps/additional_work_signature_step.dart';
import 'steps/delivery_note_photos_step.dart';
import 'steps/quote_comment_step.dart';
import 'steps/quote_photos_step.dart';
import 'steps/quote_signature_step.dart';
import '../intervention/intervention_recap_screen.dart';

class WorkflowScreen extends StatelessWidget {
  final Intervention intervention;

  const WorkflowScreen({
    super.key,
    required this.intervention,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WorkflowBloc, WorkflowState>(
      listener: (context, state) {
        if (state is WorkflowCompleted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => InterventionRecapScreen(
                intervention: intervention,
                workflowState: state.completedWorkflow,
                completedAt: state.completedAt,
              ),
            ),
          );
        }

        if (state is WorkflowInProgress && state.error != null) {
          // Don't show banner for "sauvegardé localement" messages
          if (!state.error!.toLowerCase().contains('localement')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      },
      builder: (context, state) {
        if (state is! WorkflowInProgress) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(WorkflowNavigation.getStepTitle(state.currentStep)),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _showExitConfirmation(context),
            ),
            actions: [
              // Active interruption indicator
              if (state.interruptions.any((i) => i.isActive))
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pause_circle, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'Interruption',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Travel time indicator
              if (state.travelStartTime != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.directions_car, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'Trajet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  // Progress indicator
                  _buildProgressBar(state),

                  // Saving indicator
                  if (state.isSaving)
                    const LinearProgressIndicator(),

                  // Step content
                  Expanded(
                    child: _buildStepContent(context, state),
                  ),

                  // Navigation buttons
                  _buildNavigationButtons(context, state),
                ],
              ),

              // Floating action buttons for interruptions and travel time
              _buildFloatingButtons(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(WorkflowInProgress state) {
    final progress = WorkflowNavigation.calculateProgress(
      state.currentStep,
      state.completedBranches,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Linear progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 8,
              backgroundColor: AppColors.stepPending,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 100 ? AppColors.success : AppColors.stepCurrent,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                WorkflowNavigation.getStepTitle(state.currentStep),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$progress%',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Show completed branches if any
          if (state.completedBranches.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: state.completedBranches.map((branch) {
                return Chip(
                  label: Text(
                    _getBranchLabel(branch),
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: AppColors.stepComplete,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _getBranchLabel(String branch) {
    switch (branch) {
      case 'additional_work':
        return 'Travaux supp.';
      case 'delivery_note':
        return 'Bon livraison';
      case 'quote':
        return 'Devis';
      default:
        return branch;
    }
  }

  Widget _buildStepContent(BuildContext context, WorkflowInProgress state) {
    switch (state.currentStep) {
      case WorkflowStep.securityChecklist:
        return SecurityChecklistStep(
          values: state.securityChecklist,
          onChanged: (values) {
            context.read<WorkflowBloc>().add(SaveSecurityChecklist(values));
          },
        );

      case WorkflowStep.photosBeforeIntervention:
        return PhotosBeforeStep(
          photos: state.photosBefore,
          interventionId: state.interventionId,
        );

      case WorkflowStep.photosAfterIntervention:
        return PhotosAfterStep(
          photos: state.photosAfter,
          interventionId: state.interventionId,
        );

      case WorkflowStep.qualityChecklist:
        return QualityControlStep(
          values: state.qualityControl,
          onChanged: (values) {
            context.read<WorkflowBloc>().add(SaveQualityControl(values));
          },
        );

      case WorkflowStep.observations:
        return ObservationsStep(
          observations: state.clientObservations,
          rating: state.clientRating,
          hasSignature: state.hasClientSignature,
          onSaveObservations: (text) {
            context.read<WorkflowBloc>().add(SaveClientObservations(text));
          },
          onSaveRating: (rating) {
            context.read<WorkflowBloc>().add(SaveClientRating(rating));
          },
          onSaveSignature: (bytes) {
            context.read<WorkflowBloc>().add(SaveClientSignature(bytes));
          },
        );

      case WorkflowStep.technicalObservations:
        return TechnicalObservationsStep(
          selectedChoice: state.technicalObservationsChoice,
          completedBranches: state.completedBranches,
          loopCount: state.loopCount,
          onSelect: (choice) {
            context.read<WorkflowBloc>().add(SelectTechnicalObservation(choice));
          },
        );

      case WorkflowStep.additionalWorkDescription:
        return AdditionalWorkDescriptionStep(
          description: state.additionalWorkDescription,
          onSave: (description) {
            context.read<WorkflowBloc>().add(
              SaveAdditionalWorkDescription(description),
            );
          },
        );

      case WorkflowStep.additionalWorkPhotos:
        return AdditionalWorkPhotosStep(
          photos: state.additionalWorkPhotos,
          interventionId: state.interventionId,
        );

      case WorkflowStep.additionalWorkSignature:
        return AdditionalWorkSignatureStep(
          hasSignature: state.hasAdditionalWorkSignature,
          onSave: (bytes) {
            context.read<WorkflowBloc>().add(
              SaveAdditionalWorkSignature(bytes),
            );
          },
        );

      case WorkflowStep.deliveryNotePhotos:
        return DeliveryNotePhotosStep(
          photos: state.deliveryNotePhotos,
          interventionId: state.interventionId,
        );

      case WorkflowStep.quoteComment:
        return QuoteCommentStep(
          comment: state.quoteComment,
          onSave: (comment) {
            context.read<WorkflowBloc>().add(SaveQuoteComment(comment));
          },
        );

      case WorkflowStep.quotePhotos:
        return QuotePhotosStep(
          photos: state.quotePhotos,
          interventionId: state.interventionId,
        );

      case WorkflowStep.quoteSignature:
        return QuoteSignatureStep(
          hasSignature: state.hasQuoteSignature,
          onSave: (bytes) {
            context.read<WorkflowBloc>().add(SaveQuoteSignature(bytes));
          },
        );

      case WorkflowStep.technicianSignature:
        return TechnicianSignatureStep(
          hasSignature: state.hasTechnicianSignature,
          onSave: (bytes) {
            context.read<WorkflowBloc>().add(SaveTechnicianSignature(bytes));
          },
        );

      case WorkflowStep.completed:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 80, color: AppColors.success),
              SizedBox(height: 16),
              Text(
                'Intervention terminée !',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildNavigationButtons(BuildContext context, WorkflowInProgress state) {
    final canGoBack = state.currentStep != WorkflowStep.securityChecklist &&
                       state.currentStep != WorkflowStep.completed;
    final isLastStep = state.currentStep == WorkflowStep.technicianSignature;
    final isCompleted = state.currentStep == WorkflowStep.completed;

    if (isCompleted) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Previous button
            if (canGoBack)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.isSaving
                      ? null
                      : () {
                          context.read<WorkflowBloc>().add(PreviousStep());
                        },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text(AppStrings.previous),
                ),
              ),

            if (canGoBack)
              const SizedBox(width: 16),

            // Next/Finish button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: state.isSaving || !state.canProceedFromCurrentStep()
                    ? null
                    : () {
                        if (isLastStep) {
                          _showFinishConfirmation(context);
                        } else {
                          context.read<WorkflowBloc>().add(NextStep());
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLastStep
                      ? AppColors.success
                      : AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                icon: Icon(
                  isLastStep ? Icons.check : Icons.arrow_forward,
                ),
                label: Text(
                  isLastStep ? AppStrings.finish : AppStrings.next,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButtons(BuildContext context, WorkflowInProgress state) {
    return Positioned(
      right: 16,
      bottom: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Interruption button
          FloatingActionButton(
            heroTag: 'interruption',
            onPressed: () => _showInterruptionDialog(context, state),
            backgroundColor: state.interruptions.any((i) => i.isActive)
                ? AppColors.warning
                : AppColors.primary,
            child: Icon(
              state.interruptions.any((i) => i.isActive)
                  ? Icons.play_circle
                  : Icons.pause_circle,
            ),
          ),
          const SizedBox(height: 12),

          // Travel time button
          FloatingActionButton(
            heroTag: 'travel',
            onPressed: () => _handleTravelTime(context, state),
            backgroundColor: state.travelStartTime != null
                ? AppColors.success
                : AppColors.primary,
            child: Icon(
              state.travelStartTime != null
                  ? Icons.stop
                  : Icons.directions_car,
            ),
          ),
        ],
      ),
    );
  }

  void _showInterruptionDialog(BuildContext context, WorkflowInProgress state) {
    // Show "under development" message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité en cours de développement'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  void _handleTravelTime(BuildContext context, WorkflowInProgress state) {
    // Show "under development" message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité en cours de développement'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter le workflow ?'),
        content: const Text(
          'Votre progression est sauvegardée. Vous pourrez reprendre plus tard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close workflow
            },
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }

  void _showFinishConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Terminer l\'intervention ?'),
        content: const Text(AppStrings.confirmFinishIntervention),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<WorkflowBloc>().add(CompleteWorkflow());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );
  }
}
