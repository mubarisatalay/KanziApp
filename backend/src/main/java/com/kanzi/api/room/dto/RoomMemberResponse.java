package com.kanzi.api.room.dto;

import com.kanzi.api.room.RoomMember;
import com.kanzi.api.user.User;

import java.time.Instant;
import java.util.UUID;

public record RoomMemberResponse(
        UUID id,
        UUID roomId,
        UUID userId,
        String role,
        Instant joinedAt,
        String username,
        String displayName,
        String avatarUrl
) {
    public static RoomMemberResponse from(RoomMember member, User user) {
        return new RoomMemberResponse(
                member.getId(),
                member.getRoomId(),
                member.getUserId(),
                member.getRole(),
                member.getJoinedAt(),
                user != null ? user.getUsername() : null,
                user != null ? user.getDisplayName() : null,
                user != null ? user.getAvatarUrl() : null
        );
    }
}
