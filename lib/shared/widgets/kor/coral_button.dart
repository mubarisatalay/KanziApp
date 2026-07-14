import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'pressable_scale.dart';

/// Flat coral primary action. Heights per spec: 54 hero (login/submit),
/// 42-48 inline ("Gönder"). Pressed = darken ~8%, no elevation shift.
class CoralButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final bool expanded;
  final bool loading;

  const CoralButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 48,
    this.expanded = true,
    this.loading = false,
  });

  /// Compact inline variant (e.g. the 42px "Gönder" inside the hero card).
  const CoralButton.inline({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 42,
    this.loading = false,
  }) : expanded = false;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final button = PressableScale(
      onTap: enabled ? onPressed : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.55,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: height,
          padding: expanded
              ? null
              : const EdgeInsets.symmetric(horizontal: 22),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(height >= 52 ? 16 : 13),
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.onPrimary,
                  ),
                )
              : Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: height >= 52 ? 15.5 : 14,
                      ),
                ),
        ),
      ),
    );
    return expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
