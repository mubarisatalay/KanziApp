package com.kanzi.api.auth.dto;

import jakarta.validation.constraints.Size;

/** Partial profile update — null fields are left unchanged. */
public record UpdateProfileRequest(
        @Size(min = 3, max = 30) String username,
        @Size(max = 50) String displayName
) {
}
