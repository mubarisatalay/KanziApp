package com.kanzi.api.challenge;

import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;

/**
 * Draws a random prompt from the app-curated {@code pool_challenges} table. Ordered last: this
 * is the global fallback every room can rely on; room-scoped sources register with a higher
 * precedence and win when they have something to offer.
 */
@Component
@Order(Ordered.LOWEST_PRECEDENCE)
public class CuratedPoolSource implements ChallengeSource {

    private final PoolChallengeRepository pool;

    public CuratedPoolSource(PoolChallengeRepository pool) {
        this.pool = pool;
    }

    @Override
    public Optional<ChallengeDraft> draw(UUID roomId, LocalDate date) {
        List<PoolChallenge> candidates = pool.findByActiveTrue();
        if (candidates.isEmpty()) {
            return Optional.empty();
        }
        PoolChallenge pick = candidates.get(ThreadLocalRandom.current().nextInt(candidates.size()));
        ChallengeType type = ChallengeType.fromDb(pick.getChallengeType())
                .orElseThrow(() -> new IllegalStateException(
                        "Pool challenge %s has invalid type '%s'".formatted(pick.getId(), pick.getChallengeType())));
        return Optional.of(new ChallengeDraft(pick.getChallengeText(), type, pick.isBlind()));
    }
}
