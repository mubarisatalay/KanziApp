import 'package:flutter/material.dart';

/// KOR palette — flat warm charcoal + one coral + restrained amber.
///
/// Source of truth: design_handoff_kanzi_kor_redesign/README.md ("Design Tokens").
/// Anti-goals: no gradients, no neon glows, no aurora backgrounds. Amber is
/// reserved for streaks, gold/#1 rank, timers and success-ish states only.
class AppColors {
  AppColors._();

  // --- Core surfaces ---
  /// Flat warm charcoal. The only background in the app — no gradients anywhere.
  static const Color background = Color(0xFF16120F);

  /// Glass card fill: white at 5% over [background].
  static const Color surfaceGlass = Color(0x0DFFFFFF);

  /// 1px hairline border on glass surfaces: white at 9%.
  static const Color glassBorder = Color(0x17FFFFFF);

  /// Slightly denser fill for chips/inputs: white at 6-7%.
  static const Color surfaceVariant = Color(0x12FFFFFF);

  /// Opaque surface for dialogs/sheets (glass doesn't work over scrim).
  static const Color surface = Color(0xFF211C18);

  static const Color divider = Color(0x12FFFFFF); // white 7%

  // --- Coral (primary) ---
  /// Flat fill for all primary actions.
  static const Color primary = Color(0xFFFF6B4A);

  /// Pressed state: primary darkened ~8%. No elevation change on press.
  static const Color primaryPressed = Color(0xFFEB6244);

  /// Text/icons sitting on a coral fill.
  static const Color onPrimary = Color(0xFF1A0F0A);

  /// Coral for text, links and badges on dark (lighter than the fill coral).
  static const Color primaryText = Color(0xFFFF8A6B);

  /// Coral tint fill (7-14% opacity band; this is ~10%).
  static const Color coralTint = Color(0x1AFF6B4A);

  /// Border for coral-tinted containers (22-30% band; ~26%).
  static const Color coralBorder = Color(0x42FF6B4A);

  // --- Amber (accent — streaks, #1 rank, timers, success-ish only) ---
  static const Color accent = Color(0xFFF5A860);

  /// Amber tint fill (7-15% band; ~11%).
  static const Color amberTint = Color(0x1CF5A860);

  /// Border for amber-tinted containers (25-35% band; ~30%).
  static const Color amberBorder = Color(0x4DF5A860);

  // --- Rank metals ---
  static const Color bronze = Color(0xFFD89A72);

  /// Silver (2nd place): warm white at 80%.
  static const Color silver = Color(0xCCF3EDE7);
  static const Color silverBorder = Color(0x59F3EDE7); // warm white 35%

  // --- Text (warm white ramp) ---
  static const Color textPrimary = Color(0xFFF3EDE7);
  static const Color textSecondary = Color(0x8CF3EDE7); // 55%
  static const Color textTertiary = Color(0x6BF3EDE7); // 42%
  static const Color textFaint = Color(0x59F3EDE7); // 35%

  // --- Status ---
  /// Success states are "success-ish" amber per the KOR spec.
  static const Color success = accent;
  static const Color error = Color(0xFFE8574B);
  static const Color warning = accent;
  static const Color info = textSecondary;

  // --- Legacy aliases (still referenced by not-yet-restyled files) ---
  static const Color primaryDark = primaryPressed;
  static const Color primaryLight = primaryText;
  static const Color secondary = primary;
  static const Color secondaryDark = primaryPressed;
  static const Color secondaryLight = primaryText;
  static const Color accentDark = accent;
  static const Color accentLight = accent;
  static const Color winner = accent; // gold/#1 = amber
  static const Color voted = accent;
  static const Color backgroundDark = background;
  static const Color surfaceDark = surface;
}
