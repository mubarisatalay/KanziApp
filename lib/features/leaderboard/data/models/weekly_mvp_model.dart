class WeeklyMvpEntry {
  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final double score;
  final int submissionCount;
  final int rank;
  final String? roomContext;

  const WeeklyMvpEntry({
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.score,
    required this.submissionCount,
    required this.rank,
    this.roomContext,
  });

  String get displayName_ => displayName?.trim().isNotEmpty == true ? displayName! : username;

  bool get isOnPodium => rank <= 3 && score > 0;

  factory WeeklyMvpEntry.fromJson(Map<String, dynamic> json) {
    return WeeklyMvpEntry(
      userId: json['userId'] as String,
      username: json['username'] as String? ?? 'Unknown',
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      submissionCount: (json['submissionCount'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      roomContext: json['roomContext'] as String?,
    );
  }
}
