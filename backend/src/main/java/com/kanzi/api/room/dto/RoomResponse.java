package com.kanzi.api.room.dto;

import com.kanzi.api.room.Room;

import java.time.Instant;
import java.util.UUID;

public record RoomResponse(
        UUID id,
        String name,
        String description,
        String code,
        UUID createdBy,
        Instant createdAt,
        Instant updatedAt,
        long memberCount,
        String currentUserRole
) {
    public static RoomResponse from(Room room, long memberCount, String currentUserRole) {
        return new RoomResponse(
                room.getId(),
                room.getName(),
                room.getDescription(),
                room.getCode(),
                room.getCreatedBy(),
                room.getCreatedAt(),
                room.getUpdatedAt(),
                memberCount,
                currentUserRole
        );
    }
}
