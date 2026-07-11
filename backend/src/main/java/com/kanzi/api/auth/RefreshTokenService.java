package com.kanzi.api.auth;

import com.kanzi.api.config.AppProperties;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import java.util.Optional;
import java.util.UUID;

@Service
public class RefreshTokenService {

    private static final SecureRandom RANDOM = new SecureRandom();

    private final RefreshTokenRepository repository;
    private final AppProperties props;

    public RefreshTokenService(RefreshTokenRepository repository, AppProperties props) {
        this.repository = repository;
        this.props = props;
    }

    /** Persists the HASH of a fresh token and returns the RAW value for the client (shown once). */
    public String issue(UUID userId) {
        String raw = randomToken();
        RefreshToken token = new RefreshToken();
        token.setUserId(userId);
        token.setTokenHash(hash(raw));
        token.setExpiresAt(Instant.now().plus(props.jwt().refreshTokenTtl()));
        repository.save(token);
        return raw;
    }

    /** The stored token, only if the raw value matches and it hasn't expired. */
    public Optional<RefreshToken> validate(String rawToken) {
        return repository.findByTokenHash(hash(rawToken))
                .filter(t -> t.getExpiresAt().isAfter(Instant.now()));
    }

    @Transactional
    public void revoke(String rawToken) {
        repository.deleteByTokenHash(hash(rawToken));
    }

    private static String randomToken() {
        byte[] bytes = new byte[32];
        RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private static String hash(String raw) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(raw.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) {
            throw new IllegalStateException("SHA-256 unavailable", e);
        }
    }
}
