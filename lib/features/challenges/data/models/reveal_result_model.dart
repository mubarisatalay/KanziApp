import '../../domain/entities/reveal_result.dart';

/// Maps the API's RevealResponse / RevealEntry (camelCase, flat).
class RevealResultModel extends RevealResult {
  const RevealResultModel({
    required super.challengeId,
    required super.challengeText,
    super.revealAt,
    super.entries,
    super.winner,
    super.currentUserRank,
    super.totalSubmissions,
  });

  factory RevealResultModel.fromJson(Map<String, dynamic> json) {
    final entries = (json['entries'] as List? ?? const [])
        .map((j) => RevealEntryModel.fromJson(j as Map<String, dynamic>))
        .toList();
    return RevealResultModel(
      challengeId: json['challengeId'] as String,
      challengeText: json['challengeText'] as String,
      revealAt: json['revealAt'] != null
          ? DateTime.parse(json['revealAt'] as String)
          : null,
      entries: entries,
      winner: json['winner'] != null
          ? RevealEntryModel.fromJson(json['winner'] as Map<String, dynamic>)
          : null,
      currentUserRank: (json['currentUserRank'] as num?)?.toInt(),
      totalSubmissions: (json['totalSubmissions'] as num?)?.toInt() ?? 0,
    );
  }
}

class RevealEntryModel extends RevealEntry {
  const RevealEntryModel({
    required super.rank,
    required super.submissionId,
    required super.userId,
    super.username,
    super.displayName,
    super.avatarUrl,
    super.imageUrl,
    super.textContent,
    required super.submittedAt,
    super.avgScore,
    super.voteCount,
    super.totalVotes,
  });

  factory RevealEntryModel.fromJson(Map<String, dynamic> json) {
    return RevealEntryModel(
      rank: (json['rank'] as num).toInt(),
      submissionId: json['submissionId'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String?,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      textContent: json['textContent'] as String?,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      avgScore: (json['avgScore'] as num?)?.toDouble() ?? 0,
      voteCount: (json['voteCount'] as num?)?.toInt() ?? 0,
      totalVotes: (json['totalVotes'] as num?)?.toInt() ?? 0,
    );
  }
}
