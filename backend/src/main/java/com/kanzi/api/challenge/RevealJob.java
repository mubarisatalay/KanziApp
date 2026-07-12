package com.kanzi.api.challenge;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

/**
 * Flips the durable {@code revealed} flag on challenges whose reveal moment has passed.
 *
 * <p>Read/vote gating is time-based (see {@link RevealPolicy}), so a flag flipped up to a minute
 * "late" changes nothing user-visible. The flag exists as an event marker — the hook where reveal
 * push notifications will attach later.
 */
@Component
public class RevealJob {

    private static final Logger log = LoggerFactory.getLogger(RevealJob.class);

    private final ChallengeRepository challenges;

    public RevealJob(ChallengeRepository challenges) {
        this.challenges = challenges;
    }

    // fixedDelay (not cron) so a slow tick can never overlap the next one.
    @Scheduled(fixedDelay = 60_000, initialDelay = 15_000)
    @Transactional
    public void revealDueChallenges() {
        int flipped = challenges.markRevealed(Instant.now());
        if (flipped > 0) {
            log.info("RevealJob flipped {} challenge(s) to revealed", flipped);
        }
    }
}
