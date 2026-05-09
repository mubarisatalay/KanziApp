import '../../domain/entities/submission.dart';

/// Submission model for data layer
class SubmissionModel extends Submission {
  const SubmissionModel({
    required super.id,
    required super.challengeId,
    required super.userId,
    required super.roomId,
    super.imageUrl,
    super.textContent,
    required super.submittedAt,
    super.username,
    super.displayName,
    super.avatarUrl,
    super.voteCount,
    super.averageVote,
    super.currentUserVote,
  });

  /// Create from JSON (Supabase response with joined data)
  factory SubmissionModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    // Profile data from join
    final profile = json['profiles'] as Map<String, dynamic>?;

    // Vote data from join
    int voteCount = 0;
    double averageVote = 0.0;
    int? currentUserVote;

    if (json['votes'] is List) {
      final votes = json['votes'] as List;
      voteCount = votes.length;
      if (votes.isNotEmpty) {
        final totalVotes = votes.fold<int>(
          0,
          (sum, v) => sum + (v['vote_value'] as int? ?? 0),
        );
        averageVote = totalVotes / votes.length;
      }
      if (currentUserId != null) {
        final userVote = votes.cast<Map<String, dynamic>>().where(
              (v) => v['voter_id'] == currentUserId,
            );
        if (userVote.isNotEmpty) {
          currentUserVote = userVote.first['vote_value'] as int?;
        }
      }
    }

    return SubmissionModel(
      id: json['id'] as String,
      challengeId: json['challenge_id'] as String,
      userId: json['user_id'] as String,
      roomId: json['room_id'] as String,
      imageUrl: json['image_url'] as String?,
      textContent: json['text_content'] as String?,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      username: profile?['username'] as String?,
      displayName: profile?['display_name'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
      voteCount: voteCount,
      averageVote: averageVote,
      currentUserVote: currentUserVote,
    );
  }

  /// Convert to JSON for insert
  Map<String, dynamic> toInsertJson() {
    return {
      'challenge_id': challengeId,
      'user_id': userId,
      'room_id': roomId,
      if (imageUrl != null) 'image_url': imageUrl,
      if (textContent != null) 'text_content': textContent,
    };
  }
}
