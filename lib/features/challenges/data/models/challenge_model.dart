import '../../domain/entities/challenge.dart';

/// Challenge model for data layer
class ChallengeModel extends Challenge {
  const ChallengeModel({
    required super.id,
    required super.roomId,
    required super.challengeText,
    required super.challengeType,
    required super.challengeDate,
    required super.createdAt,
    super.submissionCount,
    super.hasUserSubmitted,
  });

  /// Create from JSON (Supabase response)
  factory ChallengeModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    // Submission count from aggregated data
    int submissionCount = 0;
    bool hasUserSubmitted = false;

    if (json['submissions'] is List) {
      final submissions = json['submissions'] as List;
      submissionCount = submissions.length;
      if (currentUserId != null) {
        hasUserSubmitted = submissions.any(
          (s) => s['user_id'] == currentUserId,
        );
      }
    } else if (json['submission_count'] != null) {
      submissionCount = json['submission_count'] as int;
    }

    return ChallengeModel(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      challengeText: json['challenge_text'] as String,
      challengeType: ChallengeType.fromString(json['challenge_type'] as String),
      challengeDate: DateTime.parse(json['challenge_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      submissionCount: submissionCount,
      hasUserSubmitted: hasUserSubmitted,
    );
  }

  /// Convert to JSON for insert
  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'challenge_text': challengeText,
      'challenge_type': challengeType.toDbString(),
      'challenge_date': challengeDate.toIso8601String().split('T')[0],
    };
  }
}
