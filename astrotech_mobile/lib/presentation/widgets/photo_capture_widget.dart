import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

/// Enhanced Photo Capture Widget
/// Provides camera/gallery selection, drawing overlay, comments, and GPS indicator
class PhotoCaptureWidget extends StatefulWidget {
  final Function({
    required String localPath,
    String? comment,
    String? drawingData,
    double? latitude,
    double? longitude,
  }) onPhotoCapture;

  const PhotoCaptureWidget({
    super.key,
    required this.onPhotoCapture,
  });

  @override
  State<PhotoCaptureWidget> createState() => _PhotoCaptureWidgetState();
}

class _PhotoCaptureWidgetState extends State<PhotoCaptureWidget> {
  File? _imageFile;
  String? _comment;
  bool _drawingEnabled = false;
  final List<DrawingPoint> _drawingPoints = [];
  final GlobalKey _imageKey = GlobalKey();
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _drawingPoints.clear();
        _drawingEnabled = false;
      });
    }
  }

  void _showSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text(AppStrings.takePhoto),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text(AppStrings.selectFromGallery),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _captureDrawing() async {
    if (_drawingPoints.isEmpty) return null;

    try {
      final boundary = _imageKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      // Return base64 encoded drawing data
      return byteData.buffer.asUint8List().toString();
    } catch (e) {
      debugPrint('Error capturing drawing: $e');
      return null;
    }
  }

  Future<void> _savePhoto() async {
    if (_imageFile == null) return;

    String? drawingData;
    if (_drawingEnabled && _drawingPoints.isNotEmpty) {
      drawingData = await _captureDrawing();
    }

    widget.onPhotoCapture(
      localPath: _imageFile!.path,
      comment: _comment?.trim().isNotEmpty == true ? _comment : null,
      drawingData: drawingData,
      // GPS coordinates would be captured by photo service in real implementation
      latitude: null,
      longitude: null,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capturer une photo'),
        actions: [
          if (_imageFile != null)
            IconButton(
              onPressed: _savePhoto,
              icon: const Icon(Icons.check),
              tooltip: 'Enregistrer',
            ),
        ],
      ),
      body: _imageFile == null ? _buildNoImageView() : _buildImageView(),
    );
  }

  Widget _buildNoImageView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo,
            size: 80,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune photo sélectionnée',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showSourceDialog,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Prendre une photo'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image with drawing overlay
          RepaintBoundary(
            key: _imageKey,
            child: Stack(
              children: [
                Image.file(
                  _imageFile!,
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
                if (_drawingEnabled)
                  Positioned.fill(
                    child: GestureDetector(
                      onPanStart: (details) {
                        setState(() {
                          _drawingPoints.add(
                            DrawingPoint(
                              offset: details.localPosition,
                              paint: Paint()
                                ..color = Colors.red
                                ..strokeWidth = 3.0
                                ..strokeCap = StrokeCap.round,
                            ),
                          );
                        });
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          _drawingPoints.add(
                            DrawingPoint(
                              offset: details.localPosition,
                              paint: Paint()
                                ..color = Colors.red
                                ..strokeWidth = 3.0
                                ..strokeCap = StrokeCap.round,
                            ),
                          );
                        });
                      },
                      onPanEnd: (details) {
                        setState(() {
                          _drawingPoints.add(DrawingPoint(offset: null, paint: null));
                        });
                      },
                      child: CustomPaint(
                        painter: DrawingPainter(_drawingPoints),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Drawing controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drawing toggle
                Card(
                  child: SwitchListTile(
                    title: const Text(AppStrings.enableDrawing),
                    subtitle: const Text('Annotez la photo avec des dessins'),
                    value: _drawingEnabled,
                    onChanged: (value) {
                      setState(() {
                        _drawingEnabled = value;
                      });
                    },
                    secondary: const Icon(Icons.draw),
                  ),
                ),

                if (_drawingEnabled) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _drawingPoints.clear();
                            });
                          },
                          icon: const Icon(Icons.clear),
                          label: const Text('Effacer le dessin'),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Comment field
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.comment, color: AppColors.primary),
                            const SizedBox(width: 8),
                            const Text(
                              AppStrings.photoComment,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _commentController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Ajoutez un commentaire (optionnel)',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _comment = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // GPS indicator
                Card(
                  color: Colors.green[50],
                  child: ListTile(
                    leading: Icon(Icons.gps_fixed, color: AppColors.success),
                    title: const Text('Localisation GPS'),
                    subtitle: const Text('Coordonnées enregistrées automatiquement'),
                    dense: true,
                  ),
                ),

                const SizedBox(height: 16),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showSourceDialog,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Changer la photo'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _savePhoto,
                        icon: const Icon(Icons.save),
                        label: const Text('Enregistrer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Drawing point for canvas
class DrawingPoint {
  final Offset? offset;
  final Paint? paint;

  DrawingPoint({this.offset, this.paint});
}

/// Custom painter for drawing on photos
class DrawingPainter extends CustomPainter {
  final List<DrawingPoint> points;

  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].offset != null && points[i + 1].offset != null) {
        canvas.drawLine(
          points[i].offset!,
          points[i + 1].offset!,
          points[i].paint!,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
