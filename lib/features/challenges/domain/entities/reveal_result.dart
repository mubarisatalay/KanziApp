/// Ranked ceremony results for a revealed challenge.
class RevealResult {
  final String challengeId;
  final String challengeText;
  final DateTime? revealAt;
  final List<RevealEntry> entries;

  /// Null when nobody submitted.
  final RevealEntry? winner;

  /// Null when the current user didn't submit.
  final int? currentUserRank;
  final int totalSubmissions;

  const RevealResult({
    required this.challengeId,
    required this.challengeText,
    this.revealAt,
    this.entries = const [],
    this.winner,
    this.currentUserRank,
    this.totalSubmissions = 0,
  });
}

/// One ranked row of the ceremony. Identity is always visible — reveal happened.
class RevealEntry {
  final int rank;
  final String submissionId;
  final String userId;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String? imageUrl;
  final String? textContent;
  final DateTime submittedAt;
  final double avgScore;
  final int voteCount;
  final int totalVotes;

  const RevealEntry({
    required this.rank,
    required this.submissionId,
    required this.userId,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.imageUrl,
    this.textContent,
    required this.submittedAt,
    this.avgScore = 0,
    this.voteCount = 0,
    this.totalVotes = 0,
  });

  /// Post-reveal the server always sends author fields; '?' is a neutral,
  /// locale-free last resort.
  String get shownName => displayName ?? username ?? '?';
}
