import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'pressable_scale.dart';

/// 38px glass square used for back chevrons and overflow menus in headers.
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceGlass,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(icon, size: 19, color: AppColors.textPrimary),
      ),
    );
  }
}
