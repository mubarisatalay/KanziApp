package com.kanzi.api.room.dto;

import jakarta.validation.constraints.NotBlank;

public record JoinRoomRequest(@NotBlank String code) {
}
