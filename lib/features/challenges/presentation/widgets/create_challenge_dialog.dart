import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/challenge.dart';
import '../providers/challenge_provider.dart';

/// Dialog for creating a new challenge (admin only)
class CreateChallengeDialog extends ConsumerStatefulWidget {
  final String roomId;

  const CreateChallengeDialog({super.key, required this.roomId});

  @override
  ConsumerState<CreateChallengeDialog> createState() =>
      _CreateChallengeDialogState();
}

class _CreateChallengeDialogState extends ConsumerState<CreateChallengeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  ChallengeType _selectedType = ChallengeType.photoText;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(challengeActionsProvider).createChallenge(
            roomId: widget.roomId,
            challengeText: _textController.text,
            challengeType: _selectedType,
            challengeDate: _selectedDate,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Challenge created!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.emoji_events_outlined,
                color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          const Text('Create Challenge'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),

              // Challenge text
              TextFormField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Challenge Text',
                  hintText: 'e.g., Take a photo of something blue',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
                enabled: !_isLoading,
                maxLines: 3,
                maxLength: 300,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Challenge text is required';
                  }
                  if (value.trim().length < 5) {
                    return 'Challenge must be at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Challenge type
              Text(
                'Response Type',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SegmentedButton<ChallengeType>(
                segments: ChallengeType.values.map((type) {
                  return ButtonSegment<ChallengeType>(
                    value: type,
                    label: Text(type.label),
                    icon: Icon(_typeIcon(type)),
                  );
                }).toList(),
                selected: {_selectedType},
                onSelectionChanged: _isLoading
                    ? null
                    : (selected) {
                        setState(() => _selectedType = selected.first);
                      },
              ),
              const SizedBox(height: 16),

              // Date picker
              Text(
                'Challenge Date',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _isLoading ? null : _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 20, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        isToday
                            ? 'Today'
                            : '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down,
                          color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _create,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  IconData _typeIcon(ChallengeType type) {
    switch (type) {
      case ChallengeType.photo:
        return Icons.photo_camera_outlined;
      case ChallengeType.text:
        return Icons.text_fields;
      case ChallengeType.photoText:
        return Icons.photo_library_outlined;
    }
  }
}
