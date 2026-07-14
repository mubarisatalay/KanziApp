import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/kor/kor.dart';
import '../../../auth/data/models/user_profile_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../rooms/presentation/providers/room_provider.dart';
import '../providers/profile_provider.dart';

/// Profile — KOR design "2a Profile".
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _startEditing() {
    final profile = ref.read(currentUserProfileProvider).value;
    if (profile != null) {
      _usernameController.text = profile.username;
      _displayNameController.text = profile.displayName ?? '';
    }
    setState(() {
      _isEditing = true;
      _error = null;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _error = null;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await ref.read(profileActionsProvider).updateProfile(
            username: _usernameController.text.trim(),
            displayName: _displayNameController.text.trim().isEmpty
                ? null
                : _displayNameController.text.trim(),
          );

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).profileUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSaving = false;
        });
      }
    }
  }

  String _memberSince(BuildContext context, DateTime createdAt) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final monthYear = DateFormat.yMMM(locale).format(createdAt.toLocal());
    return AppLocalizations.of(context).memberSince(monthYear);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final currentUser = ref.watch(currentUserProvider);
    final roomCount =
        ref.watch(userRoomsProvider).valueOrNull?.length;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row.
              Row(
                children: [
                  GlassIconButton(
                    icon: Icons.chevron_left,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(l10n.profileTitle,
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                  PressableScale(
                    onTap: _isSaving
                        ? null
                        : (_isEditing ? _cancelEditing : _startEditing),
                    child: Text(
                      _isEditing ? l10n.cancel : l10n.edit,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: _isEditing
                                ? AppColors.textTertiary
                                : AppColors.primaryText,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),

              profileAsync.when(
                data: (profile) {
                  if (profile == null) {
                    return Center(child: Text(l10n.profileNotFound));
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Identity block.
                      Center(
                        child: Column(
                          children: [
                            MonogramAvatar(
                              name: profile.displayName ?? profile.username,
                              size: 84,
                              tint: MonogramTint.coral,
                              ringColor: AppColors.coralBorder,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              profile.displayName ?? profile.username,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontSize: 21),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '@${profile.username} · '
                              '${_memberSince(context, profile.createdAt)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      fontSize: 12.5,
                                      color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Stat tiles.
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              value: roomCount?.toString() ?? '–',
                              label: l10n.statRoomsUpper,
                              valueColor: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatTile(
                              // Wins/streak land with the weekly-stats backend features.
                              value: '–',
                              label: l10n.statWinsUpper,
                              valueColor: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatTile(
                              value: '–',
                              label: l10n.statStreakUpper,
                              valueColor: AppColors.primaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (_isEditing)
                        _buildEditForm(context)
                      else
                        _buildInfoList(context, profile, currentUser),

                      const SizedBox(height: 28),
                      OutlinedButton(
                        onPressed: () async {
                          try {
                            await ref.read(authActionsProvider).signOut();
                          } catch (_) {}
                        },
                        child: Text(l10n.signOut),
                      ),
                    ],
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Column(
                    children: [
                      Text(l10n.profileLoadFailed(error.toString()),
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 12),
                      CoralButton.inline(
                        label: l10n.retry,
                        onPressed: () =>
                            ref.invalidate(currentUserProfileProvider),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoList(
    BuildContext context,
    UserProfileModel profile,
    UserProfileModel? currentUser,
  ) {
    final l10n = AppLocalizations.of(context);
    return GlassCard(
      radius: 16,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _InfoRow(
              label: l10n.labelDisplayNameUpper,
              value: profile.displayName ?? profile.username),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(),
          ),
          _InfoRow(
              label: l10n.labelUsernameUpper, value: '@${profile.username}'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(),
          ),
          _InfoRow(
              label: l10n.labelEmailUpper, value: currentUser?.email ?? '–'),
        ],
      ),
    );
  }

  Widget _buildEditForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          _EditField(
            label: AppLocalizations.of(context).labelDisplayNameUpper,
            controller: _displayNameController,
            enabled: !_isSaving,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          _EditField(
            label: AppLocalizations.of(context).labelUsernameUpper,
            controller: _usernameController,
            enabled: !_isSaving,
            validator: Validators.validateUsername,
          ),
          const SizedBox(height: 18),
          CoralButton(
            label: AppLocalizations.of(context).save,
            loading: _isSaving,
            onPressed: _isSaving ? null : _saveProfile,
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _StatTile({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 21,
                  color: valueColor,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 9.5,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10.5,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                ),
          ),
          const SizedBox(height: 3),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const _EditField({
    required this.label,
    required this.controller,
    this.enabled = true,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
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
            validator: validator,
            textCapitalization: textCapitalization,
            style: Theme.of(context).textTheme.bodyLarge,
            cursorColor: AppColors.primary,
            decoration: const InputDecoration(
              isDense: true,
              filled: false,
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
