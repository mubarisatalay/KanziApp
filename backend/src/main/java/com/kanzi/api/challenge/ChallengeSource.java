package com.kanzi.api.challenge;

import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

/**
 * A source of daily challenge prompts. {@link DailyChallengeJob} consults all sources in bean
 * order ({@code @Order}) and takes the first non-empty draw, so room-scoped sources (e.g. the
 * user-submitted dare pool) naturally shadow the global curated pool by ordering before it.
 */
public interface ChallengeSource {

    /** Draw a prompt for the given room and date, or empty if this source has nothing to offer. */
    Optional<ChallengeDraft> draw(UUID roomId, LocalDate date);
}
