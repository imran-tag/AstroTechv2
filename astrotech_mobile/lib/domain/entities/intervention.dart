import 'package:equatable/equatable.dart';

class Intervention extends Equatable {
  final int id;
  final int numero;
  final String titre;
  final String type;
  final String? description;
  final String? priorite;
  final String? etat;
  final DateTime? datePrevue;
  final int? dureePrevueHeures;
  final int? dureePrevueMinutes;
  final String? motsCles;
  final int? affaireId;
  final String? affaireReference;
  final String? affaireTitre;
  final InterventionAddress? address;
  final InterventionWorkflow? workflow;
  final InterventionPhotos? photos;
  final List<InterventionReferent>? referents;
  final List<InterventionTechnician>? techniciens;
  final List<InterventionInterruption>? interruptions;
  final String? clientNom;
  final int photosBeforeCount;
  final int photosAfterCount;

  const Intervention({
    required this.id,
    required this.numero,
    required this.titre,
    required this.type,
    this.description,
    this.priorite,
    this.etat,
    this.datePrevue,
    this.dureePrevueHeures,
    this.dureePrevueMinutes,
    this.motsCles,
    this.affaireId,
    this.affaireReference,
    this.affaireTitre,
    this.address,
    this.workflow,
    this.photos,
    this.referents,
    this.techniciens,
    this.interruptions,
    this.clientNom,
    this.photosBeforeCount = 0,
    this.photosAfterCount = 0,
  });

  int get currentStep => workflow?.currentStep ?? 1;
  bool get isStarted => workflow != null && workflow!.startedAt != null;
  bool get isCompleted => workflow != null && workflow!.completedAt != null;

  String get statusLabel {
    switch (etat) {
      case 'planifie':
        return 'Planifiée';
      case 'en_cours':
        return 'En cours';
      case 'termine':
        return 'Terminée';
      case 'non_validee':
        return 'Non validée';
      default:
        return etat ?? 'Inconnu';
    }
  }

  String get priorityLabel {
    switch (priorite?.toLowerCase()) {
      case 'urgent':
      case 'urgente':
        return 'Urgent';
      case 'haute':
      case 'high':
        return 'Haute';
      case 'normale':
      case 'normal':
        return 'Normale';
      case 'basse':
      case 'low':
        return 'Basse';
      default:
        return priorite ?? 'Normale';
    }
  }

  @override
  List<Object?> get props => [
        id,
        numero,
        titre,
        type,
        description,
        priorite,
        etat,
        datePrevue,
        affaireId,
        workflow,
        photosBeforeCount,
        photosAfterCount,
      ];
}

class InterventionAddress extends Equatable {
  final int? id;
  final String? adresse;
  final String? codePostal;
  final String? ville;
  final String? province;
  final String? pays;
  final String? etage;
  final String? appartementLocal;
  final String? batiment;
  final String? interphoneDigicode;
  final String? escalier;
  final String? porteEntree;

  const InterventionAddress({
    this.id,
    this.adresse,
    this.codePostal,
    this.ville,
    this.province,
    this.pays,
    this.etage,
    this.appartementLocal,
    this.batiment,
    this.interphoneDigicode,
    this.escalier,
    this.porteEntree,
  });

  String get fullAddress {
    final parts = <String>[];
    if (adresse != null && adresse!.isNotEmpty) parts.add(adresse!);
    if (codePostal != null && codePostal!.isNotEmpty) parts.add(codePostal!);
    if (ville != null && ville!.isNotEmpty) parts.add(ville!);
    return parts.join(', ');
  }

  String get accessInfo {
    final parts = <String>[];
    if (batiment != null && batiment!.isNotEmpty) parts.add('Bât. $batiment');
    if (etage != null && etage!.isNotEmpty) parts.add('Étage $etage');
    if (appartementLocal != null && appartementLocal!.isNotEmpty) {
      parts.add('Appt. $appartementLocal');
    }
    if (interphoneDigicode != null && interphoneDigicode!.isNotEmpty) {
      parts.add('Code: $interphoneDigicode');
    }
    return parts.join(' - ');
  }

  @override
  List<Object?> get props => [id, adresse, codePostal, ville];
}

class InterventionWorkflow extends Equatable {
  final int? id;
  final int interventionId;
  final String? securityChecklist;
  final DateTime? securityChecklistCompletedAt;
  final String? comment;
  final DateTime? commentCompletedAt;
  final String? qualityControl;
  final DateTime? qualityControlCompletedAt;
  final String? signaturePath;
  final DateTime? signatureCompletedAt;
  final int currentStep;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? localId;

  // Step 4: Observations (combined)
  final String? clientObservations;
  final DateTime? clientObservationsCompletedAt;
  final int? clientRating; // 1-5 stars
  final DateTime? ratingCompletedAt;
  final String? clientSignaturePath;
  final DateTime? clientSignatureCompletedAt;

  // Step 5: Technical Observations
  final String? technicalObservationsChoice; // 'additional_work' | 'delivery_note' | 'quote' | 'finish'
  final DateTime? technicalObservationsCompletedAt;

  // Conditional Branch Data
  final String? additionalWorkDescription;
  final String? additionalWorkSignaturePath;

