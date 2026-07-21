package com.kanzi.api.leaderboard.dto;

import java.util.UUID;

/// Normalized weekly MVP entry. Score is 0–10, comparable across rooms of any size.
public record WeeklyMvpEntry(
        UUID userId,
        String username,
        String displayName,
        String avatarUrl,
        double score,          // normalized 0-10
        int submissionCount,
        int rank,
        String roomContext     // null for room tab; "2 rooms" for global tab
) {
}
