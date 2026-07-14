import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/kor/kor.dart';
import '../providers/room_provider.dart';
import 'create_room_dialog.dart' show KorDialogField;

/// Join-room dialog — KOR dark surface, mono invite-code field.
class JoinRoomDialog extends ConsumerStatefulWidget {
  const JoinRoomDialog({super.key});

  @override
  ConsumerState<JoinRoomDialog> createState() => _JoinRoomDialogState();
}

class _JoinRoomDialogState extends ConsumerState<JoinRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final room =
          await ref.read(roomActionsProvider).joinRoom(_codeController.text);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context).joinedRoom(room.name))),
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
              Text(l10n.joinRoomTitle,
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
                label: l10n.labelInviteCodeUpper,
                controller: _codeController,
                enabled: !_isLoading,
                maxLength: 6,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                style: AppTheme.mono(
                  fontSize: 19,
                  letterSpacing: 5,
                  color: AppColors.primaryText,
                ),
                onFieldSubmitted: (_) => _joinRoom(),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return l10n.inviteCodeRequired;
                  if (v.length != 6) return l10n.inviteCodeLength;
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                l10n.inviteCodeHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
              ),
              const SizedBox(height: 20),
              CoralButton(
                label: l10n.join,
                loading: _isLoading,
                onPressed: _isLoading ? null : _joinRoom,
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
