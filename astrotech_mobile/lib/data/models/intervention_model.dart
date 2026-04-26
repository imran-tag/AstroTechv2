import '../../domain/entities/intervention.dart';

class InterventionModel extends Intervention {
  const InterventionModel({
    required super.id,
    required super.numero,
    required super.titre,
    required super.type,
    super.description,
    super.priorite,
    super.etat,
    super.datePrevue,
    super.dureePrevueHeures,
    super.dureePrevueMinutes,
    super.motsCles,
    super.affaireId,
    super.affaireReference,
    super.affaireTitre,
    super.address,
    super.workflow,
    super.photos,
    super.referents,
    super.techniciens,
    super.interruptions,
    super.clientNom,
    super.photosBeforeCount,
    super.photosAfterCount,
  });

  factory InterventionModel.fromJson(Map<String, dynamic> json) {
    return InterventionModel(
      id: json['id'] as int,
      numero: json['numero'] as int? ?? 0,
      titre: json['titre'] as String? ?? '',
      type: json['type'] as String? ?? '',
      description: json['description'] as String?,
      priorite: json['priorite'] as String?,
      etat: json['etat'] as String?,
      datePrevue: json['date_prevue'] != null
          ? DateTime.tryParse(json['date_prevue'].toString())
          : null,
      dureePrevueHeures: json['duree_prevue_heures'] as int?,
      dureePrevueMinutes: json['duree_prevue_minutes'] as int?,
      motsCles: json['mots_cles'] as String?,
      affaireId: json['affaire_id'] as int?,
      affaireReference: json['affaire_reference'] as String?,
      affaireTitre: json['affaire_titre'] as String?,
      address: json['adresse'] != null || json['ville'] != null
          ? InterventionAddressModel.fromJson(json)
          : null,
      workflow: json['workflow'] != null
          ? InterventionWorkflowModel.fromJson(json['workflow'])
          : null,
      photos: json['photos'] != null
          ? InterventionPhotosModel.fromJson(json['photos'])
          : null,
      referents: json['referents'] != null
          ? (json['referents'] as List)
              .map((r) => InterventionReferentModel.fromJson(r))
              .toList()
          : null,
      techniciens: json['techniciens'] != null
          ? (json['techniciens'] as List)
              .map((t) => InterventionTechnicianModel.fromJson(t))
              .toList()
          : null,
      interruptions: json['interruptions'] != null
          ? (json['interruptions'] as List)
              .map((i) => InterventionInterruptionModel.fromJson(i))
              .toList()
          : null,
      clientNom: json['client_nom'] as String?,
      photosBeforeCount: _parseInt(json['photos_before_count']),
      photosAfterCount: _parseInt(json['photos_after_count']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero': numero,
      'titre': titre,
      'type': type,
      'description': description,
      'priorite': priorite,
      'etat': etat,
      'date_prevue': datePrevue?.toIso8601String(),
      'duree_prevue_heures': dureePrevueHeures,
      'duree_prevue_minutes': dureePrevueMinutes,
      'mots_cles': motsCles,
      'affaire_id': affaireId,
      'affaire_reference': affaireReference,
      'affaire_titre': affaireTitre,
      'client_nom': clientNom,
    };
  }
}

class InterventionAddressModel extends InterventionAddress {
  const InterventionAddressModel({
    super.id,
    super.adresse,
    super.codePostal,
    super.ville,
    super.province,
    super.pays,
    super.etage,
    super.appartementLocal,
    super.batiment,
    super.interphoneDigicode,
    super.escalier,
    super.porteEntree,
  });

  factory InterventionAddressModel.fromJson(Map<String, dynamic> json) {
    return InterventionAddressModel(
      id: json['adresse_id'] as int?,
      adresse: json['adresse'] as String?,
      codePostal: json['code_postal'] as String?,
      ville: json['ville'] as String?,
      province: json['province'] as String?,
      pays: json['pays'] as String?,
      etage: json['etage'] as String?,
      appartementLocal: json['appartement_local'] as String?,
      batiment: json['batiment'] as String?,
      interphoneDigicode: json['interphone_digicode'] as String?,
      escalier: json['escalier'] as String?,
      porteEntree: json['porte_entree'] as String?,
    );
  }
}

class InterventionWorkflowModel extends InterventionWorkflow {
  const InterventionWorkflowModel({
    super.id,
    required super.interventionId,
    super.securityChecklist,
    super.securityChecklistCompletedAt,
    super.comment,
    super.commentCompletedAt,
    super.qualityControl,
    super.qualityControlCompletedAt,
    super.signaturePath,
    super.signatureCompletedAt,
    super.currentStep,
    super.startedAt,
    super.completedAt,
    super.localId,
    super.clientObservations,
    super.clientObservationsCompletedAt,
    super.clientRating,
    super.ratingCompletedAt,
    super.clientSignaturePath,
    super.clientSignatureCompletedAt,
    super.technicalObservationsChoice,
    super.technicalObservationsCompletedAt,
    super.additionalWorkDescription,
    super.additionalWorkSignaturePath,
    super.quoteComment,
    super.quoteSignaturePath,
    super.completedBranches,
    super.loopCount,
    super.travelStartTime,
    super.travelEndTime,
    super.travelDurationMinutes,
    super.technicianSignaturePath,
    super.technicianSignatureCompletedAt,
  });

