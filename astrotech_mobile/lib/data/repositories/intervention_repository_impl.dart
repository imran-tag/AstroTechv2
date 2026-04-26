import 'package:uuid/uuid.dart';

import '../../domain/entities/intervention.dart';
import '../../domain/repositories/intervention_repository.dart';
import '../../services/connectivity_service.dart';
import '../datasources/local/local_database.dart';
import '../datasources/local/sync_queue_datasource.dart';
import '../datasources/remote/intervention_remote_datasource.dart';
import '../models/intervention_model.dart';

class InterventionRepositoryImpl implements InterventionRepository {
  final InterventionRemoteDatasource remoteDatasource;
  final LocalDatabase localDatabase;
  final SyncQueueDatasource syncQueue;
  final ConnectivityService connectivityService;

  final _uuid = const Uuid();

  InterventionRepositoryImpl({
    required this.remoteDatasource,
    required this.localDatabase,
    required this.syncQueue,
    required this.connectivityService,
  });

  @override
  Future<List<Intervention>> getInterventions({bool forceRefresh = false}) async {
    final isOnline = await connectivityService.isConnected;

    if (isOnline && forceRefresh) {
      try {
        final interventions = await remoteDatasource.getInterventions();
        await localDatabase.saveInterventions(interventions);
        return interventions;
      } catch (e) {
        // Fall back to local data on error
        return await localDatabase.getInterventions();
      }
    }

    // Try local first
    final localInterventions = await localDatabase.getInterventions();
    if (localInterventions.isNotEmpty) {
      // Refresh in background if online
      if (isOnline) {
        _refreshInBackground();
      }
      return localInterventions;
    }

    // No local data, fetch from remote
    if (isOnline) {
      final interventions = await remoteDatasource.getInterventions();
      await localDatabase.saveInterventions(interventions);
      return interventions;
    }

    return [];
  }

  Future<void> _refreshInBackground() async {
    try {
      final interventions = await remoteDatasource.getInterventions();
      await localDatabase.saveInterventions(interventions);
    } catch (e) {
      // Silent fail for background refresh
    }
  }

  @override
  Future<Intervention> getInterventionById(int id, {bool forceRefresh = false}) async {
    final isOnline = await connectivityService.isConnected;

    if (isOnline && forceRefresh) {
      try {
        final intervention = await remoteDatasource.getInterventionById(id);
        await localDatabase.saveIntervention(intervention);
        return intervention;
      } catch (e) {
        final local = await localDatabase.getInterventionById(id);
        if (local != null) return local;
        rethrow;
      }
    }

    // Try local first
    final local = await localDatabase.getInterventionById(id);
    if (local != null) {
      if (isOnline) {
        // Refresh in background
        remoteDatasource.getInterventionById(id).then((intervention) {
          localDatabase.saveIntervention(intervention);
        }).catchError((_) {});
      }
      return local;
    }

    // Fetch from remote
    if (isOnline) {
      final intervention = await remoteDatasource.getInterventionById(id);
      await localDatabase.saveIntervention(intervention);
      return intervention;
    }

    throw Exception('Intervention not found and offline');
  }

  @override
  Future<void> updateStatus(int interventionId, String status) async {
    final isOnline = await connectivityService.isConnected;

    if (isOnline) {
      try {
        await remoteDatasource.updateStatus(interventionId, status);
        return;
      } catch (e) {
        // Queue for later sync
      }
    }

    // Queue for sync
    await syncQueue.enqueue(SyncItem(
      type: SyncItemType.status,
      interventionId: interventionId,
      data: {'status': status},
    ));
  }

  @override
  Future<InterventionWorkflow> saveWorkflow(int interventionId, Map<String, dynamic> data) async {
    final isOnline = await connectivityService.isConnected;
    final localId = data['local_id'] ?? _uuid.v4();
    data['local_id'] = localId;

    // Always save locally first
    await localDatabase.saveWorkflow(interventionId, data, pendingSync: true);

    if (isOnline) {
      try {
        final workflow = await remoteDatasource.saveWorkflow(interventionId, data);
        await localDatabase.markWorkflowSynced(interventionId);
        return workflow;
      } catch (e) {
        // Queue for sync
        await syncQueue.enqueue(SyncItem(
          type: SyncItemType.workflow,
          interventionId: interventionId,
          data: data,
        ));
        return InterventionWorkflowModel(
          interventionId: interventionId,
          currentStep: data['current_step'] ?? 1,
          securityChecklist: data['security_checklist'],
          comment: data['comment'],
          qualityControl: data['quality_control'],
          signaturePath: data['signature_path'],
          localId: localId,
        );
      }
    }

    // Queue for sync when offline
    await syncQueue.enqueue(SyncItem(
      type: SyncItemType.workflow,
      interventionId: interventionId,
      data: data,
    ));

    return InterventionWorkflowModel(
      interventionId: interventionId,
      currentStep: data['current_step'] ?? 1,
      securityChecklist: data['security_checklist'],
      comment: data['comment'],
      qualityControl: data['quality_control'],
      signaturePath: data['signature_path'],
      localId: localId,
    );
  }

