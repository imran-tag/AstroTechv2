import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

class CommentStep extends StatefulWidget {
  final String initialComment;
  final Function(String) onSave;

  const CommentStep({
    super.key,
    required this.initialComment,
    required this.onSave,
  });

  @override
  State<CommentStep> createState() => _CommentStepState();
}

class _CommentStepState extends State<CommentStep> {
  late TextEditingController _controller;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialComment);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasChanges = _controller.text != widget.initialComment;
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  void _saveComment() {
    widget.onSave(_controller.text);
    setState(() {
      _hasChanges = false;
    });
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Commentaire sauvegardé'),
        duration: Duration(seconds: 1),
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
            color: AppColors.info.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_note,
                    color: AppColors.info,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.comment,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Décrivez le travail effectué et les observations importantes.',
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

          // Comment text field
          TextField(
            controller: _controller,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: AppStrings.commentPlaceholder,
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textInputAction: TextInputAction.newline,
          ),

          const SizedBox(height: 16),

          // Character count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_controller.text.length} caractères',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              if (_hasChanges)
                TextButton.icon(
                  onPressed: _saveComment,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Sauvegarder'),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Suggestions
          Text(
            'Suggestions:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SuggestionChip(
                text: 'Travail effectué selon les normes',
                onTap: () {
                  _controller.text += '\n- Travail effectué selon les normes';
                  _controller.selection = TextSelection.collapsed(
                    offset: _controller.text.length,
                  );
                },
              ),
              _SuggestionChip(
                text: 'RAS (Rien à signaler)',
                onTap: () {
                  _controller.text += '\n- RAS';
                  _controller.selection = TextSelection.collapsed(
                    offset: _controller.text.length,
                  );
                },
              ),
              _SuggestionChip(
                text: 'Pièce remplacée',
                onTap: () {
                  _controller.text += '\n- Pièce remplacée: ';
                  _controller.selection = TextSelection.collapsed(
                    offset: _controller.text.length,
                  );
                },
              ),
              _SuggestionChip(
                text: 'Intervention reportée',
                onTap: () {
                  _controller.text += '\n- Intervention reportée: ';
                  _controller.selection = TextSelection.collapsed(
                    offset: _controller.text.length,
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Completion status
          if (_controller.text.trim().isNotEmpty)
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
                    'Commentaire ajouté',
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

class _SuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
