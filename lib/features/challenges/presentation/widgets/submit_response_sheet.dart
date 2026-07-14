import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/kor/kor.dart';
import '../../domain/entities/challenge.dart';
import '../providers/challenge_provider.dart';

/// Submit-response sheet — KOR dark surface, glass fields, coral CTA.
class SubmitResponseSheet extends ConsumerStatefulWidget {
  final Challenge challenge;

  const SubmitResponseSheet({super.key, required this.challenge});

  @override
  ConsumerState<SubmitResponseSheet> createState() =>
      _SubmitResponseSheetState();
}

class _SubmitResponseSheetState extends ConsumerState<SubmitResponseSheet> {
  final _textController = TextEditingController();
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImage = picked;
          _selectedImageBytes = bytes;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context).pickImageFailed;
        });
      }
    }
  }

  void _showImageSourcePicker() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _SourceRow(
                icon: Icons.camera_alt_outlined,
                label: l10n.takePhoto,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 10),
              _SourceRow(
                icon: Icons.photo_library_outlined,
                label: l10n.chooseFromGallery,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final type = widget.challenge.challengeType;

    if (type.requiresPhoto && _selectedImage == null) {
      setState(() => _error = l10n.photoRequiredError);
      return;
    }

    if (type.requiresText && _textController.text.trim().isEmpty) {
      setState(() => _error = l10n.textRequiredError);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await ref.read(challengeActionsProvider).submitResponse(
            challengeId: widget.challenge.id,
            roomId: widget.challenge.roomId,
            textContent: _textController.text.trim().isEmpty
                ? null
                : _textController.text.trim(),
            image: _selectedImage,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.submittedToast)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = widget.challenge.challengeType;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            Text(l10n.submitSheetTitle,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),

            // Challenge reminder.
            GlassCard.coral(
              radius: 16,
              padding: const EdgeInsets.all(14),
              child: Text(
                widget.challenge.challengeText,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: AppColors.primaryText, height: 1.35),
              ),
            ),
            const SizedBox(height: 14),

            if (_error != null) ...[
              GlassCard.coral(
                radius: 14,
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Photo picker.
            if (type.requiresPhoto) ...[
              SectionLabel(type == ChallengeType.photo
                  ? l10n.labelPhotoUpper
                  : l10n.labelPhotoRequiredUpper),
              const SizedBox(height: 8),
              if (_selectedImage != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        _selectedImageBytes!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedImage = null;
                          _selectedImageBytes = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: AppColors.textPrimary,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                PressableScale(
                  onTap: _isSubmitting ? null : _showImageSourcePicker,
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceGlass,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_a_photo_outlined,
                          size: 30,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.choosePhoto,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 14),
            ],

            // Text input (required for text types, caption for photo-only).
            if (type.requiresText || type == ChallengeType.photo) ...[
              SectionLabel(type.requiresText
                  ? l10n.labelYourAnswerUpper
                  : l10n.labelCaptionOptionalUpper),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceGlass,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: TextField(
                  controller: _textController,
                  enabled: !_isSubmitting,
                  maxLines: type.requiresText ? 4 : 2,
                  maxLength: type.requiresText ? 500 : 200,
                  cursorColor: AppColors.primary,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText:
                        type.requiresText ? l10n.answerHint : l10n.captionHint,
                    counterText: '',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(height: 14),
            ],

            const SizedBox(height: 6),
            CoralButton(
              label: l10n.send,
              height: 54,
              loading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 16,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryText),
          const SizedBox(width: 12),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const Spacer(),
          const Icon(Icons.chevron_right,
              size: 20, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}
