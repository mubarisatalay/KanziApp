import '../../domain/entities/submission.dart';

/// Submission model for data layer. Maps the API's SubmissionResponse (camelCase, flat).
class SubmissionModel extends Submission {
  const SubmissionModel({
    required super.id,
    required super.challengeId,
    super.userId,
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
    super.isOwn,
    super.anonymous,
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    final totalVotes = (json['totalVotes'] as num?)?.toInt() ?? 0;
    final voteCount = (json['voteCount'] as num?)?.toInt() ?? 0;
    return SubmissionModel(
      id: json['id'] as String,
      challengeId: json['challengeId'] as String,
      // Null while the author is anonymized (blind challenge, pre-reveal).
      userId: json['userId'] as String?,
      roomId: json['roomId'] as String,
      imageUrl: json['imageUrl'] as String?,
      textContent: json['textContent'] as String?,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      username: json['username'] as String?,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      voteCount: voteCount,
      averageVote: voteCount > 0 ? totalVotes / voteCount : 0.0,
      currentUserVote: (json['currentUserVote'] as num?)?.toInt(),
      isOwn: json['ownSubmission'] as bool? ?? false,
      anonymous: json['anonymous'] as bool? ?? false,
    );
  }
}
