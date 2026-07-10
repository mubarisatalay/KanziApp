package com.kanzi.api.challenge;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface VoteRepository extends JpaRepository<Vote, UUID> {

    Optional<Vote> findBySubmissionIdAndVoterId(UUID submissionId, UUID voterId);

    List<Vote> findBySubmissionIdIn(Collection<UUID> submissionIds);

    void deleteBySubmissionIdAndVoterId(UUID submissionId, UUID voterId);
}
