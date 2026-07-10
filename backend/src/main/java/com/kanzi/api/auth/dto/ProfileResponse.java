package com.kanzi.api.auth.dto;

import com.kanzi.api.user.User;

import java.time.Instant;
import java.util.UUID;

public record ProfileResponse(
        UUID id,
        String email,
        String username,
        String displayName,
        String avatarUrl,
        boolean emailVerified,
        Instant createdAt,
        Instant updatedAt
) {
    public static ProfileResponse from(User user) {
        return new ProfileResponse(
                user.getId(),
                user.getEmail(),
                user.getUsername(),
                user.getDisplayName(),
                user.getAvatarUrl(),
                user.isEmailVerified(),
                user.getCreatedAt(),
                user.getUpdatedAt()
        );
    }
}
