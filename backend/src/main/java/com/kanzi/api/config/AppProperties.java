package com.kanzi.api.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.time.Duration;

/** Typed binding for the {@code app.*} configuration in application.yml. */
@ConfigurationProperties(prefix = "app")
public record AppProperties(String baseUrl, Mail mail, Jwt jwt, Storage storage, DailyChallenge dailyChallenge) {

    public record Mail(String from) {
    }

    public record Jwt(Duration accessTokenTtl, Duration refreshTokenTtl) {
    }

    public record Storage(String endpoint, String publicUrl, String region, String bucket,
                          String accessKey, String secretKey) {
    }

    public record DailyChallenge(String cron) {
    }
}
