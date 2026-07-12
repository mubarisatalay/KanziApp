package com.kanzi.api.challenge.dto;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Ranked results of a revealed challenge. {@code winner} is the first entry (null when nobody
 * submitted); {@code currentUserRank} is null when the caller didn't submit.
 */
public record RevealResponse(
        UUID challengeId,
        String challengeText,
        String challengeType,
        LocalDate challengeDate,
        Instant revealAt,
        List<RevealEntry> entries,
        RevealEntry winner,
        Integer currentUserRank,
        int totalSubmissions
) {
}
