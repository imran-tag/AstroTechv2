import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/logger.dart';
import '../../../domain/entities/intervention.dart';
import '../../../domain/entities/workflow_step.dart';
import '../../../domain/repositories/intervention_repository.dart';
import '../../../domain/usecases/save_workflow.dart';
import '../../../domain/usecases/upload_photo.dart';

// Events
abstract class WorkflowEvent extends Equatable {
  const WorkflowEvent();

  @override
  List<Object?> get props => [];
}

class InitializeWorkflow extends WorkflowEvent {
  final Intervention intervention;

  const InitializeWorkflow(this.intervention);

  @override
  List<Object?> get props => [intervention];
}

class SaveSecurityChecklist extends WorkflowEvent {
  final List<bool> values;

  const SaveSecurityChecklist(this.values);

  @override
  List<Object?> get props => [values];
}

class AddPhoto extends WorkflowEvent {
  final String localPath;
  final String photoType;
  final double? latitude;
  final double? longitude;

  const AddPhoto({
    required this.localPath,
    required this.photoType,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [localPath, photoType, latitude, longitude];
}

class RemovePhoto extends WorkflowEvent {
  final int photoId;
  final String photoType;

  const RemovePhoto({required this.photoId, required this.photoType});

  @override
  List<Object?> get props => [photoId, photoType];
}

class SaveComment extends WorkflowEvent {
  final String comment;

  const SaveComment(this.comment);

  @override
  List<Object?> get props => [comment];
}

class SaveQualityControl extends WorkflowEvent {
  final List<bool> values;

  const SaveQualityControl(this.values);

  @override
  List<Object?> get props => [values];
}

class SaveSignature extends WorkflowEvent {
  final Uint8List signatureBytes;

  const SaveSignature(this.signatureBytes);

  @override
  List<Object?> get props => [signatureBytes];
}

class GoToStep extends WorkflowEvent {
  final int step;

  const GoToStep(this.step);

  @override
  List<Object?> get props => [step];
}

class NextStep extends WorkflowEvent {}

class PreviousStep extends WorkflowEvent {}

class CompleteWorkflow extends WorkflowEvent {}

// New Solitech Workflow Events
class SaveClientObservations extends WorkflowEvent {
  final String observations;

  const SaveClientObservations(this.observations);

  @override
  List<Object?> get props => [observations];
}

class SaveClientRating extends WorkflowEvent {
  final int rating;

  const SaveClientRating(this.rating);

  @override
  List<Object?> get props => [rating];
}

class SaveClientSignature extends WorkflowEvent {
  final Uint8List signatureBytes;

  const SaveClientSignature(this.signatureBytes);

  @override
  List<Object?> get props => [signatureBytes];
}

class SelectTechnicalObservation extends WorkflowEvent {
  final String choice; // 'additional_work' | 'delivery_note' | 'quote' | 'finish'

  const SelectTechnicalObservation(this.choice);

  @override
  List<Object?> get props => [choice];
}

class SaveAdditionalWorkDescription extends WorkflowEvent {
  final String description;

  const SaveAdditionalWorkDescription(this.description);

  @override
  List<Object?> get props => [description];
}

class AddPhotoWithContext extends WorkflowEvent {
  final String localPath;
  final String photoType;
  final String photoContext;
  final String? comment;
  final String? drawingData;
  final double? latitude;
  final double? longitude;

  const AddPhotoWithContext({
    required this.localPath,
    required this.photoType,
    required this.photoContext,
    this.comment,
    this.drawingData,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [localPath, photoType, photoContext, comment, drawingData, latitude, longitude];
}

class SaveAdditionalWorkSignature extends WorkflowEvent {
  final Uint8List signatureBytes;

  const SaveAdditionalWorkSignature(this.signatureBytes);

  @override
  List<Object?> get props => [signatureBytes];
}

class SaveQuoteComment extends WorkflowEvent {
  final String comment;

  const SaveQuoteComment(this.comment);

  @override
  List<Object?> get props => [comment];
}

class SaveQuoteSignature extends WorkflowEvent {
  final Uint8List signatureBytes;

  const SaveQuoteSignature(this.signatureBytes);

  @override
  List<Object?> get props => [signatureBytes];
}

class SaveTechnicianSignature extends WorkflowEvent {
  final Uint8List signatureBytes;

  const SaveTechnicianSignature(this.signatureBytes);

  @override
  List<Object?> get props => [signatureBytes];
}

class StartInterruption extends WorkflowEvent {
  final String reason;
  final String? customReason;

  const StartInterruption({required this.reason, this.customReason});

  @override
  List<Object?> get props => [reason, customReason];
}

class EndInterruption extends WorkflowEvent {
  final String interruptionId;

  const EndInterruption(this.interruptionId);

  @override
  List<Object?> get props => [interruptionId];
}

class StartTravelTime extends WorkflowEvent {}

class EndTravelTime extends WorkflowEvent {}

// States
abstract class WorkflowState extends Equatable {
  const WorkflowState();

  @override
  List<Object?> get props => [];
}

class WorkflowInitial extends WorkflowState {}

class WorkflowLoading extends WorkflowState {}

class WorkflowInProgress extends WorkflowState {
  final int interventionId;
  final WorkflowStep currentStep;
  final List<bool> securityChecklist;
  final List<InterventionPhoto> photosBefore;
  final List<InterventionPhoto> photosAfter;
  final String comment;
  final List<bool> qualityControl;
  final bool hasSignature;
  final bool isSaving;
  final String? error;

  // Solitech Workflow - Observations
  final String clientObservations;
  final int? clientRating;
  final bool hasClientSignature;

  // Solitech Workflow - Technical Observations
  final String? technicalObservationsChoice;

  // Additional Work Branch
  final String additionalWorkDescription;
  final List<InterventionPhoto> additionalWorkPhotos;
  final bool hasAdditionalWorkSignature;

  // Delivery Note Branch
  final List<InterventionPhoto> deliveryNotePhotos;

  // Quote Branch
  final String quoteComment;
  final List<InterventionPhoto> quotePhotos;
  final bool hasQuoteSignature;

  // Navigation tracking
  final List<String> completedBranches;
  final int loopCount;

  // Interruptions and travel
  final List<InterventionInterruption> interruptions;
  final DateTime? travelStartTime;

  // Technician signature
  final bool hasTechnicianSignature;

  const WorkflowInProgress({
    required this.interventionId,
    this.currentStep = WorkflowStep.securityChecklist,
    this.securityChecklist = const [false, false, false],
    this.photosBefore = const [],
    this.photosAfter = const [],
    this.comment = '',
    this.qualityControl = const [false, false, false],
    this.hasSignature = false,
    this.isSaving = false,
    this.error,
    this.clientObservations = '',
    this.clientRating,
    this.hasClientSignature = false,
    this.technicalObservationsChoice,
    this.additionalWorkDescription = '',
    this.additionalWorkPhotos = const [],
    this.hasAdditionalWorkSignature = false,
    this.deliveryNotePhotos = const [],
    this.quoteComment = '',
    this.quotePhotos = const [],
    this.hasQuoteSignature = false,
    this.completedBranches = const [],
    this.loopCount = 0,
    this.interruptions = const [],
    this.travelStartTime,
    this.hasTechnicianSignature = false,
  });

  WorkflowInProgress copyWith({
    int? interventionId,
    WorkflowStep? currentStep,
    List<bool>? securityChecklist,
    List<InterventionPhoto>? photosBefore,
    List<InterventionPhoto>? photosAfter,
    String? comment,
    List<bool>? qualityControl,
    bool? hasSignature,
    bool? isSaving,
    String? error,
    String? clientObservations,
    int? clientRating,
    bool? hasClientSignature,
    String? technicalObservationsChoice,
    String? additionalWorkDescription,
    List<InterventionPhoto>? additionalWorkPhotos,
    bool? hasAdditionalWorkSignature,
    List<InterventionPhoto>? deliveryNotePhotos,
    String? quoteComment,
    List<InterventionPhoto>? quotePhotos,
    bool? hasQuoteSignature,
    List<String>? completedBranches,
    int? loopCount,
    List<InterventionInterruption>? interruptions,
    DateTime? travelStartTime,
    bool? hasTechnicianSignature,
  }) {
    return WorkflowInProgress(
      interventionId: interventionId ?? this.interventionId,
      currentStep: currentStep ?? this.currentStep,
      securityChecklist: securityChecklist ?? this.securityChecklist,
      photosBefore: photosBefore ?? this.photosBefore,
      photosAfter: photosAfter ?? this.photosAfter,
      comment: comment ?? this.comment,
      qualityControl: qualityControl ?? this.qualityControl,
      hasSignature: hasSignature ?? this.hasSignature,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      clientObservations: clientObservations ?? this.clientObservations,
      clientRating: clientRating ?? this.clientRating,
      hasClientSignature: hasClientSignature ?? this.hasClientSignature,
      technicalObservationsChoice: technicalObservationsChoice ?? this.technicalObservationsChoice,
      additionalWorkDescription: additionalWorkDescription ?? this.additionalWorkDescription,
      additionalWorkPhotos: additionalWorkPhotos ?? this.additionalWorkPhotos,
      hasAdditionalWorkSignature: hasAdditionalWorkSignature ?? this.hasAdditionalWorkSignature,
      deliveryNotePhotos: deliveryNotePhotos ?? this.deliveryNotePhotos,
      quoteComment: quoteComment ?? this.quoteComment,
      quotePhotos: quotePhotos ?? this.quotePhotos,
      hasQuoteSignature: hasQuoteSignature ?? this.hasQuoteSignature,
      completedBranches: completedBranches ?? this.completedBranches,
      loopCount: loopCount ?? this.loopCount,
      interruptions: interruptions ?? this.interruptions,
      travelStartTime: travelStartTime ?? this.travelStartTime,
      hasTechnicianSignature: hasTechnicianSignature ?? this.hasTechnicianSignature,
    );
  }

  // Legacy validation (kept for backwards compatibility)
  bool get isStep1Complete => securityChecklist.every((v) => v);
  bool get isStep2Complete => photosBefore.length >= 2; // Solitech requires minimum 2
  bool get isStep3Complete => photosAfter.isNotEmpty;
  bool get isStep4Complete => comment.trim().isNotEmpty;
  bool get isStep5Complete => qualityControl.every((v) => v);
  bool get isStep6Complete => hasSignature;

  // Solitech workflow validation
  bool get isSecurityChecklistComplete => securityChecklist.every((v) => v);
  bool get isPhotosBeforeComplete => photosBefore.length >= 2;
  bool get isPhotosAfterComplete => photosAfter.isNotEmpty;
  bool get isQualityChecklistComplete => qualityControl.every((v) => v);
  bool get isObservationsComplete =>
      clientObservations.trim().isNotEmpty &&
      clientRating != null &&
      hasClientSignature;
  bool get isTechnicalObservationsComplete => technicalObservationsChoice != null;
  bool get isAdditionalWorkDescriptionComplete => additionalWorkDescription.trim().isNotEmpty;
  bool get isAdditionalWorkPhotosComplete => additionalWorkPhotos.isNotEmpty;
  bool get isAdditionalWorkSignatureComplete => hasAdditionalWorkSignature;
  bool get isDeliveryNotePhotosComplete => deliveryNotePhotos.isNotEmpty;
  bool get isQuoteCommentComplete => quoteComment.trim().isNotEmpty;
  bool get isQuotePhotosComplete => quotePhotos.isNotEmpty;
  bool get isQuoteSignatureComplete => hasQuoteSignature;
  bool get isTechnicianSignatureComplete => hasTechnicianSignature;

  bool canProceedFromCurrentStep() {
    switch (currentStep) {
      case WorkflowStep.securityChecklist:
        return isSecurityChecklistComplete;
      case WorkflowStep.photosBeforeIntervention:
        return isPhotosBeforeComplete;
      case WorkflowStep.photosAfterIntervention:
        return isPhotosAfterComplete;
      case WorkflowStep.qualityChecklist:
        return isQualityChecklistComplete;
      case WorkflowStep.observations:
        return isObservationsComplete;
      case WorkflowStep.technicalObservations:
        return isTechnicalObservationsComplete;
      case WorkflowStep.additionalWorkDescription:
        return isAdditionalWorkDescriptionComplete;
      case WorkflowStep.additionalWorkPhotos:
        return isAdditionalWorkPhotosComplete;
      case WorkflowStep.additionalWorkSignature:
        return isAdditionalWorkSignatureComplete;
      case WorkflowStep.deliveryNotePhotos:
        return isDeliveryNotePhotosComplete;
      case WorkflowStep.quoteComment:
        return isQuoteCommentComplete;
      case WorkflowStep.quotePhotos:
        return isQuotePhotosComplete;
      case WorkflowStep.quoteSignature:
        return isQuoteSignatureComplete;
      case WorkflowStep.technicianSignature:
        return isTechnicianSignatureComplete;
      case WorkflowStep.completed:
        return true;
    }
  }

  @override
  List<Object?> get props => [
        interventionId,
        currentStep,
        securityChecklist,
        photosBefore,
        photosAfter,
        comment,
        qualityControl,
        hasSignature,
        isSaving,
        error,
        clientObservations,
        clientRating,
        hasClientSignature,
        technicalObservationsChoice,
        additionalWorkDescription,
        additionalWorkPhotos,
        hasAdditionalWorkSignature,
        deliveryNotePhotos,
        quoteComment,
        quotePhotos,
        hasQuoteSignature,
        completedBranches,
        loopCount,
        interruptions,
        travelStartTime,
        hasTechnicianSignature,
      ];
}

class WorkflowCompleted extends WorkflowState {
  final int interventionId;
  final WorkflowInProgress completedWorkflow;
  final DateTime completedAt;

  const WorkflowCompleted(this.interventionId, this.completedWorkflow, this.completedAt);

  @override
  List<Object?> get props => [interventionId, completedWorkflow, completedAt];
}

class WorkflowError extends WorkflowState {
  final String message;

  const WorkflowError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class WorkflowBloc extends Bloc<WorkflowEvent, WorkflowState> {
  final SaveWorkflow saveWorkflow;
  final UploadPhoto uploadPhoto;
  final InterventionRepository interventionRepository;

  WorkflowBloc({
    required this.saveWorkflow,
    required this.uploadPhoto,
    required this.interventionRepository,
  }) : super(WorkflowInitial()) {
    on<InitializeWorkflow>(_onInitializeWorkflow);
    on<SaveSecurityChecklist>(_onSaveSecurityChecklist);
    on<AddPhoto>(_onAddPhoto);
    on<RemovePhoto>(_onRemovePhoto);
    on<SaveComment>(_onSaveComment);
    on<SaveQualityControl>(_onSaveQualityControl);
    on<SaveSignature>(_onSaveSignature);
    on<GoToStep>(_onGoToStep);
    on<NextStep>(_onNextStep);
    on<PreviousStep>(_onPreviousStep);
    on<CompleteWorkflow>(_onCompleteWorkflow);

    // Solitech workflow events
    on<SaveClientObservations>(_onSaveClientObservations);
    on<SaveClientRating>(_onSaveClientRating);
    on<SaveClientSignature>(_onSaveClientSignature);
    on<SelectTechnicalObservation>(_onSelectTechnicalObservation);
    on<SaveAdditionalWorkDescription>(_onSaveAdditionalWorkDescription);
    on<AddPhotoWithContext>(_onAddPhotoWithContext);
    on<SaveAdditionalWorkSignature>(_onSaveAdditionalWorkSignature);
    on<SaveQuoteComment>(_onSaveQuoteComment);
    on<SaveQuoteSignature>(_onSaveQuoteSignature);
    on<SaveTechnicianSignature>(_onSaveTechnicianSignature);
    on<StartInterruption>(_onStartInterruption);
    on<EndInterruption>(_onEndInterruption);
    on<StartTravelTime>(_onStartTravelTime);
    on<EndTravelTime>(_onEndTravelTime);
  }

  void _onInitializeWorkflow(
    InitializeWorkflow event,
    Emitter<WorkflowState> emit,
  ) {
    final intervention = event.intervention;
    final workflow = intervention.workflow;

    // Determine current step from workflow data
    WorkflowStep currentStep = WorkflowStep.securityChecklist;
    if (workflow != null) {
      // Map legacy int step to new WorkflowStep enum
      // This provides backwards compatibility
      currentStep = _mapLegacyStepToWorkflowStep(workflow.currentStep);
    }

    emit(WorkflowInProgress(
      interventionId: intervention.id,
      currentStep: currentStep,
      securityChecklist: workflow?.securityChecklistValues ?? [false, false, false],
      photosBefore: intervention.photos?.before.where((p) => p.photoContext == 'before').toList() ?? [],
      photosAfter: intervention.photos?.after.where((p) => p.photoContext == 'after').toList() ?? [],
      comment: workflow?.comment ?? '',
      qualityControl: workflow?.qualityControlValues ?? [false, false, false],
      hasSignature: workflow?.signaturePath != null,
      clientObservations: workflow?.clientObservations ?? '',
      clientRating: workflow?.clientRating,
      hasClientSignature: workflow?.clientSignaturePath != null,
      technicalObservationsChoice: workflow?.technicalObservationsChoice,
      additionalWorkDescription: workflow?.additionalWorkDescription ?? '',
      additionalWorkPhotos: intervention.photos?.before.where((p) => p.photoContext == 'additional_work').toList() ?? [],
      hasAdditionalWorkSignature: workflow?.additionalWorkSignaturePath != null,
      deliveryNotePhotos: intervention.photos?.before.where((p) => p.photoContext == 'delivery_note').toList() ?? [],
      quoteComment: workflow?.quoteComment ?? '',
      quotePhotos: intervention.photos?.before.where((p) => p.photoContext == 'quote').toList() ?? [],
      hasQuoteSignature: workflow?.quoteSignaturePath != null,
      completedBranches: workflow?.completedBranches ?? [],
      loopCount: workflow?.loopCount ?? 0,
      interruptions: intervention.interruptions ?? [],
      travelStartTime: workflow?.travelStartTime,
      hasTechnicianSignature: workflow?.technicianSignaturePath != null,
    ));
  }

  WorkflowStep _mapLegacyStepToWorkflowStep(int step) {
    switch (step) {
      case 1:
        return WorkflowStep.securityChecklist;
      case 2:
        return WorkflowStep.photosBeforeIntervention;
      case 3:
        return WorkflowStep.photosAfterIntervention;
      case 4:
        return WorkflowStep.observations;
      case 5:
        return WorkflowStep.qualityChecklist;
      case 6:
        return WorkflowStep.technicianSignature;
      default:
        return WorkflowStep.securityChecklist;
    }
  }

  Future<void> _onSaveSecurityChecklist(
    SaveSecurityChecklist event,
    Emitter<WorkflowState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkflowInProgress) return;

    emit(currentState.copyWith(isSaving: true));

    try {
      final checklistString = event.values.map((v) => v ? '1' : '0').join(';');

      await saveWorkflow(currentState.interventionId, {
        'security_checklist': checklistString,
        'current_step': currentState.currentStep,
      });

      emit(currentState.copyWith(
        securityChecklist: event.values,
        isSaving: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        securityChecklist: event.values, // Still update locally
        isSaving: false,
        error: 'Sauvegardé localement',
      ));
    }
  }

  Future<void> _onAddPhoto(
    AddPhoto event,
    Emitter<WorkflowState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkflowInProgress) return;

    emit(currentState.copyWith(isSaving: true));

    try {
      final photo = await uploadPhoto(
        interventionId: currentState.interventionId,
        localPath: event.localPath,
        photoType: event.photoType,
        latitude: event.latitude,
        longitude: event.longitude,
      );

      if (event.photoType == 'before') {
        emit(currentState.copyWith(
          photosBefore: [...currentState.photosBefore, photo],
          isSaving: false,
        ));
      } else {
        emit(currentState.copyWith(
          photosAfter: [...currentState.photosAfter, photo],
          isSaving: false,
        ));
      }
    } catch (e) {
      emit(currentState.copyWith(
        isSaving: false,
        error: 'Erreur lors de l\'upload: ${e.toString()}',
      ));
    }
  }

  Future<void> _onRemovePhoto(
    RemovePhoto event,
    Emitter<WorkflowState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkflowInProgress) return;

    emit(currentState.copyWith(isSaving: true));

    try {
      await interventionRepository.deletePhoto(
        currentState.interventionId,
        event.photoId,
      );

      if (event.photoType == 'before') {
        emit(currentState.copyWith(
          photosBefore: currentState.photosBefore
              .where((p) => p.id != event.photoId)
              .toList(),
          isSaving: false,
        ));
      } else {
        emit(currentState.copyWith(
          photosAfter: currentState.photosAfter
              .where((p) => p.id != event.photoId)
              .toList(),
          isSaving: false,
        ));
      }
    } catch (e) {
      emit(currentState.copyWith(
        isSaving: false,
        error: 'Erreur lors de la suppression',
      ));
    }
  }

  Future<void> _onSaveComment(
    SaveComment event,
    Emitter<WorkflowState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkflowInProgress) return;

    emit(currentState.copyWith(isSaving: true));

    try {
      await saveWorkflow(currentState.interventionId, {
        'comment': event.comment,
        'current_step': currentState.currentStep,
      });

      emit(currentState.copyWith(
        comment: event.comment,
        isSaving: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        comment: event.comment,
        isSaving: false,
        error: 'Sauvegardé localement',
      ));
    }
  }

  Future<void> _onSaveQualityControl(
    SaveQualityControl event,
    Emitter<WorkflowState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkflowInProgress) return;

    emit(currentState.copyWith(isSaving: true));

    try {
      final qcString = event.values.map((v) => v ? '1' : '0').join(';');

      await saveWorkflow(currentState.interventionId, {
        'quality_control': qcString,
        'current_step': currentState.currentStep,
      });

      emit(currentState.copyWith(
        qualityControl: event.values,
        isSaving: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        qualityControl: event.values,
        isSaving: false,
        error: 'Sauvegardé localement',
      ));
    }
  }

