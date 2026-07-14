import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'pressable_scale.dart';

/// KOR glass surface: translucent white fill + 1px hairline border.
///
/// Default radius 20 (hero cards pass 22-24), default padding 16 (heroes
/// 18-20). Tinted variants ([GlassCard.coral], [GlassCard.amber]) are for
/// hero/status containers only — amber strictly for streak/timer/winner
/// contexts per the KOR spec.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color fill;
  final Color border;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.radius = 20,
    this.padding = const EdgeInsets.all(16),
    this.fill = AppColors.surfaceGlass,
    this.border = AppColors.glassBorder,
    this.onTap,
  });

  const GlassCard.coral({
    super.key,
    required this.child,
    this.radius = 22,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  })  : fill = AppColors.coralTint,
        border = AppColors.coralBorder;

  const GlassCard.amber({
    super.key,
    required this.child,
    this.radius = 22,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  })  : fill = AppColors.amberTint,
        border = AppColors.amberBorder;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
      ),
      child: child,
    );
    return PressableScale(onTap: onTap, child: card);
  }
}
