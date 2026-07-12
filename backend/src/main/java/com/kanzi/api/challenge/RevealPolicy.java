package com.kanzi.api.challenge;

import com.kanzi.api.config.AppProperties;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;

/**
 * Single source of truth for reveal-time math and gating.
 *
 * <p>All read-path and write-window decisions are time-based ({@code now >= revealAt}), never
 * based on the persisted {@code revealed} flag — the flag is flipped by a once-a-minute job and
 * may lag; content must unlock at exactly the configured wall-clock time.
 */
@Component
public class RevealPolicy {

    private final LocalTime revealTime;
    private final ZoneId zone;

    public RevealPolicy(AppProperties props) {
        this.revealTime = props.reveal().time();
        this.zone = ZoneId.of(props.reveal().zone()); // fail fast at startup on a bad zone id
    }

    /** The instant a challenge on the given date reveals: the configured local time in the configured zone. */
    public Instant revealAtFor(LocalDate challengeDate) {
        return ZonedDateTime.of(challengeDate, revealTime, zone).toInstant();
    }

    public boolean isRevealed(Challenge challenge) {
        return !Instant.now().isBefore(challenge.getRevealAt());
    }
}
