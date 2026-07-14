import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// KOR segmented control: glass track (radius 14, 4px inner padding), active
/// segment a flat coral pill with dark text.
class SegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selectedIndex
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    labels[i],
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: i == selectedIndex
                              ? AppColors.onPrimary
                              : AppColors.textTertiary,
                        ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
