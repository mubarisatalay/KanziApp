package com.kanzi.api.challenge;

/**
 * A prompt drawn from a {@link ChallengeSource}, ready to become a room's daily challenge.
 * Carries {@link ChallengeType} (not the raw db string) so an invalid type can't leave a source.
 */
public record ChallengeDraft(String challengeText, ChallengeType challengeType, boolean blind) {
}
