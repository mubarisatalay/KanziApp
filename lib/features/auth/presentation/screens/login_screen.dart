import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/kor/kor.dart';
import '../providers/auth_provider.dart';

/// Login / sign-up — KOR design "2a Login".
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _showConfirmationBanner = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref.read(authActionsProvider).clearError();
    setState(() => _showConfirmationBanner = false);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      if (_isSignUp) {
        final emailConfirmationRequired =
            await ref.read(authActionsProvider).signUp(
                  email: _emailController.text.trim(),
                  password: _passwordController.text,
                  username: _usernameController.text.trim(),
                );

        if (mounted && emailConfirmationRequired) {
          setState(() {
            _showConfirmationBanner = true;
            _isSignUp = false;
          });
          _passwordController.clear();
          return;
        }
      } else {
        await ref.read(authActionsProvider).signIn(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
      }
    } catch (e) {
      // Error is handled by provider
    }
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _showConfirmationBanner = false;
    });
    _formKey.currentState?.reset();
    ref.read(authActionsProvider).clearError();
  }

  Future<void> _resendConfirmation() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    try {
      await ref.read(authActionsProvider).resendConfirmationEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).resendEmailSent)),
        );
      }
    } catch (_) {
      // Error shown by provider
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authLoadingProvider);
    final errorMessage = ref.watch(authErrorProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const KorWordmark(size: 44),
                const SizedBox(height: 14),
                Text(
                  l10n.tagline,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 36),

                if (_showConfirmationBanner) ...[
                  GlassCard.amber(
                    radius: 16,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.accountCreatedVerify,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: isLoading ? null : _resendConfirmation,
                            child: Text(
                              l10n.resendEmail,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (errorMessage != null) ...[
                  GlassCard.coral(
                    radius: 16,
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      errorMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (_isSignUp) ...[
                        _KorField(
                          label: l10n.labelUsernameUpper,
                          controller: _usernameController,
                          validator: Validators.validateUsername,
                          enabled: !isLoading,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                      ],
                      _KorField(
                        label: l10n.labelEmailUpper,
                        controller: _emailController,
                        validator: Validators.validateEmail,
                        enabled: !isLoading,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      _KorField(
                        label: l10n.labelPasswordUpper,
                        controller: _passwordController,
                        validator: Validators.validatePassword,
                        enabled: !isLoading,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        trailing: GestureDetector(
                          onTap: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          child: Text(
                            _obscurePassword ? l10n.show : l10n.hide,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textTertiary,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      CoralButton(
                        label: _isSignUp ? l10n.signUp : l10n.signIn,
                        height: 54,
                        loading: isLoading,
                        onPressed: isLoading ? null : _submit,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),
                Center(
                  child: GestureDetector(
                    onTap: isLoading ? null : _toggleMode,
                    child: Text.rich(
                      TextSpan(
                        text: _isSignUp
                            ? l10n.haveAccountPrompt
                            : l10n.noAccountPrompt,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        children: [
                          TextSpan(
                            text: _isSignUp ? l10n.signIn : l10n.signUp,
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    l10n.forgotPassword,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textFaint,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// KOR input: glass container, 16 radius, tiny label above the value.
/// [label] must be pre-uppercased (l10n `...Upper` keys) — see SectionLabel.
class _KorField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? trailing;

  const _KorField({
    required this.label,
    required this.controller,
    this.validator,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10.5,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary.withAlpha(102), // 40%
                      ),
                ),
                TextFormField(
                  controller: controller,
                  validator: validator,
                  enabled: enabled,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  onFieldSubmitted: onFieldSubmitted,
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
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}
