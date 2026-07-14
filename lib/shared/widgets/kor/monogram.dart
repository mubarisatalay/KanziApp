import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

/// Which tint a monogram gets: coral 14% / amber 12-13% / white 7%.
enum MonogramTint { coral, amber, neutral }

Color _fillFor(MonogramTint tint) => switch (tint) {
      MonogramTint.coral => const Color(0x24FF6B4A),
      MonogramTint.amber => const Color(0x20F5A860),
      MonogramTint.neutral => const Color(0x12FFFFFF),
    };

Color _letterFor(MonogramTint tint) => switch (tint) {
      MonogramTint.coral => AppColors.primaryText,
      MonogramTint.amber => AppColors.accent,
      MonogramTint.neutral => AppColors.textSecondary,
    };

String _initialOf(String? name) {
  final trimmed = name?.trim() ?? '';
  return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
}

/// Circular monogram avatar: initial letter on a tinted disc. The KOR design
/// uses these everywhere a photo avatar would normally go — no image avatars.
class MonogramAvatar extends StatelessWidget {
  final String? name;
  final double size;
  final MonogramTint tint;

  /// Optional 2px ring (amber for winners, coral for profile, background-color
  /// rings for overlapping stacks).
  final Color? ringColor;

  const MonogramAvatar({
    super.key,
    required this.name,
    this.size = 34,
    this.tint = MonogramTint.neutral,
    this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _fillFor(tint),
        shape: BoxShape.circle,
        border: ringColor != null ? Border.all(color: ringColor!, width: 2) : null,
      ),
      child: Text(
        _initialOf(name),
        style: GoogleFonts.bricolageGrotesque(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: _letterFor(tint),
        ),
      ),
    );
  }
}

/// 44px rounded-14 monogram tile — the room icon. No emoji tiles per spec.
class MonogramTile extends StatelessWidget {
  final String? name;
  final double size;
  final MonogramTint tint;

  const MonogramTile({
    super.key,
    required this.name,
    this.size = 44,
    this.tint = MonogramTint.coral,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _fillFor(tint),
        borderRadius: BorderRadius.circular(size * 14 / 44),
      ),
      child: Text(
        _initialOf(name),
        style: GoogleFonts.bricolageGrotesque(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          color: _letterFor(tint),
        ),
      ),
    );
  }
}
