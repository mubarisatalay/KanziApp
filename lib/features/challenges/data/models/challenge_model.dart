import '../../domain/entities/challenge.dart';

/// Challenge model for data layer. Maps the API's ChallengeResponse (camelCase, flat).
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

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      challengeText: json['challengeText'] as String,
      challengeType: ChallengeType.fromString(json['challengeType'] as String),
      challengeDate: DateTime.parse(json['challengeDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      submissionCount: (json['submissionCount'] as num?)?.toInt() ?? 0,
      hasUserSubmitted: json['hasSubmitted'] as bool? ?? false,
    );
  }
}