  @override
  Future<InterventionPhoto> uploadPhoto({
    required int interventionId,
    required String localPath,
    required String photoType,
    double? latitude,
    double? longitude,
    String? comment,
    String? drawingData,
    String? photoContext,
  }) async {
    final isOnline = await connectivityService.isConnected;
    final localId = _uuid.v4();
    final capturedAt = DateTime.now().toIso8601String();

    // Save locally first
    await localDatabase.savePhotoLocally(
      interventionId: interventionId,
      photoType: photoType,
      localPath: localPath,
      localId: localId,
      metadata: {
        'captured_at': capturedAt,
        'latitude': latitude,
        'longitude': longitude,
        'comment': comment,
        'drawing_data': drawingData,
        'photo_context': photoContext,
      },
    );

    if (isOnline) {
      try {
        final photo = await remoteDatasource.uploadPhoto(
          interventionId: interventionId,
          filePath: localPath,
          photoType: photoType,
          capturedAt: capturedAt,
          latitude: latitude,
          longitude: longitude,
          localId: localId,
          comment: comment,
          drawingData: drawingData,
          photoContext: photoContext,
        );
        await localDatabase.markPhotoSynced(localId);
        return photo;
      } catch (e) {
        // Queue for sync
        await syncQueue.enqueue(SyncItem(
          type: SyncItemType.photo,
          interventionId: interventionId,
          data: {
            'local_path': localPath,
            'photo_type': photoType,
            'local_id': localId,
            'captured_at': capturedAt,
            'latitude': latitude,
            'longitude': longitude,
            'comment': comment,
            'drawing_data': drawingData,
            'photo_context': photoContext,
          },
        ));
      }
    } else {
      // Queue for sync when offline
      await syncQueue.enqueue(SyncItem(
        type: SyncItemType.photo,
        interventionId: interventionId,
        data: {
          'local_path': localPath,
          'photo_type': photoType,
          'local_id': localId,
          'captured_at': capturedAt,
          'latitude': latitude,
          'longitude': longitude,
          'comment': comment,
          'drawing_data': drawingData,
          'photo_context': photoContext,
        },
      ));
    }

    return InterventionPhotoModel(
      interventionId: interventionId,
      photoType: photoType,
      fileName: localPath.split('/').last,
      filePath: localPath,
      localId: localId,
      localPath: localPath,
      capturedAt: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
      comment: comment,
      drawingData: drawingData,
      photoContext: photoContext,
    );
  }

  @override
  Future<void> deletePhoto(int interventionId, int photoId) async {
    final isOnline = await connectivityService.isConnected;

    if (isOnline) {
      await remoteDatasource.deletePhoto(interventionId, photoId);
    } else {
      throw Exception('Cannot delete photo while offline');
    }
  }

  @override
  Future<void> uploadSignature(int interventionId, String signatureBase64) async {
    final isOnline = await connectivityService.isConnected;

    if (isOnline) {
      try {
        await remoteDatasource.uploadSignature(interventionId, signatureBase64);
        return;
      } catch (e) {
        // Queue for sync
      }
    }

    // Queue for sync
    await syncQueue.enqueue(SyncItem(
      type: SyncItemType.signature,
      interventionId: interventionId,
      data: {'signature_data': signatureBase64},
    ));
  }

  @override
  Future<void> uploadTypedSignature(int interventionId, String signatureType, String signatureBase64) async {
    final isOnline = await connectivityService.isConnected;

    if (isOnline) {
      try {
        await remoteDatasource.uploadTypedSignature(interventionId, signatureType, signatureBase64);
        return;
      } catch (e) {
        // Queue for sync
      }
    }

    // Queue for sync
    await syncQueue.enqueue(SyncItem(
      type: SyncItemType.signature,
      interventionId: interventionId,
      data: {
        'signature_data': signatureBase64,
        'signature_type': signatureType,
      },
    ));
  }

