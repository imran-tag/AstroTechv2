import '../repositories/intervention_repository.dart';

class SyncOfflineData {
  final InterventionRepository repository;

  SyncOfflineData(this.repository);

  Future<void> call() {
    return repository.syncOfflineData();
  }
}
