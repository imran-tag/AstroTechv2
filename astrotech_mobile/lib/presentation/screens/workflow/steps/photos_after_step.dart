import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/permission_utils.dart';
import '../../../../domain/entities/intervention.dart';
import '../../../../injection_container.dart';
import '../../../../services/photo_service.dart';
import '../../../blocs/workflow/workflow_bloc.dart';

class PhotosAfterStep extends StatelessWidget {
  final List<InterventionPhoto> photos;
  final int interventionId;

  const PhotosAfterStep({
    super.key,
    required this.photos,
    required this.interventionId,
  });

  Future<void> _takePhoto(BuildContext context) async {
    try {
      final photoService = getIt<PhotoService>();
      final result = await photoService.takePhoto();
      if (result != null && context.mounted) {
        context.read<WorkflowBloc>().add(AddPhotoWithContext(
              localPath: result.path,
              photoType: 'after',
              photoContext: 'after',
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
              photoType: 'after',
              photoContext: 'after',
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

  void _showPhotoOptions(BuildContext context) {
    // Capture the parent context before opening bottom sheet
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

  void _showDeleteConfirmation(BuildContext context, InterventionPhoto photo) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.deletePhoto),
        content: const Text(AppStrings.confirmDeletePhoto),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (photo.id != null) {
                context.read<WorkflowBloc>().add(RemovePhoto(
                      photoId: photo.id!,
                      photoType: 'after',
                    ));
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Card(
            color: AppColors.success.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.camera_alt,
                    color: AppColors.success,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.photosAfter,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Prenez des photos du résultat après les travaux.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Add photo button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showPhotoOptions(context),
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Ajouter une photo'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Photo count
          Row(
            children: [
              Text(
                '${photos.length} photo${photos.length != 1 ? 's' : ''}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              if (photos.isEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  '(${AppStrings.minPhotosRequired})',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Photo grid
          if (photos.isEmpty)
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.textHint.withOpacity(0.3),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 48,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.noPhotos,
                      style: TextStyle(color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photo = photos[index];
                return _PhotoTile(
                  photo: photo,
                  onDelete: () => _showDeleteConfirmation(context, photo),
                );
              },
            ),

          const SizedBox(height: 16),

          // Success indicator
          if (photos.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 12),
                  Text(
                    'Photos ajoutées',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final InterventionPhoto photo;
  final VoidCallback onDelete;

  const _PhotoTile({
    required this.photo,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (photo.localPath != null) {
      imageWidget = Image.file(
        File(photo.localPath!),
        fit: BoxFit.cover,
      );
    } else {
      imageWidget = Container(
        color: AppColors.background,
        child: const Icon(Icons.image),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageWidget,
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            onPressed: onDelete,
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
            ),
            icon: const Icon(
              Icons.delete,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        if (photo.id == null)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'En attente',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
