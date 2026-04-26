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

/// Additional Work Photos Step
/// Second step in the additional work branch - capture photos of the extra work
class AdditionalWorkPhotosStep extends StatelessWidget {
  final List<InterventionPhoto> photos;
  final int interventionId;

  const AdditionalWorkPhotosStep({
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
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.photo_camera, color: Colors.blue, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.additionalWorkPhotos,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Étape 2/3 - Photos',
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
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.minAdditionalWorkPhotos,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Photographiez les travaux supplémentaires réalisés',
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

  Widget _buildPhotosSection(BuildContext context) {
    if (photos.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.add_photo_alternate,
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
                'Ajoutez au moins 1 photo',
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
        childAspectRatio: 1,
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

          // Overlay with index
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${index + 1}',
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
      label: const Text(AppStrings.takePhoto),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
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
                  isValid ? 'Photos ajoutées' : 'Photos requises',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isValid ? AppColors.success : AppColors.warning,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${photos.length} photo${photos.length > 1 ? 's' : ''} ${photos.length > 1 ? 'ajoutées' : 'ajoutée'}',
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
              photoType: 'additional_work',
              photoContext: 'additional_work',
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
              photoType: 'additional_work',
              photoContext: 'additional_work',
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
                  photoType: 'additional_work',
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
