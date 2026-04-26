import '../repositories/intervention_repository.dart';

class UpdateInterventionStatus {
  final InterventionRepository repository;

  UpdateInterventionStatus(this.repository);

  Future<void> call(int interventionId, String status) {
    return repository.updateStatus(interventionId, status);
  }
}
