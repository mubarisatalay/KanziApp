package com.kanzi.api.auth;

import com.kanzi.api.auth.dto.*;
import com.kanzi.api.common.CurrentUserId;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService auth;

    public AuthController(AuthService auth) {
        this.auth = auth;
    }

    @PostMapping("/signup")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public SignupResponse signup(@Valid @RequestBody SignupRequest request) {
        return auth.signup(request);
    }

    @GetMapping("/verify")
    public Map<String, String> verify(@RequestParam String token) {
        auth.verify(token);
        return Map.of("message", "Email verified. You can now sign in.");
    }

    @PostMapping("/resend-verification")
    public Map<String, String> resendVerification(@Valid @RequestBody ResendRequest request) {
        auth.resendVerification(request.email());
        return Map.of("message", "If that email is registered and unverified, a new link has been sent.");
    }

    @PostMapping("/login")
    public TokenResponse login(@Valid @RequestBody LoginRequest request) {
        return auth.login(request);
    }

    @PostMapping("/refresh")
    public TokenResponse refresh(@Valid @RequestBody RefreshRequest request) {
        return auth.refresh(request.refreshToken());
    }

    @PostMapping("/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void logout(@Valid @RequestBody RefreshRequest request) {
        auth.logout(request.refreshToken());
    }

    @GetMapping("/me")
    public ProfileResponse me(@AuthenticationPrincipal Jwt jwt) {
        return auth.me(UUID.fromString(jwt.getSubject()));
    }

    @PatchMapping("/me")
    public ProfileResponse updateProfile(@CurrentUserId UUID userId,
                                         @Valid @RequestBody UpdateProfileRequest request) {
        return auth.updateProfile(userId, request);
    }
}
