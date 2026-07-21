package com.kanzi.api.challenge;

import com.kanzi.api.config.AppProperties;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.Random;

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

    /**
     * The instant the challenge becomes visible on the given date.
     * Chosen deterministically from the date's epoch day as a seed, so all rooms
     * share the same time and it is stable across restarts.
     * Window: 12:00–20:00 local time (480-minute range).
     */
    public Instant scheduledAtFor(LocalDate date) {
        int minuteOffset = new Random(date.toEpochDay()).nextInt(480); // [0, 480) minutes
        LocalTime scheduledTime = LocalTime.of(12, 0).plusMinutes(minuteOffset);
        return ZonedDateTime.of(date, scheduledTime, zone).toInstant();
    }

    /** The instant a challenge on the given date reveals: the configured local time in the configured zone. */
    public Instant revealAtFor(LocalDate challengeDate) {
        return ZonedDateTime.of(challengeDate, revealTime, zone).toInstant();
    }

    public boolean isScheduled(Challenge challenge) {
        return !Instant.now().isBefore(challenge.getScheduledAt());
    }

    public boolean isRevealed(Challenge challenge) {
        return !Instant.now().isBefore(challenge.getRevealAt());
    }
}
