import 'package:flutter_test/flutter_test.dart';
import 'package:astrotech_mobile/domain/entities/workflow_step.dart';

void main() {
  group('WorkflowNavigation Tests', () {
    test('getNextStep should follow main linear flow', () {
      expect(
        WorkflowNavigation.getNextStep(WorkflowStep.securityChecklist, null),
        WorkflowStep.photosBeforeIntervention,
      );

      expect(
        WorkflowNavigation.getNextStep(
          WorkflowStep.photosBeforeIntervention,
          null,
        ),
        WorkflowStep.photosAfterIntervention,
      );

      expect(
        WorkflowNavigation.getNextStep(
          WorkflowStep.photosAfterIntervention,
          null,
        ),
        WorkflowStep.qualityChecklist,
      );

      expect(
        WorkflowNavigation.getNextStep(WorkflowStep.qualityChecklist, null),
        WorkflowStep.observations,
      );

      expect(
        WorkflowNavigation.getNextStep(WorkflowStep.observations, null),
        WorkflowStep.technicalObservations,
      );
    });

    test('getNextStep should handle technical observations branching', () {
      expect(
        WorkflowNavigation.getNextStep(
          WorkflowStep.technicalObservations,
          'additional_work',
        ),
        WorkflowStep.additionalWorkDescription,
      );

      expect(
        WorkflowNavigation.getNextStep(
          WorkflowStep.technicalObservations,
          'delivery_note',
        ),
        WorkflowStep.deliveryNotePhotos,
      );

      expect(
        WorkflowNavigation.getNextStep(
          WorkflowStep.technicalObservations,
          'quote',
        ),
        WorkflowStep.quoteComment,
      );

      expect(
        WorkflowNavigation.getNextStep(
          WorkflowStep.technicalObservations,
          'finish',
        ),
        WorkflowStep.technicianSignature,
      );
    });

    test('getNextStep should loop branches back to technical observations', () {
      expect(
        WorkflowNavigation.getNextStep(
          WorkflowStep.additionalWorkSignature,
          null,
        ),
        WorkflowStep.technicalObservations,
      );

      expect(
        WorkflowNavigation.getNextStep(
          WorkflowStep.deliveryNotePhotos,
          null,
        ),
        WorkflowStep.technicalObservations,
      );

      expect(
        WorkflowNavigation.getNextStep(WorkflowStep.quoteSignature, null),
        WorkflowStep.technicalObservations,
      );
    });

    test('getNextStep should complete workflow', () {
      expect(
        WorkflowNavigation.getNextStep(WorkflowStep.technicianSignature, null),
        WorkflowStep.completed,
      );

      expect(
        WorkflowNavigation.getNextStep(WorkflowStep.completed, null),
        null,
      );
    });

    test('getPreviousStep should navigate backwards correctly', () {
      expect(
        WorkflowNavigation.getPreviousStep(
          WorkflowStep.photosBeforeIntervention,
          [],
        ),
        WorkflowStep.securityChecklist,
      );

      expect(
        WorkflowNavigation.getPreviousStep(
          WorkflowStep.qualityChecklist,
          [],
        ),
        WorkflowStep.photosAfterIntervention,
      );
    });

    test('isBranchStep should identify branch steps correctly', () {
      expect(
        WorkflowNavigation.isBranchStep(WorkflowStep.additionalWorkDescription),
        true,
      );
      expect(
        WorkflowNavigation.isBranchStep(WorkflowStep.deliveryNotePhotos),
        true,
      );
      expect(
        WorkflowNavigation.isBranchStep(WorkflowStep.quoteComment),
        true,
      );
      expect(
        WorkflowNavigation.isBranchStep(WorkflowStep.securityChecklist),
        false,
      );
      expect(
        WorkflowNavigation.isBranchStep(WorkflowStep.qualityChecklist),
        false,
      );
    });

    test('getBranchName should return correct branch names', () {
      expect(
        WorkflowNavigation.getBranchName(WorkflowStep.additionalWorkDescription),
        'additional_work',
      );
      expect(
        WorkflowNavigation.getBranchName(WorkflowStep.additionalWorkPhotos),
        'additional_work',
      );
      expect(
        WorkflowNavigation.getBranchName(WorkflowStep.deliveryNotePhotos),
        'delivery_note',
      );
      expect(
        WorkflowNavigation.getBranchName(WorkflowStep.quoteComment),
        'quote',
      );
      expect(
        WorkflowNavigation.getBranchName(WorkflowStep.securityChecklist),
        null,
      );
    });

    test('getStepTitle should return correct French titles', () {
      expect(
        WorkflowNavigation.getStepTitle(WorkflowStep.securityChecklist),
        'Liste de Sécurité',
      );
      expect(
        WorkflowNavigation.getStepTitle(WorkflowStep.photosBeforeIntervention),
        'Photos Avant Intervention',
      );
      expect(
        WorkflowNavigation.getStepTitle(WorkflowStep.qualityChecklist),
        'Contrôle Qualité',
      );
      expect(
        WorkflowNavigation.getStepTitle(WorkflowStep.observations),
        'Observations',
      );
      expect(
        WorkflowNavigation.getStepTitle(WorkflowStep.technicianSignature),
        'Signature Technicien',
      );
    });

    test('calculateProgress should return correct percentages', () {
      expect(
        WorkflowNavigation.calculateProgress(
          WorkflowStep.securityChecklist,
          [],
        ),
        0,
      );

      expect(
        WorkflowNavigation.calculateProgress(
          WorkflowStep.photosBeforeIntervention,
          [],
        ),
        12,
      );

      expect(
        WorkflowNavigation.calculateProgress(
          WorkflowStep.qualityChecklist,
          [],
        ),
        37,
      );

      expect(
        WorkflowNavigation.calculateProgress(
          WorkflowStep.technicianSignature,
          [],
        ),
        87,
      );

      expect(
        WorkflowNavigation.calculateProgress(
          WorkflowStep.completed,
          [],
        ),
        100,
      );
    });

    test('calculateProgress should handle branch steps', () {
      final additionalWorkProgress = WorkflowNavigation.calculateProgress(
        WorkflowStep.additionalWorkDescription,
        [],
      );
      expect(additionalWorkProgress, greaterThan(0));
      expect(additionalWorkProgress, lessThan(100));

      final quoteProgress = WorkflowNavigation.calculateProgress(
        WorkflowStep.quoteComment,
        [],
      );
      expect(quoteProgress, greaterThan(0));
      expect(quoteProgress, lessThan(100));
    });
  });
}
