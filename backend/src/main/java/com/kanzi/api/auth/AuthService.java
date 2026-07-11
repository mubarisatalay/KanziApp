package com.kanzi.api.auth;

import com.kanzi.api.auth.dto.LoginRequest;
import com.kanzi.api.auth.dto.ProfileResponse;
import com.kanzi.api.auth.dto.SignupRequest;
import com.kanzi.api.auth.dto.SignupResponse;
import com.kanzi.api.auth.dto.TokenResponse;
import com.kanzi.api.auth.dto.UpdateProfileRequest;
import com.kanzi.api.common.ApiException;
import com.kanzi.api.user.User;
import com.kanzi.api.user.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class AuthService {

    private final UserRepository users;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final RefreshTokenService refreshTokens;
    private final MailService mailService;

    public AuthService(UserRepository users, PasswordEncoder passwordEncoder, JwtService jwtService,
                       RefreshTokenService refreshTokens, MailService mailService) {
        this.users = users;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.refreshTokens = refreshTokens;
        this.mailService = mailService;
    }

    @Transactional
    public SignupResponse signup(SignupRequest request) {
        String email = request.email().trim();
        String username = request.username().trim();

        if (users.existsByEmailIgnoreCase(email)) {
            throw ApiException.conflict("This email is already registered. Please sign in instead.");
        }
        if (users.existsByUsernameIgnoreCase(username)) {
            throw ApiException.conflict("Username already exists.");
        }

        User user = new User();
        user.setEmail(email);
        user.setUsername(username);
        user.setDisplayName(username);
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user.setEmailVerified(false);
        user.setVerificationToken(UUID.randomUUID().toString());
        users.save(user);

        mailService.sendVerificationEmail(user.getEmail(), user.getVerificationToken());
        return new SignupResponse("Account created. Check your email to verify your address.", true);
    }

    @Transactional
    public void verify(String token) {
        User user = users.findByVerificationToken(token)
                .orElseThrow(() -> ApiException.badRequest("Invalid or expired verification token."));
        user.setEmailVerified(true);
        user.setVerificationToken(null);
        users.save(user);
    }

    @Transactional
    public void resendVerification(String email) {
        // Never reveal whether an email exists / is already verified.
        users.findByEmailIgnoreCase(email.trim())
                .filter(u -> !u.isEmailVerified())
                .ifPresent(user -> {
                    user.setVerificationToken(UUID.randomUUID().toString());
                    users.save(user);
                    mailService.sendVerificationEmail(user.getEmail(), user.getVerificationToken());
                });
    }

    @Transactional
    public TokenResponse login(LoginRequest request) {
        User user = users.findByEmailIgnoreCase(request.email().trim())
                .orElseThrow(() -> ApiException.unauthorized("Invalid email or password."));
        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw ApiException.unauthorized("Invalid email or password.");
        }
        if (!user.isEmailVerified()) {
            throw ApiException.forbidden("Please verify your email address before signing in.");
        }
        return issueTokens(user);
    }

    @Transactional
    public TokenResponse refresh(String rawRefreshToken) {
        RefreshToken stored = refreshTokens.validate(rawRefreshToken)
                .orElseThrow(() -> ApiException.unauthorized("Invalid or expired refresh token."));
        User user = users.findById(stored.getUserId())
                .orElseThrow(() -> ApiException.unauthorized("Invalid refresh token."));
        refreshTokens.revoke(rawRefreshToken); // rotate: old token can't be reused
        return issueTokens(user);
    }

    @Transactional
    public void logout(String rawRefreshToken) {
        refreshTokens.revoke(rawRefreshToken);
    }

    @Transactional(readOnly = true)
    public ProfileResponse me(UUID userId) {
        User user = users.findById(userId)
                .orElseThrow(() -> ApiException.notFound("User not found."));
        return ProfileResponse.from(user);
    }

    @Transactional
    public ProfileResponse updateProfile(UUID userId, UpdateProfileRequest request) {
        User user = users.findById(userId)
                .orElseThrow(() -> ApiException.notFound("User not found."));
        if (request.username() != null) {
            String username = request.username().trim();
            if (!username.equalsIgnoreCase(user.getUsername()) && users.existsByUsernameIgnoreCase(username)) {
                throw ApiException.conflict("Username already exists.");
            }
            user.setUsername(username);
        }
        if (request.displayName() != null) {
            user.setDisplayName(request.displayName().trim());
        }
        users.saveAndFlush(user);
        return ProfileResponse.from(user);
    }

    private TokenResponse issueTokens(User user) {
        String accessToken = jwtService.issueAccessToken(user);
        String refreshToken = refreshTokens.issue(user.getId());
        return new TokenResponse(accessToken, refreshToken, "Bearer",
                jwtService.accessTokenTtlSeconds(), ProfileResponse.from(user));
    }
}
