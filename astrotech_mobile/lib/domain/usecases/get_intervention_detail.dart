import '../entities/intervention.dart';
import '../repositories/intervention_repository.dart';

class GetInterventionDetail {
  final InterventionRepository repository;

  GetInterventionDetail(this.repository);

  Future<Intervention> call(int id, {bool forceRefresh = false}) {
    return repository.getInterventionById(id, forceRefresh: forceRefresh);
  }
}
