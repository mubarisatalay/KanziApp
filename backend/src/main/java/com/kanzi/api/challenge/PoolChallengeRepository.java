package com.kanzi.api.challenge;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface PoolChallengeRepository extends JpaRepository<PoolChallenge, UUID> {

    List<PoolChallenge> findByActiveTrue();
}
