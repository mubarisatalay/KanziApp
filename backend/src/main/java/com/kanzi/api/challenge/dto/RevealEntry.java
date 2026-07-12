package com.kanzi.api.challenge.dto;

import java.time.Instant;
import java.util.UUID;

/** One ranked row of the reveal ceremony. Identity is always visible here — reveal has happened. */
public record RevealEntry(
        int rank,
        UUID submissionId,
        UUID userId,
        String username,
        String displayName,
        String avatarUrl,
        String imageUrl,
        String textContent,
        Instant submittedAt,
        double avgScore,
        int voteCount,
        int totalVotes
) {
}