  Future<void> _onSaveSignature(
    SaveSignature event,
    Emitter<WorkflowState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkflowInProgress) return;

    emit(currentState.copyWith(isSaving: true));

    try {
      final base64Signature = 'data:image/png;base64,${base64Encode(event.signatureBytes)}';

      await interventionRepository.uploadSignature(
        currentState.interventionId,
        base64Signature,
      );

      emit(currentState.copyWith(
        hasSignature: true,
        isSaving: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        hasSignature: true, // Mark as complete anyway (saved locally)
        isSaving: false,
        error: 'Signature sauvegardée localement',
      ));
    }
  }

  void _onGoToStep(
    GoToStep event,
    Emitter<WorkflowState> emit,
  ) {
    final currentState = state;
    if (currentState is! WorkflowInProgress) return;

    // Map legacy int step to WorkflowStep
    final step = _mapLegacyStepToWorkflowStep(event.step);
    emit(currentState.copyWith(currentStep: step, error: null));
  }

  Future<void> _onNextStep(
    NextStep event,
    Emitter<WorkflowState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkflowInProgress) return;

    if (!currentState.canProceedFromCurrentStep()) {
      emit(currentState.copyWith(
        error: 'Veuillez compléter cette étape avant de continuer',
      ));
      return;
    }

    final nextStep = WorkflowNavigation.getNextStep(
      currentState.currentStep,
      currentState.technicalObservationsChoice,
    );

    if (nextStep == null) {
      emit(currentState.copyWith(
        error: 'Impossible de continuer',
      ));
      return;
    }

    // Check if we're looping back to technical observations
    List<String> updatedBranches = currentState.completedBranches;
    int updatedLoopCount = currentState.loopCount;

    if (nextStep == WorkflowStep.technicalObservations &&
        currentState.currentStep != WorkflowStep.observations) {
      // We're looping back from a branch
      final branchName = WorkflowNavigation.getBranchName(currentState.currentStep);
      if (branchName != null && !updatedBranches.contains(branchName)) {
        updatedBranches = [...updatedBranches, branchName];
      }
      updatedLoopCount++;
    }

    // Save current step to backend
    try {
      await saveWorkflow(currentState.interventionId, {
        'current_step': _mapWorkflowStepToLegacyInt(nextStep),
        'completed_branches': updatedBranches,
        'loop_count': updatedLoopCount,
      });
    } catch (e) {
      // Continue anyway, will sync later
    }

    emit(currentState.copyWith(
      currentStep: nextStep,
      completedBranches: updatedBranches,
      loopCount: updatedLoopCount,
      error: null,
    ));

    // Auto-complete workflow if we reached the completed step
    if (nextStep == WorkflowStep.completed) {
      add(CompleteWorkflow());
    }
  }

  void _onPreviousStep(
    PreviousStep event,
    Emitter<WorkflowState> emit,
  ) {
    final currentState = state;
    if (currentState is! WorkflowInProgress) return;

    final prevStep = WorkflowNavigation.getPreviousStep(
      currentState.currentStep,
      currentState.completedBranches,
    );

    if (prevStep != null) {
      emit(currentState.copyWith(currentStep: prevStep, error: null));
    }
  }

  int _mapWorkflowStepToLegacyInt(WorkflowStep step) {
    // Map to legacy integer steps for backend compatibility
    switch (step) {
      case WorkflowStep.securityChecklist:
        return 1;
      case WorkflowStep.photosBeforeIntervention:
        return 2;
      case WorkflowStep.photosAfterIntervention:
        return 3;
      case WorkflowStep.qualityChecklist:
        return 5;
      case WorkflowStep.observations:
        return 4;
      case WorkflowStep.technicalObservations:
      case WorkflowStep.technicianSignature:
        return 6;
      default:
        return 1;
    }
  }

  Future<void> _onCompleteWorkflow(
    CompleteWorkflow event,
    Emitter<WorkflowState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkflowInProgress) return;

    if (!currentState.hasTechnicianSignature) {
      emit(currentState.copyWith(error: 'Signature du technicien requise'));
      return;
    }

    emit(currentState.copyWith(isSaving: true));

    try {
      // Update intervention status to completed
      await interventionRepository.updateStatus(
        currentState.interventionId,
        'terminee',
      );

      emit(WorkflowCompleted(currentState.interventionId, currentState, DateTime.now()));
    } catch (e) {
      emit(currentState.copyWith(
        isSaving: false,
        error: 'Erreur lors de la finalisation',
      ));
    }
  }

  // Solitech Workflow Event Handlers

  Future<void> _onSaveClientObservations(
    SaveClientObservations event,
    Emitter<WorkflowState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkflowInProgress) return;

    emit(currentState.copyWith(isSaving: true));

    try {
      await saveWorkflow(currentState.interventionId, {
        'client_observations': event.observations,
      });

      emit(currentState.copyWith(
        clientObservations: event.observations,
        isSaving: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        clientObservations: event.observations,
        isSaving: false,
        error: 'Sauvegardé localement',
      ));
    }
  }

  Future<void> _onSaveClientRating(
    SaveClientRating event,
    Emitter<WorkflowState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkflowInProgress) return;

    emit(currentState.copyWith(isSaving: true));

    try {
      await saveWorkflow(currentState.interventionId, {
        'client_rating': event.rating,
      });

      emit(currentState.copyWith(
        clientRating: event.rating,
        isSaving: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        clientRating: event.rating,
        isSaving: false,
        error: 'Sauvegardé localement',
      ));
    }
  }

  Future<void> _onSaveClientSignature(
    SaveClientSignature event,
    Emitter<WorkflowState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkflowInProgress) return;

    emit(currentState.copyWith(isSaving: true));

    try {
      final base64Signature = 'data:image/png;base64,${base64Encode(event.signatureBytes)}';

      await interventionRepository.uploadTypedSignature(
        currentState.interventionId,
        'client',
        base64Signature,
      );

      emit(currentState.copyWith(
        hasClientSignature: true,
        isSaving: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        hasClientSignature: true,
        isSaving: false,
        error: 'Signature sauvegardée localement',
      ));
    }
  }

  Future<void> _onSelectTechnicalObservation(
    SelectTechnicalObservation event,
    Emitter<WorkflowState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkflowInProgress) return;

    emit(currentState.copyWith(isSaving: true));

    try {
      await saveWorkflow(currentState.interventionId, {
        'technical_observations_choice': event.choice,
      });

      emit(currentState.copyWith(
        technicalObservationsChoice: event.choice,
        isSaving: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        technicalObservationsChoice: event.choice,
        isSaving: false,
        error: 'Sauvegardé localement',
      ));
    }
  }

  Future<void> _onSaveAdditionalWorkDescription(
    SaveAdditionalWorkDescription event,
    Emitter<WorkflowState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkflowInProgress) return;

    emit(currentState.copyWith(isSaving: true));

    try {
      await saveWorkflow(currentState.interventionId, {
        'additional_work_description': event.description,
      });

      emit(currentState.copyWith(
        additionalWorkDescription: event.description,
        isSaving: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        additionalWorkDescription: event.description,
        isSaving: false,
        error: 'Sauvegardé localement',
      ));
    }
  }

  Future<void> _onAddPhotoWithContext(
    AddPhotoWithContext event,
    Emitter<WorkflowState> emit,
  ) async {
    Logger.workflow('AddPhotoWithContext event received');
    Logger.workflow('   - localPath: ${event.localPath}');
    Logger.workflow('   - photoType: ${event.photoType}');
    Logger.workflow('   - photoContext: ${event.photoContext}');

    final currentState = state;
    if (currentState is! WorkflowInProgress) {
      Logger.error('Current state is not WorkflowInProgress', null, null, 'WORKFLOW');
      return;
    }

    Logger.workflow('Setting state to saving...');
    emit(currentState.copyWith(isSaving: true));

    try {
      Logger.workflow('Calling uploadPhoto use case...');
      final photo = await uploadPhoto(
        interventionId: currentState.interventionId,
        localPath: event.localPath,
        photoType: event.photoType,
        latitude: event.latitude,
        longitude: event.longitude,
        comment: event.comment,
        drawingData: event.drawingData,
        photoContext: event.photoContext,
      );

      Logger.info('Photo uploaded successfully, ID: ${photo.id}', 'WORKFLOW');
      Logger.workflow('   - localPath: ${photo.localPath}');
      Logger.workflow('   - photoType: ${photo.photoType}');

      // Add photo to appropriate list based on context
      List<InterventionPhoto> updatedPhotos;
      switch (event.photoContext) {
        case 'before':
          updatedPhotos = [...currentState.photosBefore, photo];
          Logger.info('Added to photosBefore list, new count: ${updatedPhotos.length}', 'WORKFLOW');
          emit(currentState.copyWith(
            photosBefore: updatedPhotos,
            isSaving: false,
          ));
          break;
        case 'after':
          updatedPhotos = [...currentState.photosAfter, photo];
          Logger.info('Added to photosAfter list, new count: ${updatedPhotos.length}', 'WORKFLOW');
          emit(currentState.copyWith(
            photosAfter: updatedPhotos,
            isSaving: false,
          ));
          break;
        case 'additional_work':
          updatedPhotos = [...currentState.additionalWorkPhotos, photo];
          Logger.info('Added to additionalWorkPhotos list, new count: ${updatedPhotos.length}', 'WORKFLOW');
          emit(currentState.copyWith(
            additionalWorkPhotos: updatedPhotos,
            isSaving: false,
          ));
          break;
        case 'delivery_note':
          updatedPhotos = [...currentState.deliveryNotePhotos, photo];
          Logger.info('Added to deliveryNotePhotos list, new count: ${updatedPhotos.length}', 'WORKFLOW');
          emit(currentState.copyWith(
            deliveryNotePhotos: updatedPhotos,
            isSaving: false,
          ));
          break;
        case 'quote':
          updatedPhotos = [...currentState.quotePhotos, photo];
          Logger.info('Added to quotePhotos list, new count: ${updatedPhotos.length}', 'WORKFLOW');
          emit(currentState.copyWith(
            quotePhotos: updatedPhotos,
            isSaving: false,
          ));
          break;
        default:
          Logger.warning('Unknown photo context: ${event.photoContext}', 'WORKFLOW');
          emit(currentState.copyWith(isSaving: false));
      }
    } catch (e, stackTrace) {
      Logger.error('Error uploading photo: $e', e, stackTrace, 'WORKFLOW');
      emit(currentState.copyWith(
        isSaving: false,
        error: 'Erreur lors de l\'upload: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSaveAdditionalWorkSignature(
    SaveAdditionalWorkSignature event,
    Emitter<WorkflowState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkflowInProgress) return;

    emit(currentState.copyWith(isSaving: true));

    try {
      final base64Signature = 'data:image/png;base64,${base64Encode(event.signatureBytes)}';

      await interventionRepository.uploadTypedSignature(
        currentState.interventionId,
        'additional_work',
        base64Signature,
      );

      emit(currentState.copyWith(
        hasAdditionalWorkSignature: true,
        isSaving: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        hasAdditionalWorkSignature: true,
        isSaving: false,
        error: 'Signature sauvegardée localement',
      ));
    }
  }

  Future<void> _onSaveQuoteComment(
    SaveQuoteComment event,
    Emitter<WorkflowState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkflowInProgress) return;

    emit(currentState.copyWith(isSaving: true));

    try {
      await saveWorkflow(currentState.interventionId, {
        'quote_comment': event.comment,
      });

      emit(currentState.copyWith(
        quoteComment: event.comment,
        isSaving: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        quoteComment: event.comment,
        isSaving: false,
        error: 'Sauvegardé localement',
      ));
    }
  }

  Future<void> _onSaveQuoteSignature(
    SaveQuoteSignature event,
    Emitter<WorkflowState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkflowInProgress) return;

    emit(currentState.copyWith(isSaving: true));

    try {
      final base64Signature = 'data:image/png;base64,${base64Encode(event.signatureBytes)}';

      await interventionRepository.uploadTypedSignature(
        currentState.interventionId,
        'quote',
        base64Signature,
      );

      emit(currentState.copyWith(
        hasQuoteSignature: true,
        isSaving: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        hasQuoteSignature: true,
        isSaving: false,
        error: 'Signature sauvegardée localement',
      ));
    }
  }

  Future<void> _onSaveTechnicianSignature(
    SaveTechnicianSignature event,
    Emitter<WorkflowState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkflowInProgress) return;

    emit(currentState.copyWith(isSaving: true));

    try {
      final base64Signature = 'data:image/png;base64,${base64Encode(event.signatureBytes)}';

      await interventionRepository.uploadTypedSignature(
        currentState.interventionId,
        'technician',
        base64Signature,
      );

      emit(currentState.copyWith(
        hasTechnicianSignature: true,
        isSaving: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        hasTechnicianSignature: true,
        isSaving: false,
        error: 'Signature sauvegardée localement',
      ));
    }
  }

  Future<void> _onStartInterruption(
    StartInterruption event,
    Emitter<WorkflowState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkflowInProgress) return;

    emit(currentState.copyWith(isSaving: true));

    try {
      final interruption = InterventionInterruption(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        interventionId: currentState.interventionId,
        reason: event.reason,
        customReason: event.customReason,
        startedAt: DateTime.now(),
        localId: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      await interventionRepository.saveInterruption(interruption);

      emit(currentState.copyWith(
        interruptions: [...currentState.interruptions, interruption],
        isSaving: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        isSaving: false,
        error: 'Erreur lors de l\'enregistrement',
      ));
    }
  }

  Future<void> _onEndInterruption(
    EndInterruption event,
    Emitter<WorkflowState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkflowInProgress) return;

    emit(currentState.copyWith(isSaving: true));

    try {
      final interruptions = currentState.interruptions;
      final index = interruptions.indexWhere((i) => i.id == event.interruptionId);

      if (index != -1) {
        final endTime = DateTime.now();
        final duration = endTime.difference(interruptions[index].startedAt).inMinutes;

        final updatedInterruption = InterventionInterruption(
          id: interruptions[index].id,
          interventionId: interruptions[index].interventionId,
          reason: interruptions[index].reason,
          customReason: interruptions[index].customReason,
          startedAt: interruptions[index].startedAt,
          endedAt: endTime,
          durationMinutes: duration,
          localId: interruptions[index].localId,
        );

        await interventionRepository.updateInterruption(updatedInterruption);

        final updatedInterruptions = [...interruptions];
        updatedInterruptions[index] = updatedInterruption;

        emit(currentState.copyWith(
          interruptions: updatedInterruptions,
          isSaving: false,
        ));
      }
    } catch (e) {
      emit(currentState.copyWith(
        isSaving: false,
        error: 'Erreur lors de la mise à jour',
      ));
    }
  }

  Future<void> _onStartTravelTime(
    StartTravelTime event,
    Emitter<WorkflowState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkflowInProgress) return;

    emit(currentState.copyWith(isSaving: true));

    try {
      final startTime = DateTime.now();

      await saveWorkflow(currentState.interventionId, {
        'travel_start_time': startTime.toIso8601String(),
      });

      emit(currentState.copyWith(
        travelStartTime: startTime,
        isSaving: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        travelStartTime: DateTime.now(),
        isSaving: false,
        error: 'Sauvegardé localement',
      ));
    }
  }

  Future<void> _onEndTravelTime(
    EndTravelTime event,
    Emitter<WorkflowState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkflowInProgress) return;

    if (currentState.travelStartTime == null) {
      emit(currentState.copyWith(
        error: 'Aucun trajet en cours',
      ));
      return;
    }

    emit(currentState.copyWith(isSaving: true));

    try {
      final endTime = DateTime.now();
      final duration = endTime.difference(currentState.travelStartTime!).inMinutes;

      await saveWorkflow(currentState.interventionId, {
        'travel_end_time': endTime.toIso8601String(),
        'travel_duration_minutes': duration,
      });

      emit(currentState.copyWith(
        travelStartTime: null, // Clear after saving
        isSaving: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        isSaving: false,
        error: 'Erreur lors de la sauvegarde',
      ));
    }
  }
}
