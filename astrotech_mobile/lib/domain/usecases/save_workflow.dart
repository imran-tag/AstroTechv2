import '../entities/intervention.dart';
import '../repositories/intervention_repository.dart';

class SaveWorkflow {
  final InterventionRepository repository;

  SaveWorkflow(this.repository);

  Future<InterventionWorkflow> call(int interventionId, Map<String, dynamic> data) {
    return repository.saveWorkflow(interventionId, data);
  }
}
