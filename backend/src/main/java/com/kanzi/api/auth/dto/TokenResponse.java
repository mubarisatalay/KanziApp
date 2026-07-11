package com.kanzi.api.auth.dto;

public record TokenResponse(
        String accessToken,
        String refreshToken,
        String tokenType,
        long expiresIn,
        ProfileResponse user
) {
}
