import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../models/intervention_model.dart';

class InterventionRemoteDatasource {
  final ApiClient _apiClient;

  InterventionRemoteDatasource(this._apiClient);

  Future<List<InterventionModel>> getInterventions() async {
    final response = await _apiClient.get(ApiConstants.mobileInterventions);
    final data = response.data['data'] as List;
    return data.map((json) => InterventionModel.fromJson(json)).toList();
  }

  Future<InterventionModel> getInterventionById(int id) async {
    final response = await _apiClient.get(ApiConstants.mobileInterventionDetail(id));
    return InterventionModel.fromJson(response.data['data']);
  }

  Future<void> updateStatus(int interventionId, String status, {String? deviceId}) async {
    await _apiClient.put(
      ApiConstants.mobileInterventionStatus(interventionId),
      data: {
        'status': status,
        if (deviceId != null) 'device_id': deviceId,
      },
    );
  }

  Future<InterventionWorkflowModel> saveWorkflow(
    int interventionId,
    Map<String, dynamic> workflowData,
  ) async {
    final response = await _apiClient.patch(
      ApiConstants.mobileInterventionWorkflow(interventionId),
      data: workflowData,
    );
    return InterventionWorkflowModel.fromJson(response.data['data']);
  }

  Future<InterventionWorkflowModel> createWorkflow(
    int interventionId,
    Map<String, dynamic> workflowData,
  ) async {
    final response = await _apiClient.post(
      ApiConstants.mobileInterventionWorkflow(interventionId),
      data: workflowData,
    );
    return InterventionWorkflowModel.fromJson(response.data['data']);
  }

  Future<List<InterventionPhotoModel>> getPhotos(int interventionId, {String? type}) async {
    final response = await _apiClient.get(
      ApiConstants.mobileInterventionPhotos(interventionId),
      queryParameters: type != null ? {'type': type} : null,
    );
    final data = response.data['data'] as List;
    return data.map((json) => InterventionPhotoModel.fromJson(json)).toList();
  }

  Future<InterventionPhotoModel> uploadPhoto({
    required int interventionId,
    required String filePath,
    required String photoType,
    String? capturedAt,
    double? latitude,
    double? longitude,
    String? localId,
    String? comment,
    String? drawingData,
    String? photoContext,
  }) async {
    final response = await _apiClient.uploadFile(
      ApiConstants.mobileInterventionPhotos(interventionId),
      filePath: filePath,
      fieldName: 'photo',
      data: {
        'photo_type': photoType,
        if (capturedAt != null) 'captured_at': capturedAt,
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
        if (localId != null) 'local_id': localId,
        if (comment != null) 'comment': comment,
        if (drawingData != null) 'drawing_data': drawingData,
        if (photoContext != null) 'photo_context': photoContext,
      },
    );
    return InterventionPhotoModel.fromJson(response.data['data']);
  }

  Future<void> deletePhoto(int interventionId, int photoId) async {
    await _apiClient.delete(
      ApiConstants.mobileInterventionPhoto(interventionId, photoId),
    );
  }

  Future<void> uploadSignature(int interventionId, String signatureBase64) async {
    await _apiClient.post(
      ApiConstants.mobileInterventionSignature(interventionId),
      data: {
        'signature_data': signatureBase64,
      },
    );
  }

  Future<void> uploadTypedSignature(int interventionId, String signatureType, String signatureBase64) async {
    await _apiClient.post(
      ApiConstants.mobileInterventionTypedSignature(interventionId, signatureType),
      data: {
        'signature_data': signatureBase64,
      },
    );
  }

  Future<void> saveInterruption(dynamic interruption) async {
    await _apiClient.post(
      ApiConstants.mobileInterventionInterruptions(interruption.interventionId),
      data: {
        'id': interruption.id,
        'reason': interruption.reason,
        'custom_reason': interruption.customReason,
        'started_at': interruption.startedAt.toIso8601String(),
        if (interruption.endedAt != null) 'ended_at': interruption.endedAt!.toIso8601String(),
        if (interruption.durationMinutes != null) 'duration_minutes': interruption.durationMinutes,
      },
    );
  }

  Future<void> updateInterruption(dynamic interruption) async {
    await _apiClient.patch(
      ApiConstants.mobileInterventionInterruption(interruption.interventionId, interruption.id),
      data: {
        'ended_at': interruption.endedAt?.toIso8601String(),
        'duration_minutes': interruption.durationMinutes,
      },
    );
  }

  Future<Map<String, dynamic>> bulkSync(Map<String, dynamic> syncData) async {
    final response = await _apiClient.post(
      ApiConstants.mobileSync,
      data: syncData,
    );
    return response.data['data'] as Map<String, dynamic>;
  }
}
