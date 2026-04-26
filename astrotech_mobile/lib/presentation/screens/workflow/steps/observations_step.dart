import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../blocs/workflow/workflow_bloc.dart';
import '../../../widgets/signature_pad.dart';

/// Observations Step - Combined step for Solitech workflow
/// Includes: Client observations + Rating (1-5 stars) + Client signature
class ObservationsStep extends StatefulWidget {
  final String observations;
  final int? rating;
  final bool hasSignature;
  final Function(String) onSaveObservations;
  final Function(int) onSaveRating;
  final Function(Uint8List) onSaveSignature;

  const ObservationsStep({
    super.key,
    required this.observations,
    required this.rating,
    required this.hasSignature,
    required this.onSaveObservations,
    required this.onSaveRating,
    required this.onSaveSignature,
  });

  @override
  State<ObservationsStep> createState() => _ObservationsStepState();
}

class _ObservationsStepState extends State<ObservationsStep> {
  late TextEditingController _observationsController;
  int? _selectedRating;
  bool _showSignaturePad = false;

  @override
  void initState() {
    super.initState();
    _observationsController = TextEditingController(text: widget.observations);
    _selectedRating = widget.rating;
  }

  @override
  void dispose() {
    _observationsController.dispose();
    super.dispose();
  }

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

          // Section 1: Client Observations
          _buildObservationsSection(),
          const SizedBox(height: 24),

          // Section 2: Rating
          _buildRatingSection(),
          const SizedBox(height: 24),

          // Section 3: Client Signature
          _buildSignatureSection(),
          const SizedBox(height: 16),

          // Completion indicator
          _buildCompletionIndicator(),
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
            Icon(Icons.rate_review, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppStrings.observationsTitle,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Recueillez les observations, la notation et la signature du client',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildObservationsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.comment, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppStrings.clientObservations,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_observationsController.text.trim().isNotEmpty)
                  Icon(Icons.check_circle, color: AppColors.success, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _observationsController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: AppStrings.clientObservationsPlaceholder,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                // Auto-save as user types
                widget.onSaveObservations(value);
              },
            ),
            const SizedBox(height: 8),
            // Quick suggestion button
            TextButton.icon(
              onPressed: () {
                _observationsController.text = AppStrings.clientObservationsPlaceholder;
                widget.onSaveObservations(_observationsController.text);
                setState(() {});
              },
              icon: const Icon(Icons.lightbulb_outline, size: 16),
              label: Text(
                'Suggestion: "${AppStrings.clientObservationsPlaceholder}"',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppStrings.clientRating,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_selectedRating != null)
                  Icon(Icons.check_circle, color: AppColors.success, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.ratingInstruction,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            // Star rating
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  final isSelected = _selectedRating != null && starValue <= _selectedRating!;
                  final isHovered = _selectedRating == null && starValue <= (index + 1);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRating = starValue;
                      });
                      widget.onSaveRating(starValue);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        isSelected ? Icons.star : Icons.star_border,
                        size: 48,
                        color: isSelected ? AppColors.warning : Colors.grey[400],
                      ),
                    ),
                  );
                }),
              ),
            ),
            if (_selectedRating != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '$_selectedRating / 5 étoiles',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.draw, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppStrings.clientSignature,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (widget.hasSignature)
                  Icon(Icons.check_circle, color: AppColors.success, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.clientSignatureInstruction,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            if (!widget.hasSignature)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showSignaturePad = true;
                  });
                  _showSignatureDialog(context);
                },
                icon: const Icon(Icons.edit),
                label: const Text('Signer'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Signature du client enregistrée',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _showSignatureDialog(context);
                      },
                      child: const Text('Modifier'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionIndicator() {
    final hasObservations = _observationsController.text.trim().isNotEmpty;
    final hasRating = _selectedRating != null;
    final hasSignature = widget.hasSignature;

    final completedCount = [hasObservations, hasRating, hasSignature].where((e) => e).length;
    final isComplete = completedCount == 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isComplete ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isComplete ? AppColors.success : AppColors.warning,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.info,
            color: isComplete ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isComplete ? 'Étape complète' : 'Étape incomplète',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isComplete ? AppColors.success : AppColors.warning,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completedCount / 3 sections complétées',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isComplete)
            const Icon(Icons.thumb_up, color: AppColors.success),
        ],
      ),
    );
  }

  void _showSignatureDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    AppStrings.clientSignature,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.signatureInstruction,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              // Signature pad
              SignaturePad(
                onSave: (bytes) {
                  widget.onSaveSignature(bytes);
                  Navigator.pop(dialogContext);
                  setState(() {});
                },
                onClear: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