  @override
  Future<void> saveInterruption(InterventionInterruption interruption) async {
    final isOnline = await connectivityService.isConnected;

    // Always save locally first
    await localDatabase.saveInterruption(
      id: interruption.id,
      interventionId: interruption.interventionId,
      reason: interruption.reason,
      customReason: interruption.customReason,
      startedAt: interruption.startedAt,
      endedAt: interruption.endedAt,
      durationMinutes: interruption.durationMinutes,
      localId: interruption.localId,
    );

    if (isOnline) {
      try {
        await remoteDatasource.saveInterruption(interruption);
        return;
      } catch (e) {
        // Queue for sync
      }
    }

    // Queue for sync if offline or failed
    await syncQueue.enqueue(SyncItem(
      type: SyncItemType.interruption,
      interventionId: interruption.interventionId,
      data: {
        'id': interruption.id,
        'reason': interruption.reason,
        'custom_reason': interruption.customReason,
        'started_at': interruption.startedAt.toIso8601String(),
        'ended_at': interruption.endedAt?.toIso8601String(),
        'duration_minutes': interruption.durationMinutes,
      },
    ));
  }

  @override
  Future<void> updateInterruption(InterventionInterruption interruption) async {
    final isOnline = await connectivityService.isConnected;

    // Update locally first
    if (interruption.endedAt != null && interruption.durationMinutes != null) {
      await localDatabase.updateInterruption(
        id: interruption.id,
        endedAt: interruption.endedAt!,
        durationMinutes: interruption.durationMinutes!,
      );
    }

    if (isOnline) {
      try {
        await remoteDatasource.updateInterruption(interruption);
        return;
      } catch (e) {
        // Queue for sync
      }
    }

    // Queue for sync if offline or failed
    await syncQueue.enqueue(SyncItem(
      type: SyncItemType.interruption,
      interventionId: interruption.interventionId,
      data: {
        'id': interruption.id,
        'ended_at': interruption.endedAt?.toIso8601String(),
        'duration_minutes': interruption.durationMinutes,
      },
    ));
  }

  @override
  Future<void> syncOfflineData() async {
    final isOnline = await connectivityService.isConnected;
    if (!isOnline) return;

    final pendingItems = await syncQueue.getPendingItems();

    for (final item in pendingItems) {
      try {
        switch (item.type) {
          case SyncItemType.workflow:
            await remoteDatasource.saveWorkflow(item.interventionId, item.data);
            break;
          case SyncItemType.photo:
            await remoteDatasource.uploadPhoto(
              interventionId: item.interventionId,
              filePath: item.data['local_path'],
              photoType: item.data['photo_type'],
              capturedAt: item.data['captured_at'],
              latitude: item.data['latitude'],
              longitude: item.data['longitude'],
              localId: item.data['local_id'],
              comment: item.data['comment'],
              drawingData: item.data['drawing_data'],
              photoContext: item.data['photo_context'],
            );
            break;
          case SyncItemType.status:
            await remoteDatasource.updateStatus(item.interventionId, item.data['status']);
            break;
          case SyncItemType.signature:
            if (item.data.containsKey('signature_type')) {
              await remoteDatasource.uploadTypedSignature(
                item.interventionId,
                item.data['signature_type'],
                item.data['signature_data'],
              );
            } else {
              await remoteDatasource.uploadSignature(item.interventionId, item.data['signature_data']);
            }
            break;
          case SyncItemType.interruption:
            final interruption = InterventionInterruption(
              id: item.data['id'] as String,
              interventionId: item.interventionId,
              reason: item.data['reason'] as String,
              customReason: item.data['custom_reason'] as String?,
              startedAt: DateTime.parse(item.data['started_at'] as String),
              endedAt: item.data['ended_at'] != null
                  ? DateTime.parse(item.data['ended_at'] as String)
                  : null,
              durationMinutes: item.data['duration_minutes'] as int?,
            );
            if (item.data['ended_at'] != null) {
              await remoteDatasource.updateInterruption(interruption);
            } else {
              await remoteDatasource.saveInterruption(interruption);
            }
            break;
        }
        await syncQueue.markCompleted(item.id!);
      } catch (e) {
        await syncQueue.markFailed(item.id!, e.toString());
      }
    }

    // Clean up completed items
    await syncQueue.clearCompleted();
  }

  @override
  Future<int> getPendingSyncCount() async {
    return await syncQueue.getPendingCount();
  }
}