  final String? quoteComment;
  final String? quoteSignaturePath;

  // Navigation tracking
  final List<String> completedBranches;
  final int loopCount;

  // Travel time
  final DateTime? travelStartTime;
  final DateTime? travelEndTime;
  final int? travelDurationMinutes;

  // Technician final signature
  final String? technicianSignaturePath;
  final DateTime? technicianSignatureCompletedAt;

  const InterventionWorkflow({
    this.id,
    required this.interventionId,
    this.securityChecklist,
    this.securityChecklistCompletedAt,
    this.comment,
    this.commentCompletedAt,
    this.qualityControl,
    this.qualityControlCompletedAt,
    this.signaturePath,
    this.signatureCompletedAt,
    this.currentStep = 1,
    this.startedAt,
    this.completedAt,
    this.localId,
    this.clientObservations,
    this.clientObservationsCompletedAt,
    this.clientRating,
    this.ratingCompletedAt,
    this.clientSignaturePath,
    this.clientSignatureCompletedAt,
    this.technicalObservationsChoice,
    this.technicalObservationsCompletedAt,
    this.additionalWorkDescription,
    this.additionalWorkSignaturePath,
    this.quoteComment,
    this.quoteSignaturePath,
    this.completedBranches = const [],
    this.loopCount = 0,
    this.travelStartTime,
    this.travelEndTime,
    this.travelDurationMinutes,
    this.technicianSignaturePath,
    this.technicianSignatureCompletedAt,
  });

  List<bool> get securityChecklistValues {
    if (securityChecklist == null || securityChecklist!.isEmpty) {
      return [false, false, false];
    }
    return securityChecklist!.split(';').map((v) => v == '1').toList();
  }

  List<bool> get qualityControlValues {
    if (qualityControl == null || qualityControl!.isEmpty) {
      return [false, false, false];
    }
    return qualityControl!.split(';').map((v) => v == '1').toList();
  }

  @override
  List<Object?> get props => [
        id,
        interventionId,
        currentStep,
        securityChecklist,
        comment,
        qualityControl,
        signaturePath,
        completedAt,
        clientObservations,
        clientRating,
        clientSignaturePath,
        technicalObservationsChoice,
        additionalWorkDescription,
        additionalWorkSignaturePath,
        quoteComment,
        quoteSignaturePath,
        completedBranches,
        loopCount,
        travelStartTime,
        travelEndTime,
        technicianSignaturePath,
      ];
}

class InterventionPhotos extends Equatable {
  final List<InterventionPhoto> before;
  final List<InterventionPhoto> after;

  const InterventionPhotos({
    this.before = const [],
    this.after = const [],
  });

  @override
  List<Object?> get props => [before, after];
}

class InterventionPhoto extends Equatable {
  final int? id;
  final int interventionId;
  final String photoType;
  final String fileName;
  final String filePath;
  final int? fileSize;
  final String? mimeType;
  final DateTime? capturedAt;
  final double? latitude;
  final double? longitude;
  final String? localId;
  final String? localPath; // For offline-stored photos
  final String? comment;
  final bool? drawingEnabled;
  final String? drawingData; // Base64 drawing overlay
  final String? photoContext; // 'before', 'after', 'additional_work', 'delivery_note', 'quote'

  const InterventionPhoto({
    this.id,
    required this.interventionId,
    required this.photoType,
    required this.fileName,
    required this.filePath,
    this.fileSize,
    this.mimeType,
    this.capturedAt,
    this.latitude,
    this.longitude,
    this.localId,
    this.localPath,
    this.comment,
    this.drawingEnabled,
    this.drawingData,
    this.photoContext,
  });

  @override
  List<Object?> get props => [
        id,
        interventionId,
        photoType,
        fileName,
        filePath,
        localId,
        comment,
        drawingData,
        photoContext,
      ];
}

class InterventionInterruption extends Equatable {
  final String id;
  final int interventionId;
  final String reason; // 'material_purchase', 'lunch_break', 'other'
  final String? customReason;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? durationMinutes;
  final String? localId;

  const InterventionInterruption({
    required this.id,
    required this.interventionId,
    required this.reason,
    this.customReason,
    required this.startedAt,
    this.endedAt,
    this.durationMinutes,
    this.localId,
  });

  bool get isActive => endedAt == null;

  @override
  List<Object?> get props => [
        id,
        interventionId,
        reason,
        customReason,
        startedAt,
        endedAt,
        durationMinutes,
      ];
}

class InterventionReferent extends Equatable {
  final int id;
  final String nomComplet;
  final String? fonction;
  final String? organisation;

  const InterventionReferent({
    required this.id,
    required this.nomComplet,
    this.fonction,
    this.organisation,
  });

  @override
  List<Object?> get props => [id, nomComplet];
}

class InterventionTechnician extends Equatable {
  final int id;
  final String nom;
  final String prenom;
  final String? telephone;
  final String? role;

  const InterventionTechnician({
    required this.id,
    required this.nom,
    required this.prenom,
    this.telephone,
    this.role,
  });

  String get fullName => '$prenom $nom';

  @override
  List<Object?> get props => [id, nom, prenom];
}
