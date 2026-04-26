class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'AstroTech Mobile';
  static const String appTitle = 'AstroTech';

  // Auth
  static const String login = 'Connexion';
  static const String logout = 'Déconnexion';
  static const String email = 'Email';
  static const String password = 'Mot de passe';
  static const String loginButton = 'Se connecter';
  static const String loginError = 'Erreur de connexion';
  static const String invalidCredentials = 'Email ou mot de passe incorrect';

  // Interventions
  static const String interventions = 'Interventions';
  static const String intervention = 'Intervention';
  static const String noInterventions = 'Aucune intervention';
  static const String startIntervention = 'Démarrer l\'intervention';
  static const String continueIntervention = 'Continuer';
  static const String interventionCompleted = 'Intervention terminée';

  // Status
  static const String statusPlanifie = 'Planifiée';
  static const String statusEnCours = 'En cours';
  static const String statusTermine = 'Terminée';
  static const String statusNonValidee = 'Non validée';

  // Priority
  static const String priorityUrgent = 'Urgent';
  static const String priorityHigh = 'Haute';
  static const String priorityNormal = 'Normale';
  static const String priorityLow = 'Basse';

  // Workflow steps
  static const String step1Title = 'Checklist Sécurité';
  static const String step2Title = 'Photos Avant';
  static const String step3Title = 'Photos Après';
  static const String step4Title = 'Commentaire';
  static const String step5Title = 'Contrôle Qualité';
  static const String step6Title = 'Signature';

  // Security checklist items
  static const String securityItem1 = 'EPI portés (casque, gants, chaussures)';
  static const String securityItem2 = 'Zone de travail sécurisée';
  static const String securityItem3 = 'Outils en bon état';

  // Quality control items
  static const String qcItem1 = 'Travail effectué selon les normes';
  static const String qcItem2 = 'Zone de travail nettoyée';
  static const String qcItem3 = 'Client informé du résultat';

  // Photos
  static const String photosBefore = 'Photos avant intervention';
  static const String photosAfter = 'Photos après intervention';
  static const String takePhoto = 'Prendre une photo';
  static const String selectFromGallery = 'Choisir depuis la galerie';
  static const String deletePhoto = 'Supprimer la photo';
  static const String noPhotos = 'Aucune photo';
  static const String minPhotosRequired = 'Minimum 1 photo requise';

  // Comment
  static const String comment = 'Commentaire';
  static const String commentPlaceholder = 'Décrivez le travail effectué...';

  // Signature
  static const String signature = 'Signature';
  static const String signatureInstruction = 'Signez dans le cadre ci-dessous';
  static const String clearSignature = 'Effacer';
  static const String signatureRequired = 'Signature requise';

  // Actions
  static const String next = 'Suivant';
  static const String previous = 'Précédent';
  static const String save = 'Enregistrer';
  static const String cancel = 'Annuler';
  static const String confirm = 'Confirmer';
  static const String finish = 'Terminer';
  static const String retry = 'Réessayer';
  static const String refresh = 'Actualiser';

  // Sync
  static const String syncing = 'Synchronisation...';
  static const String syncComplete = 'Synchronisation terminée';
  static const String syncFailed = 'Échec de la synchronisation';
  static const String offlineMode = 'Mode hors ligne';
  static const String pendingSync = 'En attente de synchronisation';

  // Errors
  static const String errorGeneric = 'Une erreur est survenue';
  static const String errorNetwork = 'Erreur de connexion réseau';
  static const String errorServer = 'Erreur serveur';
  static const String errorTimeout = 'Délai d\'attente dépassé';

  // Confirmations
  static const String confirmLogout = 'Voulez-vous vous déconnecter ?';
  static const String confirmDeletePhoto = 'Voulez-vous supprimer cette photo ?';
  static const String confirmFinishIntervention = 'Voulez-vous terminer cette intervention ?';

  // Solitech Workflow - Observations
  static const String observationsTitle = 'Observations';
  static const String clientObservations = 'Observations du client';
  static const String clientObservationsPlaceholder = 'Rien à signaler';
  static const String clientRating = 'Notation';
  static const String ratingInstruction = 'Évaluez la qualité de l\'intervention';
  static const String clientSignature = 'Signature du client';
  static const String clientSignatureInstruction = 'Signature du client pour validation';

  // Solitech Workflow - Technical Observations
  static const String technicalObservationsTitle = 'Observations Techniques';
  static const String technicalObservationsInstruction = 'Sélectionnez une option :';
  static const String techObsAdditionalWork = 'Travaux supplémentaires réalisés';
  static const String techObsDeliveryNote = 'BON DE LIVRAISON';
  static const String techObsQuote = 'Devis à faire';
  static const String techObsFinish = 'Finir l\'intervention';
  static const String completedBranches = 'Branches complétées :';
  static const String loopCounter = 'Itération';

  // Additional Work Branch
  static const String additionalWorkTitle = 'Travaux Supplémentaires';
  static const String additionalWorkDescription = 'Description des travaux';
  static const String additionalWorkDescriptionPlaceholder = 'Décrivez les travaux supplémentaires effectués...';
  static const String additionalWorkPhotos = 'Photos des travaux';
  static const String additionalWorkSignature = 'Signature travaux supplémentaires';
  static const String minAdditionalWorkPhotos = 'Minimum 1 photo requise';

  // Delivery Note Branch
  static const String deliveryNoteTitle = 'Bon de Livraison';
  static const String deliveryNotePhotos = 'Photos du bon de livraison';
  static const String deliveryNoteInstruction = 'Prenez des photos du bon de livraison';
  static const String minDeliveryNotePhotos = 'Minimum 1 photo requise';

  // Quote Branch
  static const String quoteTitle = 'Devis';
  static const String quoteComment = 'Commentaire du devis';
  static const String quoteCommentPlaceholder = 'Détails du devis à établir...';
  static const String quotePhotos = 'Photos pour le devis';
  static const String quotePhotosInstruction = 'Prenez des photos pour établir le devis';
  static const String quoteSignature = 'Signature du devis';
  static const String minQuotePhotos = 'Minimum 1 photo requise';

  // Technician Signature
  static const String technicianSignature = 'Signature du Technicien';
  static const String technicianSignatureInstruction = 'Signature finale du technicien';
  static const String technicianSignatureRequired = 'Signature du technicien requise';

  // Interruptions
  static const String interruptions = 'Interruptions';
  static const String startInterruption = 'Démarrer une interruption';
  static const String endInterruption = 'Terminer l\'interruption';
  static const String activeInterruption = 'Interruption en cours';
  static const String interruptionReason = 'Raison de l\'interruption';
  static const String interruptionMaterialPurchase = 'Achat matériel';
  static const String interruptionLunchBreak = 'Pause déjeuner';
  static const String interruptionOther = 'Autre';
  static const String interruptionCustomReason = 'Précisez la raison';
  static const String interruptionDuration = 'Durée';
  static const String noInterruptions = 'Aucune interruption';

  // Travel Time
  static const String travelTime = 'Temps de trajet';
  static const String startTravelTime = 'Démarrer le trajet';
  static const String endTravelTime = 'Terminer le trajet';
  static const String travelTimeActive = 'Trajet en cours';
  static const String travelTimeDuration = 'Durée du trajet';

  // Photo Enhancements
  static const String photoComment = 'Commentaire de la photo';
  static const String photoCommentPlaceholder = 'Ajoutez un commentaire...';
  static const String enableDrawing = 'Activer le dessin';
  static const String drawOnPhoto = 'Dessiner sur la photo';
  static const String photoWithDrawing = 'Photo avec annotations';

  // Validation Messages
  static const String observationsRequired = 'Observations requises';
  static const String ratingRequired = 'Notation requise';
  static const String minPhotosBeforeRequired = 'Minimum 2 photos avant requises';
  static const String minPhotosAfterRequired = 'Minimum 1 photo après requise';
  static const String technicalObservationChoiceRequired = 'Sélectionnez une option';
  static const String additionalWorkDescriptionRequired = 'Description requise';

  // Progress
  static const String workflowProgress = 'Progression';
  static const String currentStep = 'Étape actuelle';
  static const String stepsCompleted = 'Étapes terminées';
}
