package com.kanzi.api.leaderboard.dto;

import java.util.UUID;

public record LeaderboardEntry(
        UUID userId,
        String username,
        String displayName,
        String avatarUrl,
        int totalVotes,
        int submissionCount,
        int rank
) {
}
