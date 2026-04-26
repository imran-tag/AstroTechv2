import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/utils/logger.dart';

class PhotoPermissionException implements Exception {
  final String permissionLabel;
  final String reason;
  PhotoPermissionException({required this.permissionLabel, required this.reason});
}

class PhotoService {
  final ImagePicker _picker = ImagePicker();

  Future<PhotoResult?> takePhoto() async {
    try {
      Logger.photo('Attempting to take photo with camera...');

      var cameraStatus = await Permission.camera.status;
      Logger.photo('Camera permission status: $cameraStatus');

      if (cameraStatus.isPermanentlyDenied) {
        throw PhotoPermissionException(
          permissionLabel: 'l\'appareil photo',
          reason: 'L\'accès à l\'appareil photo est nécessaire pour photographier l\'intervention.',
        );
      }

      if (!cameraStatus.isGranted) {
        cameraStatus = await Permission.camera.request();
        Logger.photo('Camera permission after request: $cameraStatus');

        if (cameraStatus.isPermanentlyDenied) {
          throw PhotoPermissionException(
            permissionLabel: 'l\'appareil photo',
            reason: 'L\'accès à l\'appareil photo est nécessaire pour photographier l\'intervention.',
          );
        }

        if (!cameraStatus.isGranted) {
          Logger.warning('Camera permission not granted', 'PHOTO');
          return null;
        }
      }

      Logger.photo('Camera permission granted, opening camera');

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo == null) {
        Logger.photo('No photo captured');
        return null;
      }

      Logger.info('Photo captured: ${photo.path}', 'PHOTO');

      // Get location
      Position? position;
      try {
        Logger.photo('Getting GPS coordinates...');
        position = await _getCurrentPosition();
        if (position != null) {
          Logger.info('GPS coordinates: ${position.latitude}, ${position.longitude}', 'PHOTO');
        }
      } catch (e) {
        Logger.warning('Location not available: $e', 'PHOTO');
        // Location not available, continue without it
      }

      // Copy to app directory
      Logger.photo('Saving photo to app directory...');
      final savedPath = await _saveToAppDirectory(photo);

      Logger.info('Photo saved to: $savedPath', 'PHOTO');

      return PhotoResult(
        path: savedPath,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );
    } on PhotoPermissionException {
      rethrow;
    } catch (e, stackTrace) {
      Logger.error('Error taking photo: $e', e, stackTrace, 'PHOTO');
      return null;
    }
  }

  Future<PhotoResult?> pickFromGallery() async {
    try {
      Logger.photo('Attempting to pick photo from gallery...');

      // Check photo library permission status first
      PermissionStatus photosStatus;

      if (Platform.isAndroid) {
        photosStatus = await Permission.photos.status;
        if (!photosStatus.isGranted && !photosStatus.isLimited && !photosStatus.isPermanentlyDenied) {
          photosStatus = await Permission.photos.request();
          if (!photosStatus.isGranted && !photosStatus.isLimited && !photosStatus.isPermanentlyDenied) {
            photosStatus = await Permission.storage.request();
          }
        }
      } else {
        photosStatus = await Permission.photos.status;
        if (!photosStatus.isGranted && !photosStatus.isLimited && !photosStatus.isPermanentlyDenied) {
          photosStatus = await Permission.photos.request();
        }
      }

      Logger.photo('Photos permission status: $photosStatus');

      if (photosStatus.isPermanentlyDenied) {
        throw PhotoPermissionException(
          permissionLabel: 'la galerie photos',
          reason: 'L\'accès à la galerie est nécessaire pour sélectionner une photo.',
        );
      }

      if (!photosStatus.isGranted && !photosStatus.isLimited) {
        Logger.warning('Permission not granted', 'PHOTO');
        return null;
      }

      Logger.photo('Permission granted, opening gallery');

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo == null) {
        Logger.photo('No photo selected');
        return null;
      }

      Logger.info('Photo selected: ${photo.path}', 'PHOTO');

      // Copy to app directory
      final savedPath = await _saveToAppDirectory(photo);

      Logger.info('Photo saved to: $savedPath', 'PHOTO');

      return PhotoResult(
        path: savedPath,
        latitude: null,
        longitude: null,
      );
    } on PhotoPermissionException {
      rethrow;
    } catch (e, stackTrace) {
      Logger.error('Error picking from gallery: $e', e, stackTrace, 'PHOTO');
      return null;
    }
  }

  Future<Position?> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<String> _saveToAppDirectory(XFile photo) async {
    final directory = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${directory.path}/photos');

    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedPath = '${photosDir.path}/$fileName';

    await File(photo.path).copy(savedPath);

    return savedPath;
  }

  Future<void> deletePhoto(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore deletion errors
    }
  }
}

class PhotoResult {
  final String path;
  final double? latitude;
  final double? longitude;

  PhotoResult({
    required this.path,
    this.latitude,
    this.longitude,
  });
}
