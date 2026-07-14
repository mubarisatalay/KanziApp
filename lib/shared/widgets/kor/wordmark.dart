import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

/// The `kanzi.` wordmark: lowercase, 800 weight, tight tracking, coral dot.
class KorWordmark extends StatelessWidget {
  final double size;

  const KorWordmark({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.bricolageGrotesque(
      fontSize: size,
      fontWeight: FontWeight.w800,
      // -0.8 at 24px per spec, scaled proportionally.
      letterSpacing: -0.8 * (size / 24),
      color: AppColors.textPrimary,
      height: 1,
    );
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: 'kanzi', style: style),
        TextSpan(text: '.', style: style.copyWith(color: AppColors.primary)),
      ]),
    );
  }
}
