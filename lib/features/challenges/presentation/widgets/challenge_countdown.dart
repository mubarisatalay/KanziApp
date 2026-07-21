import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/challenge.dart';

/// Shows a live countdown to the challenge start or reveal time.
///
/// Rebuilds every second via an internal [Timer]. When the target time passes
/// the widget calls [onExpired] so the parent can refresh state.
class ChallengeCountdown extends StatefulWidget {
  final Challenge challenge;

  /// Called once when the countdown reaches zero so the parent can invalidate providers.
  final VoidCallback? onExpired;

  const ChallengeCountdown({
    super.key,
    required this.challenge,
    this.onExpired,
  });

  @override
  State<ChallengeCountdown> createState() => _ChallengeCountdownState();
}

class _ChallengeCountdownState extends State<ChallengeCountdown> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  _Phase _phase = _Phase.waiting;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _update() {
    final now = DateTime.now();
    final scheduledAt = widget.challenge.scheduledAt;
    final revealAt = widget.challenge.revealAt;

    Duration remaining;
    _Phase phase;

    if (scheduledAt != null && now.isBefore(scheduledAt)) {
      remaining = scheduledAt.difference(now);
      phase = _Phase.waiting;
    } else if (revealAt != null && now.isBefore(revealAt)) {
      remaining = revealAt.difference(now);
      phase = _Phase.active;
    } else {
      remaining = Duration.zero;
      phase = _Phase.revealed;
    }

    if (mounted) {
      setState(() {
        _remaining = remaining;
        _phase = phase;
      });
    }

    if (phase == _Phase.revealed && _remaining == Duration.zero) {
      _timer?.cancel();
      widget.onExpired?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _Phase.waiting => _CountdownBanner(
          icon: Icons.timer_outlined,
          label: 'Challenge starts in',
          duration: _remaining,
          color: AppColors.primary,
        ),
      _Phase.active => _CountdownBanner(
          icon: Icons.lock_clock,
          label: 'Reveal in',
          duration: _remaining,
          color: AppColors.warning,
        ),
      _Phase.revealed => const SizedBox.shrink(),
    };
  }
}

enum _Phase { waiting, active, revealed }

class _CountdownBanner extends StatelessWidget {
  final IconData icon;
  final String label;
  final Duration duration;
  final Color color;

  const _CountdownBanner({
    required this.icon,
    required this.label,
    required this.duration,
    required this.color,
  });

  String _format(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            _format(duration),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
