package com.kanzi.api.challenge;

import com.kanzi.api.config.AppProperties;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.zone.ZoneRulesException;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class RevealPolicyTest {

    private static RevealPolicy policy(String time, String zone) {
        return new RevealPolicy(new AppProperties(null, null, null, null, null,
                new AppProperties.Reveal(LocalTime.parse(time), zone)));
    }

    @Test
    void istanbulIsFixedUtcPlus3YearRound() {
        RevealPolicy policy = policy("21:00", "Europe/Istanbul");
        assertEquals(Instant.parse("2026-07-11T18:00:00Z"), policy.revealAtFor(LocalDate.parse("2026-07-11")));
        assertEquals(Instant.parse("2026-01-15T18:00:00Z"), policy.revealAtFor(LocalDate.parse("2026-01-15")));
    }

    @Test
    void dstAwareZoneShiftsWithSeason() {
        RevealPolicy policy = policy("21:00", "Europe/Berlin");
        // CEST (UTC+2) in summer, CET (UTC+1) in winter.
        assertEquals(Instant.parse("2026-07-11T19:00:00Z"), policy.revealAtFor(LocalDate.parse("2026-07-11")));
        assertEquals(Instant.parse("2026-01-15T20:00:00Z"), policy.revealAtFor(LocalDate.parse("2026-01-15")));
    }

    @Test
    void customRevealTimeIsRespected() {
        RevealPolicy policy = policy("22:30", "Europe/Istanbul");
        assertEquals(Instant.parse("2026-07-11T19:30:00Z"), policy.revealAtFor(LocalDate.parse("2026-07-11")));
    }

    @Test
    void invalidZoneFailsFast() {
        assertThrows(ZoneRulesException.class, () -> policy("21:00", "Mars/Olympus_Mons"));
    }

    @Test
    void isRevealedIsTimeBased() {
        RevealPolicy policy = policy("21:00", "Europe/Istanbul");
        Challenge past = new Challenge();
        past.setRevealAt(Instant.now().minusSeconds(1));
        Challenge future = new Challenge();
        future.setRevealAt(Instant.now().plusSeconds(3600));
        assertTrue(policy.isRevealed(past));
        assertFalse(policy.isRevealed(future));
    }
}
