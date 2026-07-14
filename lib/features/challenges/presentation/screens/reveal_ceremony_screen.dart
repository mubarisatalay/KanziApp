import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/kor/kor.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/reveal_result.dart';
import '../providers/challenge_provider.dart';

/// Reveal ceremony — KOR design "3b": the 21:00 moment. Rows enter staggered,
/// last place first, the winner card last.
class RevealCeremonyScreen extends ConsumerWidget {
  final String challengeId;

  const RevealCeremonyScreen({super.key, required this.challengeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(revealResultsProvider(challengeId));
    final currentUserId = ref.watch(currentUserProvider)?.id;

    return Scaffold(
      body: SafeArea(
        child: resultAsync.when(
          data: (result) => _CeremonyBody(
            result: result,
            currentUserId: currentUserId,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorStateWidget(
            message: error.toString(),
            onRetry: () => ref.invalidate(revealResultsProvider(challengeId)),
          ),
        ),
      ),
    );
  }
}

class _CeremonyBody extends StatefulWidget {
  final RevealResult result;
  final String? currentUserId;

  const _CeremonyBody({required this.result, this.currentUserId});

  @override
  State<_CeremonyBody> createState() => _CeremonyBodyState();
}

class _CeremonyBodyState extends State<_CeremonyBody> {
  /// How many entries (counted from LAST place) are visible. The winner card
  /// is the final step — suspense builds bottom-up.
  int _revealedSteps = 0;
  Timer? _stagger;

  int get _totalSteps => widget.result.entries.length;

  @override
  void initState() {
    super.initState();
    _stagger = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!mounted) return;
      setState(() => _revealedSteps++);
      if (_revealedSteps >= _totalSteps) {
        timer.cancel();
        HapticFeedback.mediumImpact(); // the winner lands
      }
    });
  }

  @override
  void dispose() {
    _stagger?.cancel();
    super.dispose();
  }

  /// Entry i (0 = winner) becomes visible once the countdown of steps from
  /// the bottom reaches it — last place first, winner last.
  bool _isVisible(int indexInEntries) =>
      _revealedSteps >= (widget.result.entries.length - indexInEntries);

  String _revealTimeLabel(AppLocalizations l10n) {
    final revealAt = widget.result.revealAt?.toLocal();
    if (revealAt == null) return l10n.ceremonyRevealLabel('--:--');
    final hh = revealAt.hour.toString().padLeft(2, '0');
    final mm = revealAt.minute.toString().padLeft(2, '0');
    return l10n.ceremonyRevealLabel('$hh:$mm');
  }

  Future<void> _share(AppLocalizations l10n) async {
    final result = widget.result;
    if (result.winner == null) return;
    final lines = [
      l10n.ceremonyShareHeader,
      '"${result.challengeText}"',
      '',
      for (final e in result.entries)
        '${e.rank}. ${e.shownName} — ${e.avgScore.toStringAsFixed(1)} '
            '(${l10n.votesShort(e.voteCount)})',
    ];
    await SharePlus.instance.share(ShareParams(text: lines.join('\n')));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final result = widget.result;
    final winner = result.winner;
    final rest = result.entries.length > 1
        ? result.entries.sublist(1)
        : const <RevealEntry>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GlassIconButton(
                icon: Icons.chevron_left,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              _revealTimeLabel(l10n),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: 11,
                    letterSpacing: 2,
                    color: AppColors.textTertiary,
                  ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              l10n.ceremonyTitle,
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(fontSize: 24),
            ),
          ),
          const SizedBox(height: 20),

          if (winner == null)
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  l10n.ceremonyNobodySubmitted,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textTertiary),
                ),
              ),
            )
          else ...[
            // Winner card — the last thing to appear.
            _Staggered(
              visible: _isVisible(0),
              child: _WinnerCard(
                entry: winner,
                isCurrentUser: winner.userId == widget.currentUserId,
              ),
            ),
            const SizedBox(height: 12),

            for (var i = 0; i < rest.length; i++) ...[
              _Staggered(
                visible: _isVisible(i + 1),
                child: _RankedRow(
                  entry: rest[i],
                  isCurrentUser: rest[i].userId == widget.currentUserId,
                ),
              ),
              const SizedBox(height: 8),
            ],

            const SizedBox(height: 16),
            OutlinedButton(
              onPressed:
                  _revealedSteps >= _totalSteps ? () => _share(l10n) : null,
              child: Text(l10n.ceremonyShare),
            ),
          ],
        ],
      ),
    );
  }
}

/// 300ms fade + upward slide when [visible] flips.
class _Staggered extends StatelessWidget {
  final bool visible;
  final Widget child;

  const _Staggered({required this.visible, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 0.08),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: child,
      ),
    );
  }
}

/// Amber winner card: photo, amber-ringed monogram, name, big score.
class _WinnerCard extends StatelessWidget {
  final RevealEntry entry;
  final bool isCurrentUser;

  const _WinnerCard({required this.entry, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.amberTint,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.amberBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.imageUrl != null)
            CachedNetworkImage(
              imageUrl: entry.imageUrl!,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 180,
                color: AppColors.surfaceVariant,
              ),
              errorWidget: (_, __, ___) => Container(
                height: 180,
                color: AppColors.surfaceVariant,
                child: const Center(
                  child: Icon(Icons.broken_image_outlined,
                      size: 34, color: AppColors.textTertiary),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                MonogramAvatar(
                  name: entry.shownName,
                  size: 44,
                  tint: MonogramTint.amber,
                  ringColor: AppColors.accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              entry.shownName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrentUser) ...[
                            const SizedBox(width: 6),
                            const _YouPill(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.textContent != null &&
                                entry.textContent!.isNotEmpty
                            ? entry.textContent!
                            : '@${entry.username ?? ''}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                                fontSize: 12, color: AppColors.textTertiary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      entry.avgScore.toStringAsFixed(1),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontSize: 22, color: AppColors.accent),
                    ),
                    Text(
                      l10n.votesShort(entry.voteCount),
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                              fontSize: 11, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Glass row for ranks 2+.
class _RankedRow extends StatelessWidget {
  final RevealEntry entry;
  final bool isCurrentUser;

  const _RankedRow({required this.entry, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppColors.coralTint : AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isCurrentUser ? AppColors.coralBorder : AppColors.glassBorder,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '${entry.rank}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTertiary,
                  ),
            ),
          ),
          MonogramAvatar(
            name: entry.shownName,
            size: 32,
            tint: MonogramTint.values[
                (entry.username ?? '?').hashCode.abs() %
                    MonogramTint.values.length],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    entry.shownName,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isCurrentUser) ...[
                  const SizedBox(width: 6),
                  const _YouPill(),
                ],
              ],
            ),
          ),
          Text(
            entry.avgScore.toStringAsFixed(1),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isCurrentUser
                      ? AppColors.accent
                      : AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}

class _YouPill extends StatelessWidget {
  const _YouPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        AppLocalizations.of(context).youPillUpper,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: AppColors.onPrimary,
        ),
      ),
    );
  }
}
