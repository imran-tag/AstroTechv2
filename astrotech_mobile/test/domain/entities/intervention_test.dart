import 'package:flutter_test/flutter_test.dart';
import 'package:astrotech_mobile/domain/entities/intervention.dart';

void main() {
  group('Intervention Entity Tests', () {
    test('should create intervention with required fields', () {
      final intervention = Intervention(
        id: 1,
        numero: 1001,
        titre: 'Test Intervention',
        type: 'Maintenance',
        etat: 'planifie',
      );

      expect(intervention.id, 1);
      expect(intervention.numero, 1001);
      expect(intervention.titre, 'Test Intervention');
      expect(intervention.type, 'Maintenance');
      expect(intervention.etat, 'planifie');
    });

    test('statusLabel should return correct French labels', () {
      final planifie = Intervention(
        id: 1,
        numero: 1001,
        titre: 'Test',
        type: 'Maintenance',
        etat: 'planifie',
      );
      expect(planifie.statusLabel, 'Planifiée');

      final enCours = Intervention(
        id: 2,
        numero: 1002,
        titre: 'Test',
        type: 'Maintenance',
        etat: 'en_cours',
      );
      expect(enCours.statusLabel, 'En cours');

      final termine = Intervention(
        id: 3,
        numero: 1003,
        titre: 'Test',
        type: 'Maintenance',
        etat: 'termine',
      );
      expect(termine.statusLabel, 'Terminée');

      final nonValidee = Intervention(
        id: 4,
        numero: 1004,
        titre: 'Test',
        type: 'Maintenance',
        etat: 'non_validee',
      );
      expect(nonValidee.statusLabel, 'Non validée');
    });

    test('priorityLabel should return correct labels', () {
      final urgent = Intervention(
        id: 1,
        numero: 1001,
        titre: 'Test',
        type: 'Maintenance',
        priorite: 'urgent',
      );
      expect(urgent.priorityLabel, 'Urgent');

      final haute = Intervention(
        id: 2,
        numero: 1002,
        titre: 'Test',
        type: 'Maintenance',
        priorite: 'haute',
      );
      expect(haute.priorityLabel, 'Haute');

      final normale = Intervention(
        id: 3,
        numero: 1003,
        titre: 'Test',
        type: 'Maintenance',
        priorite: 'normale',
      );
      expect(normale.priorityLabel, 'Normale');

      final basse = Intervention(
        id: 4,
        numero: 1004,
        titre: 'Test',
        type: 'Maintenance',
        priorite: 'basse',
      );
      expect(basse.priorityLabel, 'Basse');
    });

    test('isStarted should return true when workflow is started', () {
      final workflow = InterventionWorkflow(
        interventionId: 1,
        startedAt: DateTime.now(),
      );

      final intervention = Intervention(
        id: 1,
        numero: 1001,
        titre: 'Test',
        type: 'Maintenance',
        workflow: workflow,
      );

      expect(intervention.isStarted, true);
    });

    test('isCompleted should return true when workflow is completed', () {
      final workflow = InterventionWorkflow(
        interventionId: 1,
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      final intervention = Intervention(
        id: 1,
        numero: 1001,
        titre: 'Test',
        type: 'Maintenance',
        workflow: workflow,
      );

      expect(intervention.isCompleted, true);
    });
  });

  group('InterventionAddress Tests', () {
    test('fullAddress should combine address fields correctly', () {
      final address = InterventionAddress(
        adresse: '123 Main Street',
        codePostal: '75001',
        ville: 'Paris',
      );

      expect(address.fullAddress, '123 Main Street, 75001, Paris');
    });

    test('fullAddress should handle empty fields', () {
      final address = InterventionAddress(
        adresse: '123 Main Street',
        ville: 'Paris',
      );

      expect(address.fullAddress, '123 Main Street, Paris');
    });

    test('accessInfo should combine access details correctly', () {
      final address = InterventionAddress(
        batiment: 'A',
        etage: '3',
        appartementLocal: '12',
        interphoneDigicode: '1234',
      );

      expect(
        address.accessInfo,
        'Bât. A - Étage 3 - Appt. 12 - Code: 1234',
      );
    });
  });

  group('InterventionInterruption Tests', () {
    test('isActive should return true when interruption is ongoing', () {
      final interruption = InterventionInterruption(
        id: '1',
        interventionId: 1,
        reason: 'lunch_break',
        startedAt: DateTime.now(),
      );

      expect(interruption.isActive, true);
    });

    test('isActive should return false when interruption is ended', () {
      final interruption = InterventionInterruption(
        id: '1',
        interventionId: 1,
        reason: 'lunch_break',
        startedAt: DateTime.now().subtract(Duration(hours: 1)),
        endedAt: DateTime.now(),
      );

      expect(interruption.isActive, false);
    });
  });

  group('InterventionWorkflow Tests', () {
    test('securityChecklistValues should parse semicolon-separated values', () {
      final workflow = InterventionWorkflow(
        interventionId: 1,
        securityChecklist: '1;0;1',
      );

      expect(workflow.securityChecklistValues, [true, false, true]);
    });

    test('securityChecklistValues should return default false values when null', () {
      final workflow = InterventionWorkflow(
        interventionId: 1,
      );

      expect(workflow.securityChecklistValues, [false, false, false]);
    });

    test('qualityControlValues should parse semicolon-separated values', () {
      final workflow = InterventionWorkflow(
        interventionId: 1,
        qualityControl: '0;1;1',
      );

      expect(workflow.qualityControlValues, [false, true, true]);
    });
  });
}
