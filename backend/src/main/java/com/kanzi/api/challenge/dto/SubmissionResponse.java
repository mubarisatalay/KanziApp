package com.kanzi.api.challenge.dto;

import java.time.Instant;
import java.util.UUID;

public record SubmissionResponse(
        UUID id,
        UUID challengeId,
        UUID userId,
        UUID roomId,
        String imageUrl,
        String textContent,
        Instant submittedAt,
        String username,
        String displayName,
        String avatarUrl,
        int totalVotes,
        int voteCount,
        Integer currentUserVote,
        boolean ownSubmission
) {
}
