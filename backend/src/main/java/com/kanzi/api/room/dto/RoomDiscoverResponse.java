package com.kanzi.api.room.dto;

import com.kanzi.api.room.Room;

import java.util.UUID;

public record RoomDiscoverResponse(
        UUID id,
        String name,
        String description,
        long memberCount,
        boolean hasChallengeToday
) {
    public static RoomDiscoverResponse from(Room room, long memberCount, boolean hasChallengeToday) {
        return new RoomDiscoverResponse(
                room.getId(),
                room.getName(),
                room.getDescription(),
                memberCount,
                hasChallengeToday
        );
    }
}
