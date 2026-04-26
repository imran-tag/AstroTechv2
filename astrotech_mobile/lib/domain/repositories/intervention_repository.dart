import '../entities/intervention.dart';

abstract class InterventionRepository {
  Future<List<Intervention>> getInterventions({bool forceRefresh = false});
  Future<Intervention> getInterventionById(int id, {bool forceRefresh = false});
  Future<void> updateStatus(int interventionId, String status);
  Future<InterventionWorkflow> saveWorkflow(int interventionId, Map<String, dynamic> data);
  Future<InterventionPhoto> uploadPhoto({
    required int interventionId,
    required String localPath,
    required String photoType,
    double? latitude,
    double? longitude,
    String? comment,
    String? drawingData,
    String? photoContext,
  });
  Future<void> deletePhoto(int interventionId, int photoId);
  Future<void> uploadSignature(int interventionId, String signatureBase64);
  Future<void> uploadTypedSignature(int interventionId, String signatureType, String signatureBase64);
  Future<void> saveInterruption(InterventionInterruption interruption);
  Future<void> updateInterruption(InterventionInterruption interruption);
  Future<void> syncOfflineData();
  Future<int> getPendingSyncCount();
}
