package com.kanzi.api.room.dto;

import jakarta.validation.constraints.Size;

/** Partial update — null fields are left unchanged. */
public record UpdateRoomRequest(
        @Size(max = 100) String name,
        @Size(max = 500) String description
) {
}
