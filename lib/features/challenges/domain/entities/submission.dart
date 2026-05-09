/// Submission entity — a user's response to a challenge
class Submission {
  final String id;
  final String challengeId;
  final String userId;
  final String roomId;
  final String? imageUrl;
  final String? textContent;
  final DateTime submittedAt;

  /// Populated from joins
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  /// Vote data
  final int voteCount;
  final double averageVote;
  final int? currentUserVote; // null if current user hasn't voted

  const Submission({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.roomId,
    this.imageUrl,
    this.textContent,
    required this.submittedAt,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.voteCount = 0,
    this.averageVote = 0.0,
    this.currentUserVote,
  });

  /// Whether the current user has voted on this submission
  bool get hasVoted => currentUserVote != null;

  Submission copyWith({
    String? id,
    String? challengeId,
    String? userId,
    String? roomId,
    String? imageUrl,
    String? textContent,
    DateTime? submittedAt,
    String? username,
    String? displayName,
    String? avatarUrl,
    int? voteCount,
    double? averageVote,
    int? currentUserVote,
  }) {
    return Submission(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      userId: userId ?? this.userId,
      roomId: roomId ?? this.roomId,
      imageUrl: imageUrl ?? this.imageUrl,
      textContent: textContent ?? this.textContent,
      submittedAt: submittedAt ?? this.submittedAt,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      voteCount: voteCount ?? this.voteCount,
      averageVote: averageVote ?? this.averageVote,
      currentUserVote: currentUserVote ?? this.currentUserVote,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Submission && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Submission(id: $id, userId: $userId, votes: $voteCount)';
  }
}
