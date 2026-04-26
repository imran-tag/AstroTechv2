/// Workflow Step Enumeration
/// Defines all possible steps in the Solitech-style intervention workflow
enum WorkflowStep {
  // Main workflow steps (linear)
  securityChecklist,
  photosBeforeIntervention,
  photosAfterIntervention,
  qualityChecklist,
  observations, // Combined: client obs + rating + signature
  technicalObservations, // Choice point for branching

  // Additional Work Branch
  additionalWorkDescription,
  additionalWorkPhotos,
  additionalWorkSignature,

  // Delivery Note Branch
  deliveryNotePhotos,

  // Quote Branch
  quoteComment,
  quotePhotos,
  quoteSignature,

  // Final step
  technicianSignature,
  completed,
}

/// Workflow Navigation Logic
/// Handles conditional branching based on technical observations choice
class WorkflowNavigation {
  /// Get the next workflow step based on current step and user choices
  static WorkflowStep? getNextStep(
    WorkflowStep current,
    String? technicalObsChoice,
  ) {
    switch (current) {
      // Main linear flow
      case WorkflowStep.securityChecklist:
        return WorkflowStep.photosBeforeIntervention;

      case WorkflowStep.photosBeforeIntervention:
        return WorkflowStep.photosAfterIntervention;

      case WorkflowStep.photosAfterIntervention:
        return WorkflowStep.qualityChecklist;

      case WorkflowStep.qualityChecklist:
        return WorkflowStep.observations;

      case WorkflowStep.observations:
        return WorkflowStep.technicalObservations;

      case WorkflowStep.technicalObservations:
        return _handleTechnicalChoice(technicalObsChoice);

      // Additional Work Branch - loops back to technical observations
      case WorkflowStep.additionalWorkDescription:
        return WorkflowStep.additionalWorkPhotos;

      case WorkflowStep.additionalWorkPhotos:
        return WorkflowStep.additionalWorkSignature;

      case WorkflowStep.additionalWorkSignature:
        return WorkflowStep.technicalObservations;

      // Delivery Note Branch - loops back to technical observations
      case WorkflowStep.deliveryNotePhotos:
        return WorkflowStep.technicalObservations;

      // Quote Branch - loops back to technical observations
      case WorkflowStep.quoteComment:
        return WorkflowStep.quotePhotos;

      case WorkflowStep.quotePhotos:
        return WorkflowStep.quoteSignature;

      case WorkflowStep.quoteSignature:
        return WorkflowStep.technicalObservations;

      // Final step
      case WorkflowStep.technicianSignature:
        return WorkflowStep.completed;

      case WorkflowStep.completed:
        return null; // No next step
    }
  }

  /// Get the previous workflow step (for back navigation)
  static WorkflowStep? getPreviousStep(
    WorkflowStep current,
    List<String> completedBranches,
  ) {
    switch (current) {
      case WorkflowStep.photosBeforeIntervention:
        return WorkflowStep.securityChecklist;

      case WorkflowStep.photosAfterIntervention:
        return WorkflowStep.photosBeforeIntervention;

      case WorkflowStep.qualityChecklist:
        return WorkflowStep.photosAfterIntervention;

      case WorkflowStep.observations:
        return WorkflowStep.qualityChecklist;

      case WorkflowStep.technicalObservations:
        return WorkflowStep.observations;

      // Branch steps
      case WorkflowStep.additionalWorkDescription:
        return WorkflowStep.technicalObservations;

      case WorkflowStep.additionalWorkPhotos:
        return WorkflowStep.additionalWorkDescription;

      case WorkflowStep.additionalWorkSignature:
        return WorkflowStep.additionalWorkPhotos;

      case WorkflowStep.deliveryNotePhotos:
        return WorkflowStep.technicalObservations;

      case WorkflowStep.quoteComment:
        return WorkflowStep.technicalObservations;

      case WorkflowStep.quotePhotos:
        return WorkflowStep.quoteComment;

      case WorkflowStep.quoteSignature:
        return WorkflowStep.quotePhotos;

      case WorkflowStep.technicianSignature:
        return WorkflowStep.technicalObservations;

      default:
        return null;
    }
  }

