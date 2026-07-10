package com.kanzi.api.challenge;

import java.util.Arrays;
import java.util.Optional;

/** Mirrors the DB CHECK constraint on challenges.challenge_type. */
public enum ChallengeType {
    PHOTO("photo"),
    TEXT("text"),
    PHOTO_TEXT("photo_text");

    private final String db;

    ChallengeType(String db) {
        this.db = db;
    }

    public String db() {
        return db;
    }

    public static Optional<ChallengeType> fromDb(String value) {
        return Arrays.stream(values()).filter(t -> t.db.equals(value)).findFirst();
    }
}
