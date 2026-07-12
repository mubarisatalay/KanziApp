/// Challenge entity
class Challenge {
  final String id;
  final String roomId;
  final String challengeText;
  final ChallengeType challengeType;
  final DateTime challengeDate;
  final DateTime createdAt;

  /// When results open and votes/submissions close (null for pre-migration payloads).
  final DateTime? revealAt;

  /// Whether the reveal moment has passed (server-derived).
  final bool revealed;

  /// Whether submission authors are hidden until reveal.
  final bool blind;

  /// Additional computed fields
  final int submissionCount;
  final bool hasUserSubmitted;

  const Challenge({
    required this.id,
    required this.roomId,
    required this.challengeText,
    required this.challengeType,
    required this.challengeDate,
    required this.createdAt,
    this.revealAt,
    this.revealed = true,
    this.blind = false,
    this.submissionCount = 0,
    this.hasUserSubmitted = false,
  });

  /// Whether this challenge is for today
  bool get isToday {
    final now = DateTime.now();
    return challengeDate.year == now.year &&
        challengeDate.month == now.month &&
        challengeDate.day == now.day;
  }

  /// Whether the reveal moment has passed, derived live from [revealAt] so an
  /// open screen flips at 21:00 without a refetch. Falls back to the server
  /// snapshot for old payloads without the field.
  bool get isRevealedNow =>
      revealAt != null ? !DateTime.now().isBefore(revealAt!) : revealed;

  /// Whether this challenge still accepts submissions/votes (today and not yet
  /// revealed — the server returns 409 for either after reveal).
  bool get isActive => isToday && !isRevealedNow;

  /// Whether this challenge is in the past
  bool get isPast => challengeDate.isBefore(DateTime.now().copyWith(
        hour: 0,
        minute: 0,
        second: 0,
        millisecond: 0,
      ));

  Challenge copyWith({
    String? id,
    String? roomId,
    String? challengeText,
    ChallengeType? challengeType,
    DateTime? challengeDate,
    DateTime? createdAt,
    DateTime? revealAt,
    bool? revealed,
    bool? blind,
    int? submissionCount,
    bool? hasUserSubmitted,
  }) {
    return Challenge(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      challengeText: challengeText ?? this.challengeText,
      challengeType: challengeType ?? this.challengeType,
      challengeDate: challengeDate ?? this.challengeDate,
      createdAt: createdAt ?? this.createdAt,
      revealAt: revealAt ?? this.revealAt,
      revealed: revealed ?? this.revealed,
      blind: blind ?? this.blind,
      submissionCount: submissionCount ?? this.submissionCount,
      hasUserSubmitted: hasUserSubmitted ?? this.hasUserSubmitted,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Challenge && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Challenge(id: $id, type: $challengeType, date: $challengeDate)';
  }
}

/// Challenge type enum
enum ChallengeType {
  photo,
  text,
  photoText;

  /// Create from database string
  static ChallengeType fromString(String value) {
    switch (value) {
      case 'photo':
        return ChallengeType.photo;
      case 'text':
        return ChallengeType.text;
      case 'photo_text':
        return ChallengeType.photoText;
      default:
        return ChallengeType.photoText;
    }
  }

  /// Convert to database string
  String toDbString() {
    switch (this) {
      case ChallengeType.photo:
        return 'photo';
      case ChallengeType.text:
        return 'text';
      case ChallengeType.photoText:
        return 'photo_text';
    }
  }

  /// Display label
  String get label {
    switch (this) {
      case ChallengeType.photo:
        return 'Photo';
      case ChallengeType.text:
        return 'Text';
      case ChallengeType.photoText:
        return 'Photo & Text';
    }
  }

  /// Whether this type requires a photo
  bool get requiresPhoto =>
      this == ChallengeType.photo || this == ChallengeType.photoText;

  /// Whether this type requires text
  bool get requiresText =>
      this == ChallengeType.text || this == ChallengeType.photoText;
}
