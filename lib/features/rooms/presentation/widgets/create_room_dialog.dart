import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/kor/kor.dart';
import '../providers/room_provider.dart';

/// Create-room dialog — KOR dark surface, tiny-uppercase-label fields.
class CreateRoomDialog extends ConsumerStatefulWidget {
  const CreateRoomDialog({super.key});

  @override
  ConsumerState<CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends ConsumerState<CreateRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final room = await ref.read(roomActionsProvider).createRoom(
            name: _nameController.text,
            description: _descriptionController.text.isEmpty
                ? null
                : _descriptionController.text,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context).roomCreated(room.name, room.code)),
            duration: const Duration(seconds: 4),
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
    final l10n = AppLocalizations.of(context);
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.newRoomTitle,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
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
              KorDialogField(
                label: l10n.labelRoomNameUpper,
                controller: _nameController,
                enabled: !_isLoading,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return l10n.roomNameRequired;
                  if (v.length < 2) return l10n.roomNameTooShort;
                  if (v.length > 50) return l10n.roomNameTooLong;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              KorDialogField(
                label: l10n.labelDescriptionOptionalUpper,
                controller: _descriptionController,
                enabled: !_isLoading,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),
              CoralButton(
                label: l10n.create,
                loading: _isLoading,
                onPressed: _isLoading ? null : _createRoom,
              ),
              const SizedBox(height: 10),
              Center(
                child: GestureDetector(
                  onTap: _isLoading ? null : () => Navigator.pop(context),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      l10n.cancel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared KOR dialog field: glass container, tiny label above value.
/// [label] must be pre-uppercased (l10n `...Upper` keys) — Dart's toUpperCase
/// breaks the Turkish dotted İ, so casing lives in the ARB files.
class KorDialogField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final int maxLines;
  final int? maxLength;
  final TextStyle? style;
  final TextAlign textAlign;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  const KorDialogField({
    super.key,
    required this.label,
    required this.controller,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.style,
    this.textAlign = TextAlign.start,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10.5,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary.withAlpha(102),
                ),
          ),
          TextFormField(
            controller: controller,
            enabled: enabled,
            maxLines: maxLines,
            maxLength: maxLength,
            textAlign: textAlign,
            textInputAction: textInputAction,
            textCapitalization: textCapitalization,
            validator: validator,
            onFieldSubmitted: onFieldSubmitted,
            style: style ?? Theme.of(context).textTheme.bodyLarge,
            cursorColor: AppColors.primary,
            decoration: const InputDecoration(
              isDense: true,
              filled: false,
              counterText: '',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 4, bottom: 8),
            ),
          ),
        ],
      ),
    );
  }
}
