package com.kanzi.api.challenge;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.UUID;

public interface SubmissionRepository extends JpaRepository<Submission, UUID> {

    List<Submission> findByChallengeIdOrderBySubmittedAt(UUID challengeId);

    List<Submission> findByRoomId(UUID roomId);

    boolean existsByChallengeIdAndUserId(UUID challengeId, UUID userId);

    long countByChallengeId(UUID challengeId);

    List<Submission> findByChallengeIdIn(Collection<UUID> challengeIds);

    List<Submission> findByChallengeIdInAndUserId(Collection<UUID> challengeIds, UUID userId);
}
