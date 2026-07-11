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
        boolean hasSubmitted,
        int submissionCount
) {
    public static ChallengeResponse from(Challenge challenge, boolean hasSubmitted, int submissionCount) {
        return new ChallengeResponse(
                challenge.getId(),
                challenge.getRoomId(),
                challenge.getChallengeText(),
                challenge.getChallengeType(),
                challenge.getChallengeDate(),
                challenge.getCreatedAt(),
                hasSubmitted,
                submissionCount
        );
    }
}
