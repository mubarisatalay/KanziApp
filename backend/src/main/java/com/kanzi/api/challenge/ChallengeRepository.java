package com.kanzi.api.challenge;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ChallengeRepository extends JpaRepository<Challenge, UUID> {

    Optional<Challenge> findByRoomIdAndChallengeDate(UUID roomId, LocalDate challengeDate);

    boolean existsByRoomIdAndChallengeDate(UUID roomId, LocalDate challengeDate);

    List<Challenge> findTop30ByRoomIdOrderByChallengeDateDesc(UUID roomId);

    @Modifying
    @Query("update Challenge c set c.revealed = true where c.revealed = false and c.revealAt <= :now")
    int markRevealed(@Param("now") Instant now);
}
