import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

/// Reusable signature pad widget
/// Used in observations step, technician signature, additional work signature, quote signature
class SignaturePad extends StatefulWidget {
  final Function(Uint8List) onSave;
  final VoidCallback onClear;
  final String? saveButtonText;
  final double height;

  const SignaturePad({
    super.key,
    required this.onSave,
    required this.onClear,
    this.saveButtonText,
    this.height = 300,
  });

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  late SignatureController _controller;
  bool _hasDrawn = false;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: AppColors.textPrimary,
      exportBackgroundColor: Colors.white,
      exportPenColor: Colors.black,
    );

    _controller.addListener(() {
      final isEmpty = _controller.isEmpty;
      if (_hasDrawn == isEmpty) {
        setState(() {
          _hasDrawn = !isEmpty;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearSignature() {
    _controller.clear();
    widget.onClear();
    setState(() {
      _hasDrawn = false;
    });
  }

  Future<void> _saveSignature() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.signatureRequired),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final bytes = await _controller.toPngBytes();
    if (bytes != null) {
      widget.onSave(bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Signature canvas
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hasDrawn
                  ? AppColors.primary
                  : AppColors.textHint.withOpacity(0.3),
              width: _hasDrawn ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Signature(
              controller: _controller,
              height: widget.height,
              backgroundColor: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _hasDrawn ? _clearSignature : null,
                icon: const Icon(Icons.clear),
                label: const Text(AppStrings.clearSignature),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _hasDrawn ? _saveSignature : null,
                icon: const Icon(Icons.check),
                label: Text(widget.saveButtonText ?? AppStrings.save),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
