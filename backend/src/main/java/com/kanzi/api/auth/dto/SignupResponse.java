package com.kanzi.api.auth.dto;

public record SignupResponse(String message, boolean emailConfirmationRequired) {
}
