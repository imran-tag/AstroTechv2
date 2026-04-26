import '../entities/intervention.dart';
import '../repositories/intervention_repository.dart';

class UploadPhoto {
  final InterventionRepository repository;

  UploadPhoto(this.repository);

  Future<InterventionPhoto> call({
    required int interventionId,
    required String localPath,
    required String photoType,
    double? latitude,
    double? longitude,
    String? comment,
    String? drawingData,
    String? photoContext,
  }) {
    return repository.uploadPhoto(
      interventionId: interventionId,
      localPath: localPath,
      photoType: photoType,
      latitude: latitude,
      longitude: longitude,
      comment: comment,
      drawingData: drawingData,
      photoContext: photoContext,
    );
  }
}
