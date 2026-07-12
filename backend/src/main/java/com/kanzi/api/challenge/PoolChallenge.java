package com.kanzi.api.challenge;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.util.UUID;

/**
 * An app-curated challenge prompt. Seeded via Liquibase (006); the daily job draws a random
 * active row per room. Retire a prompt by setting {@code active = false} — never delete, so
 * past challenges keep their provenance.
 */
@Entity
@Table(name = "pool_challenges")
@Getter
@Setter
@NoArgsConstructor
public class PoolChallenge {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "challenge_text", nullable = false)
    private String challengeText;

    @Column(name = "challenge_type", nullable = false)
    private String challengeType;

    /** Authors hidden until reveal — only for prompts whose content doesn't identify the author. */
    @Column(name = "blind", nullable = false)
    private boolean blind;

    @Column(name = "active", nullable = false)
    private boolean active = true;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
}
