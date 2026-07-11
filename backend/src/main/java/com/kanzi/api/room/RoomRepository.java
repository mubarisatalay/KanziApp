package com.kanzi.api.room;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RoomRepository extends JpaRepository<Room, UUID> {

    Optional<Room> findByCode(String code);

    boolean existsByCode(String code);

    @Query("""
            select r from Room r
            where r.id in (select m.roomId from RoomMember m where m.userId = :userId)
            order by r.updatedAt desc
            """)
    List<Room> findAllForMember(@Param("userId") UUID userId);
}
