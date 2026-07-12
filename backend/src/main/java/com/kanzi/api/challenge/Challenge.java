package com.kanzi.api.challenge;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "challenges")
@Getter
@Setter
@NoArgsConstructor
public class Challenge {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "room_id", nullable = false)
    private UUID roomId;

    @Column(name = "challenge_text", nullable = false)
    private String challengeText;

    @Column(name = "challenge_type", nullable = false)
    private String challengeType;

    @Column(name = "challenge_date", nullable = false)
    private LocalDate challengeDate;

    /** Instant at which results open and votes/submissions close. Gate on this, not on {@code revealed}. */
    @Column(name = "reveal_at", nullable = false)
    private Instant revealAt;

    /** Durable event marker flipped by {@link RevealJob}; may lag reveal_at by up to a minute. */
    @Column(name = "revealed", nullable = false)
    private boolean revealed;

    /** Blind challenges hide submission authors (never the content) until reveal. */
    @Column(name = "blind", nullable = false)
    private boolean blind;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
}