  factory InterventionWorkflowModel.fromJson(Map<String, dynamic> json) {
    return InterventionWorkflowModel(
      id: json['id'] as int?,
      interventionId: json['intervention_id'] as int? ?? 0,
      securityChecklist: json['security_checklist'] as String?,
      securityChecklistCompletedAt: json['security_checklist_completed_at'] != null
          ? DateTime.tryParse(json['security_checklist_completed_at'].toString())
          : null,
      comment: json['comment'] as String?,
      commentCompletedAt: json['comment_completed_at'] != null
          ? DateTime.tryParse(json['comment_completed_at'].toString())
          : null,
      qualityControl: json['quality_control'] as String?,
      qualityControlCompletedAt: json['quality_control_completed_at'] != null
          ? DateTime.tryParse(json['quality_control_completed_at'].toString())
          : null,
      signaturePath: json['signature_path'] as String?,
      signatureCompletedAt: json['signature_completed_at'] != null
          ? DateTime.tryParse(json['signature_completed_at'].toString())
          : null,
      currentStep: json['current_step'] as int? ?? 1,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'].toString())
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
      localId: json['local_id'] as String?,
      clientObservations: json['client_observations'] as String?,
      clientObservationsCompletedAt: json['client_observations_completed_at'] != null
          ? DateTime.tryParse(json['client_observations_completed_at'].toString())
          : null,
      clientRating: json['client_rating'] as int?,
      ratingCompletedAt: json['rating_completed_at'] != null
          ? DateTime.tryParse(json['rating_completed_at'].toString())
          : null,
      clientSignaturePath: json['client_signature_path'] as String?,
      clientSignatureCompletedAt: json['client_signature_completed_at'] != null
          ? DateTime.tryParse(json['client_signature_completed_at'].toString())
          : null,
      technicalObservationsChoice: json['technical_observations_choice'] as String?,
      technicalObservationsCompletedAt: json['technical_observations_completed_at'] != null
          ? DateTime.tryParse(json['technical_observations_completed_at'].toString())
          : null,
      additionalWorkDescription: json['additional_work_description'] as String?,
      additionalWorkSignaturePath: json['additional_work_signature_path'] as String?,
      quoteComment: json['quote_comment'] as String?,
      quoteSignaturePath: json['quote_signature_path'] as String?,
      completedBranches: json['completed_branches'] != null
          ? List<String>.from(json['completed_branches'] as List)
          : const [],
      loopCount: json['loop_count'] as int? ?? 0,
      travelStartTime: json['travel_start_time'] != null
          ? DateTime.tryParse(json['travel_start_time'].toString())
          : null,
      travelEndTime: json['travel_end_time'] != null
          ? DateTime.tryParse(json['travel_end_time'].toString())
          : null,
      travelDurationMinutes: json['travel_duration_minutes'] as int?,
      technicianSignaturePath: json['technician_signature_path'] as String?,
      technicianSignatureCompletedAt: json['technician_signature_completed_at'] != null
          ? DateTime.tryParse(json['technician_signature_completed_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'intervention_id': interventionId,
      'security_checklist': securityChecklist,
      'comment': comment,
      'quality_control': qualityControl,
      'signature_path': signaturePath,
      'current_step': currentStep,
      'local_id': localId,
      'client_observations': clientObservations,
      'client_rating': clientRating,
      'client_signature_path': clientSignaturePath,
      'technical_observations_choice': technicalObservationsChoice,
      'additional_work_description': additionalWorkDescription,
      'additional_work_signature_path': additionalWorkSignaturePath,
      'quote_comment': quoteComment,
      'quote_signature_path': quoteSignaturePath,
      'completed_branches': completedBranches,
      'loop_count': loopCount,
      'travel_start_time': travelStartTime?.toIso8601String(),
      'travel_end_time': travelEndTime?.toIso8601String(),
      'travel_duration_minutes': travelDurationMinutes,
      'technician_signature_path': technicianSignaturePath,
    };
  }
}

class InterventionPhotosModel extends InterventionPhotos {
  const InterventionPhotosModel({
    super.before,
    super.after,
  });

  factory InterventionPhotosModel.fromJson(Map<String, dynamic> json) {
    return InterventionPhotosModel(
      before: json['before'] != null
          ? (json['before'] as List)
              .map((p) => InterventionPhotoModel.fromJson(p))
              .toList()
          : [],
      after: json['after'] != null
          ? (json['after'] as List)
              .map((p) => InterventionPhotoModel.fromJson(p))
              .toList()
          : [],
    );
  }
}

class InterventionPhotoModel extends InterventionPhoto {
  const InterventionPhotoModel({
    super.id,
    required super.interventionId,
    required super.photoType,
    required super.fileName,
    required super.filePath,
    super.fileSize,
    super.mimeType,
    super.capturedAt,
    super.latitude,
    super.longitude,
    super.localId,
    super.localPath,
    super.comment,
    super.drawingEnabled,
    super.drawingData,
    super.photoContext,
  });

  factory InterventionPhotoModel.fromJson(Map<String, dynamic> json) {
    return InterventionPhotoModel(
      id: json['id'] as int?,
      interventionId: json['intervention_id'] as int? ?? 0,
      photoType: json['photo_type'] as String? ?? 'before',
      fileName: json['file_name'] as String? ?? '',
      filePath: json['file_path'] as String? ?? '',
      fileSize: json['file_size'] as int?,
      mimeType: json['mime_type'] as String?,
      capturedAt: json['captured_at'] != null
          ? DateTime.tryParse(json['captured_at'].toString())
          : null,
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      localId: json['local_id'] as String?,
      comment: json['comment'] as String?,
      drawingEnabled: json['drawing_enabled'] as bool?,
      drawingData: json['drawing_data'] as String?,
      photoContext: json['photo_context'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'intervention_id': interventionId,
      'photo_type': photoType,
      'file_name': fileName,
      'file_path': filePath,
      'file_size': fileSize,
      'mime_type': mimeType,
      'captured_at': capturedAt?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'local_id': localId,
      'comment': comment,
      'drawing_enabled': drawingEnabled,
      'drawing_data': drawingData,
      'photo_context': photoContext,
    };
  }
}

class InterventionInterruptionModel extends InterventionInterruption {
  const InterventionInterruptionModel({
    required super.id,
    required super.interventionId,
    required super.reason,
    super.customReason,
    required super.startedAt,
    super.endedAt,
    super.durationMinutes,
    super.localId,
  });

  factory InterventionInterruptionModel.fromJson(Map<String, dynamic> json) {
    return InterventionInterruptionModel(
      id: json['id'] as String,
      interventionId: json['intervention_id'] as int,
      reason: json['reason'] as String,
      customReason: json['custom_reason'] as String?,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null
          ? DateTime.tryParse(json['ended_at'].toString())
          : null,
      durationMinutes: json['duration_minutes'] as int?,
      localId: json['local_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'intervention_id': interventionId,
      'reason': reason,
      'custom_reason': customReason,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'local_id': localId,
    };
  }
}

class InterventionReferentModel extends InterventionReferent {
  const InterventionReferentModel({
    required super.id,
    required super.nomComplet,
    super.fonction,
    super.organisation,
  });

  factory InterventionReferentModel.fromJson(Map<String, dynamic> json) {
    return InterventionReferentModel(
      id: json['id'] as int,
      nomComplet: json['nom_complet'] as String? ?? '',
      fonction: json['fonction'] as String?,
      organisation: json['organisation'] as String?,
    );
  }
}

class InterventionTechnicianModel extends InterventionTechnician {
  const InterventionTechnicianModel({
    required super.id,
    required super.nom,
    required super.prenom,
    super.telephone,
    super.role,
  });

  factory InterventionTechnicianModel.fromJson(Map<String, dynamic> json) {
    return InterventionTechnicianModel(
      id: json['id'] as int,
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      telephone: json['telephone'] as String?,
      role: json['role'] as String?,
    );
  }
}
