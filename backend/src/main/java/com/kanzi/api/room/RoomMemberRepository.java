package com.kanzi.api.room;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RoomMemberRepository extends JpaRepository<RoomMember, UUID> {

    Optional<RoomMember> findByRoomIdAndUserId(UUID roomId, UUID userId);

    boolean existsByRoomIdAndUserId(UUID roomId, UUID userId);

    List<RoomMember> findByRoomIdOrderByJoinedAt(UUID roomId);

    List<RoomMember> findByRoomIdIn(Collection<UUID> roomIds);

    long countByRoomId(UUID roomId);

    long countByRoomIdAndRole(UUID roomId, String role);

    List<RoomMember> findByUserId(UUID userId);

    void deleteByRoomIdAndUserId(UUID roomId, UUID userId);
}
