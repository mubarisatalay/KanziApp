import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// Once-a-second amber mono countdown to a reveal instant.
///
/// Compact form renders "07:42 kaldı"; [big] renders just the digits at
/// display size (the blind-state hero). Shows 00:00 once the moment passes.
class RevealCountdown extends StatefulWidget {
  final DateTime revealAt;
  final double fontSize;
  final bool big;

  /// Fired once when the countdown crosses zero while on screen — the hook
  /// for auto-refreshing into the revealed state / ceremony.
  final VoidCallback? onDone;

  const RevealCountdown({
    super.key,
    required this.revealAt,
    this.fontSize = 13,
    this.big = false,
    this.onDone,
  });

  const RevealCountdown.big({super.key, required this.revealAt, this.onDone})
      : fontSize = 34,
        big = true;

  @override
  State<RevealCountdown> createState() => _RevealCountdownState();
}

class _RevealCountdownState extends State<RevealCountdown> {
  Timer? _timer;
  bool _doneFired = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (!_doneFired && !DateTime.now().isBefore(widget.revealAt)) {
        _doneFired = true;
        widget.onDone?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _remaining {
    final diff = widget.revealAt.difference(DateTime.now());
    if (diff.isNegative) return '00:00';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final digits = TextSpan(
      text: _remaining,
      style: AppTheme.mono(
        fontSize: widget.fontSize,
        letterSpacing: widget.big ? 2 : 1,
        color: AppColors.accent,
      ),
    );
    if (widget.big) {
      return Text.rich(digits);
    }
    return Text.rich(
      TextSpan(children: [
        digits,
        TextSpan(
          text: AppLocalizations.of(context).timeLeftSuffix,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
        ),
      ]),
    );
  }
}
