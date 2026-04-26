import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

/// Technical Observations Step - Conditional branching decision point
/// 4 choices:
/// - Travaux supplémentaires réalisés (additional_work)
/// - BON DE LIVRAISON (delivery_note)
/// - Devis à faire (quote)
/// - Finir l'intervention (finish)
class TechnicalObservationsStep extends StatefulWidget {
  final String? selectedChoice;
  final List<String> completedBranches;
  final int loopCount;
  final Function(String) onSelect;

  const TechnicalObservationsStep({
    super.key,
    required this.selectedChoice,
    required this.completedBranches,
    required this.loopCount,
    required this.onSelect,
  });

  @override
  State<TechnicalObservationsStep> createState() => _TechnicalObservationsStepState();
}

class _TechnicalObservationsStepState extends State<TechnicalObservationsStep> {
  String? _selectedChoice;

  @override
  void initState() {
    super.initState();
    _selectedChoice = widget.selectedChoice;
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

          // Completed branches indicator
          if (widget.completedBranches.isNotEmpty) ...[
            _buildCompletedBranchesCard(),
            const SizedBox(height: 24),
          ],

          // Choice cards
          _buildChoiceCard(
            choice: 'additional_work',
            icon: Icons.build,
            title: AppStrings.techObsAdditionalWork,
            description: 'Des travaux supplémentaires ont été effectués et doivent être documentés',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),

          _buildChoiceCard(
            choice: 'delivery_note',
            icon: Icons.receipt_long,
            title: AppStrings.techObsDeliveryNote,
            description: 'Un bon de livraison doit être photographié',
            color: Colors.orange,
          ),
          const SizedBox(height: 12),

          _buildChoiceCard(
            choice: 'quote',
            icon: Icons.request_quote,
            title: AppStrings.techObsQuote,
            description: 'Un devis doit être établi pour des travaux futurs',
            color: Colors.purple,
          ),
          const SizedBox(height: 12),

          _buildChoiceCard(
            choice: 'finish',
            icon: Icons.check_circle,
            title: AppStrings.techObsFinish,
            description: 'Terminer l\'intervention avec la signature du technicien',
            color: Colors.green,
          ),

          const SizedBox(height: 24),

          // Info card
          _buildInfoCard(),
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
            Icon(Icons.assignment, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppStrings.technicalObservationsTitle,
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
          AppStrings.technicalObservationsInstruction,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedBranchesCard() {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppStrings.completedBranches,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.completedBranches.map((branch) {
                return Chip(
                  avatar: Icon(
                    _getBranchIcon(branch),
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    _getBranchLabel(branch),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: AppColors.success,
                );
              }).toList(),
            ),
            if (widget.loopCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${AppStrings.loopCounter}: ${widget.loopCount}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required String choice,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    final isSelected = _selectedChoice == choice;
    final isCompleted = widget.completedBranches.contains(choice);

    return Card(
      elevation: isSelected ? 8 : 2,
      color: isSelected ? color.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedChoice = choice;
          });
          widget.onSelect(choice);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Radio button
              Radio<String>(
                value: choice,
                groupValue: _selectedChoice,
                onChanged: (value) {
                  setState(() {
                    _selectedChoice = value;
                  });
                  if (value != null) {
                    widget.onSelect(value);
                  }
                },
                activeColor: color,
              ),

              const SizedBox(width: 8),

              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : color,
                  size: 28,
                ),
              ),

              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? color : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isCompleted)
                          Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Selection indicator
              if (isSelected)
                Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Navigation flexible',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vous pouvez compléter plusieurs branches avant de terminer l\'intervention. Sélectionnez une option et suivez les étapes.',
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

  IconData _getBranchIcon(String branch) {
    switch (branch) {
      case 'additional_work':
        return Icons.build;
      case 'delivery_note':
        return Icons.receipt_long;
      case 'quote':
        return Icons.request_quote;
      default:
        return Icons.check;
    }
  }

  String _getBranchLabel(String branch) {
    switch (branch) {
      case 'additional_work':
        return 'Travaux supp.';
      case 'delivery_note':
        return 'Bon livraison';
      case 'quote':
        return 'Devis';
      default:
        return branch;
    }
  }
}
