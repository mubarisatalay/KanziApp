package com.kanzi.api.challenge;

import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ChallengeRepository extends JpaRepository<Challenge, UUID> {

    Optional<Challenge> findByRoomIdAndChallengeDate(UUID roomId, LocalDate challengeDate);

    boolean existsByRoomIdAndChallengeDate(UUID roomId, LocalDate challengeDate);

    List<Challenge> findTop30ByRoomIdOrderByChallengeDateDesc(UUID roomId);
}
