/// A single entry on the leaderboard
class LeaderboardEntry {
  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final int totalVotes;
  final int rank;
  final int submissionCount;

  const LeaderboardEntry({
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.totalVotes,
    required this.rank,
    this.submissionCount = 0,
  });

  /// Whether this user is the winner (rank 1 with votes)
  bool get isWinner => rank == 1 && totalVotes > 0;

  /// Whether this user is on the podium (top 3)
  bool get isOnPodium => rank <= 3 && totalVotes > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaderboardEntry && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() {
    return 'LeaderboardEntry(rank: $rank, user: $username, votes: $totalVotes)';
  }
}
