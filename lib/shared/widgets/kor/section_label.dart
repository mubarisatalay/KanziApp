import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// KOR section label: 12 / 700 / +1.6 letter-spacing / tertiary.
/// Pass PRE-UPPERCASED text (the l10n `...Upper` keys) — Dart's toUpperCase
/// is not locale-aware and breaks the Turkish dotted İ, so casing lives in
/// the ARB files, not here.
class SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w700,
          ),
    );
    if (trailing == null) return label;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [label, trailing!],
    );
  }
}
