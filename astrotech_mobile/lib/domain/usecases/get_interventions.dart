import '../entities/intervention.dart';
import '../repositories/intervention_repository.dart';

class GetInterventions {
  final InterventionRepository repository;

  GetInterventions(this.repository);

  Future<List<Intervention>> call({bool forceRefresh = false}) {
    return repository.getInterventions(forceRefresh: forceRefresh);
  }
}
