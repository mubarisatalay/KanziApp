package com.kanzi.api.challenge.dto;

import com.kanzi.api.challenge.Challenge;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

public record ChallengeResponse(
        UUID id,
        UUID roomId,
        String challengeText,
        String challengeType,
        LocalDate challengeDate,
        Instant createdAt,
        Instant scheduledAt,
        Instant revealAt,
        boolean revealed,
        boolean blind,
        boolean hasSubmitted,
        int submissionCount
) {
    /** {@code revealed} must be the time-derived value (RevealPolicy), not the entity's lagging flag. */
    public static ChallengeResponse from(Challenge challenge, boolean revealed,
                                         boolean hasSubmitted, int submissionCount) {
        return new ChallengeResponse(
                challenge.getId(),
                challenge.getRoomId(),
                challenge.getChallengeText(),
                challenge.getChallengeType(),
                challenge.getChallengeDate(),
                challenge.getCreatedAt(),
                challenge.getScheduledAt(),
                challenge.getRevealAt(),
                revealed,
                challenge.isBlind(),
                hasSubmitted,
                submissionCount
        );
    }
}
