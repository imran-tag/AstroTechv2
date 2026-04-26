import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/permission_utils.dart';
import '../../../../domain/entities/intervention.dart';
import '../../../../injection_container.dart';
import '../../../../services/photo_service.dart';
import '../../../blocs/workflow/workflow_bloc.dart';

/// Delivery Note Photos Step
/// Delivery note branch - capture photos of the delivery note
class DeliveryNotePhotosStep extends StatelessWidget {
  final List<InterventionPhoto> photos;
  final int interventionId;

  const DeliveryNotePhotosStep({
    super.key,
    required this.photos,
    required this.interventionId,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 24),

          // Info card
          _buildInfoCard(),
          const SizedBox(height: 24),

          // Photos grid
          _buildPhotosSection(context),
          const SizedBox(height: 24),

          // Add photo button
          _buildAddPhotoButton(context),
          const SizedBox(height: 24),

          // Validation status
          _buildValidationStatus(),
          const SizedBox(height: 24),

          // Next action info
          _buildNextActionCard(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.receipt_long, color: Colors.orange, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.deliveryNoteTitle,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Photos du bon de livraison',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                AppStrings.minDeliveryNotePhotos,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.deliveryNoteInstruction,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Assurez-vous que le document est lisible\n'
            '• Photographiez toutes les pages si nécessaire\n'
            '• Incluez les signatures et tampons',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection(BuildContext context) {
    if (photos.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.note_add,
                size: 64,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.noPhotos,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Photographiez le bon de livraison',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return _buildPhotoCard(context, photo, index);
      },
    );
  }

  Widget _buildPhotoCard(BuildContext context, InterventionPhoto photo, int index) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Photo
          if (photo.localPath != null)
            Image.file(
              File(photo.localPath!),
              fit: BoxFit.cover,
            )
          else
            Image.network(
              photo.filePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: Icon(Icons.broken_image, color: AppColors.textHint),
                );
              },
            ),

          // Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),

          // Page number
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Page ${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          // Delete button
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _deletePhoto(context, photo),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _showPhotoSourceDialog(context),
      icon: const Icon(Icons.add_a_photo),
      label: Text(
        photos.isEmpty
            ? 'Photographier le bon de livraison'
            : 'Ajouter une page',
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
      ),
    );
  }

  Widget _buildValidationStatus() {
    final isValid = photos.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isValid ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValid ? AppColors.success : AppColors.warning,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.warning_amber,
            color: isValid ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isValid ? 'Photos du bon de livraison ajoutées' : 'Photos requises',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isValid ? AppColors.success : AppColors.warning,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${photos.length} page${photos.length > 1 ? 's' : ''} photographiée${photos.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextActionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.arrow_forward, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prochaine étape',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Retour aux observations techniques',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPhotoSourceDialog(BuildContext context) {
    // CRITICAL: Capture parent context BEFORE opening bottom sheet
    final parentContext = context;

    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text(AppStrings.takePhoto),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                // Use parent context, not bottom sheet context
                _takePhoto(parentContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text(AppStrings.selectFromGallery),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                // Use parent context, not bottom sheet context
                _pickFromGallery(parentContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto(BuildContext context) async {
    try {
      final photoService = getIt<PhotoService>();
      final result = await photoService.takePhoto();
      if (result != null && context.mounted) {
        context.read<WorkflowBloc>().add(AddPhotoWithContext(
              localPath: result.path,
              photoType: 'delivery_note',
              photoContext: 'delivery_note',
              latitude: result.latitude,
              longitude: result.longitude,
            ));
      }
    } on PhotoPermissionException catch (e) {
      if (!context.mounted) return;
      await PermissionUtils.showSettingsDialog(
        context,
        permissionLabel: e.permissionLabel,
        reason: e.reason,
      );
    }
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    try {
      final photoService = getIt<PhotoService>();
      final result = await photoService.pickFromGallery();
      if (result != null && context.mounted) {
        context.read<WorkflowBloc>().add(AddPhotoWithContext(
              localPath: result.path,
              photoType: 'delivery_note',
              photoContext: 'delivery_note',
              latitude: result.latitude,
              longitude: result.longitude,
            ));
      }
    } on PhotoPermissionException catch (e) {
      if (!context.mounted) return;
      await PermissionUtils.showSettingsDialog(
        context,
        permissionLabel: e.permissionLabel,
        reason: e.reason,
      );
    }
  }

  void _deletePhoto(BuildContext context, InterventionPhoto photo) {
    if (photo.id == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer la photo ?'),
        content: const Text(AppStrings.confirmDeletePhoto),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<WorkflowBloc>().add(
                RemovePhoto(
                  photoId: photo.id!,
                  photoType: 'delivery_note',
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );
  }
}