  /// Handle technical observations choice to determine next branch
  static WorkflowStep? _handleTechnicalChoice(String? choice) {
    if (choice == null) return null;

    switch (choice) {
      case 'additional_work':
        return WorkflowStep.additionalWorkDescription;

      case 'delivery_note':
        return WorkflowStep.deliveryNotePhotos;

      case 'quote':
        return WorkflowStep.quoteComment;

      case 'finish':
        return WorkflowStep.technicianSignature;

      default:
        return null;
    }
  }

  /// Check if a step is part of a branch (not main flow)
  static bool isBranchStep(WorkflowStep step) {
    return [
      WorkflowStep.additionalWorkDescription,
      WorkflowStep.additionalWorkPhotos,
      WorkflowStep.additionalWorkSignature,
      WorkflowStep.deliveryNotePhotos,
      WorkflowStep.quoteComment,
      WorkflowStep.quotePhotos,
      WorkflowStep.quoteSignature,
    ].contains(step);
  }

  /// Get branch name from step
  static String? getBranchName(WorkflowStep step) {
    if ([
      WorkflowStep.additionalWorkDescription,
      WorkflowStep.additionalWorkPhotos,
      WorkflowStep.additionalWorkSignature,
    ].contains(step)) {
      return 'additional_work';
    }

    if (step == WorkflowStep.deliveryNotePhotos) {
      return 'delivery_note';
    }

    if ([
      WorkflowStep.quoteComment,
      WorkflowStep.quotePhotos,
      WorkflowStep.quoteSignature,
    ].contains(step)) {
      return 'quote';
    }

    return null;
  }

  /// Get step title for display
  static String getStepTitle(WorkflowStep step) {
    switch (step) {
      case WorkflowStep.securityChecklist:
        return 'Liste de Sécurité';
      case WorkflowStep.photosBeforeIntervention:
        return 'Photos Avant Intervention';
      case WorkflowStep.photosAfterIntervention:
        return 'Photos Après Intervention';
      case WorkflowStep.qualityChecklist:
        return 'Contrôle Qualité';
      case WorkflowStep.observations:
        return 'Observations';
      case WorkflowStep.technicalObservations:
        return 'Observations Techniques';
      case WorkflowStep.additionalWorkDescription:
        return 'Travaux Supplémentaires - Description';
      case WorkflowStep.additionalWorkPhotos:
        return 'Travaux Supplémentaires - Photos';
      case WorkflowStep.additionalWorkSignature:
        return 'Travaux Supplémentaires - Signature';
      case WorkflowStep.deliveryNotePhotos:
        return 'Bon de Livraison - Photos';
      case WorkflowStep.quoteComment:
        return 'Devis - Commentaire';
      case WorkflowStep.quotePhotos:
        return 'Devis - Photos';
      case WorkflowStep.quoteSignature:
        return 'Devis - Signature';
      case WorkflowStep.technicianSignature:
        return 'Signature Technicien';
      case WorkflowStep.completed:
        return 'Intervention Terminée';
    }
  }

  /// Calculate progress percentage (0-100)
  static int calculateProgress(
    WorkflowStep currentStep,
    List<String> completedBranches,
  ) {
    final Map<WorkflowStep, int> stepToProgress = {
      WorkflowStep.securityChecklist: 0,
      WorkflowStep.photosBeforeIntervention: 12,
      WorkflowStep.photosAfterIntervention: 25,
      WorkflowStep.qualityChecklist: 37,
      WorkflowStep.observations: 50,
      WorkflowStep.technicalObservations: 62,
      WorkflowStep.technicianSignature: 87,
      WorkflowStep.completed: 100,
    };

    // Branch steps get intermediate progress values
    final Map<WorkflowStep, int> branchProgress = {
      WorkflowStep.additionalWorkDescription: 65,
      WorkflowStep.additionalWorkPhotos: 70,
      WorkflowStep.additionalWorkSignature: 75,
      WorkflowStep.deliveryNotePhotos: 70,
      WorkflowStep.quoteComment: 65,
      WorkflowStep.quotePhotos: 70,
      WorkflowStep.quoteSignature: 75,
    };

    if (stepToProgress.containsKey(currentStep)) {
      return stepToProgress[currentStep]!;
    }

    if (branchProgress.containsKey(currentStep)) {
      return branchProgress[currentStep]!;
    }

    return 0;
  }
}
