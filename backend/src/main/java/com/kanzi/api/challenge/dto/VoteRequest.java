package com.kanzi.api.challenge.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

public record VoteRequest(@Min(1) @Max(5) int voteValue) {
}
