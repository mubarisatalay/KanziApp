package com.kanzi.api.challenge.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;

public record CreateChallengeRequest(
        @NotBlank String challengeText,
        @NotBlank String challengeType,
        @NotNull LocalDate challengeDate
) {
}
