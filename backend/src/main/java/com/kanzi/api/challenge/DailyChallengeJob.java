package com.kanzi.api.challenge;

import com.kanzi.api.room.Room;
import com.kanzi.api.room.RoomRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;

@Component
public class DailyChallengeJob {

    private static final Logger log = LoggerFactory.getLogger(DailyChallengeJob.class);

    private static final List<String> POOL = List.of(
            "Take the most cringe photo today.",
            "Take a photo with the youngest person you saw today.",
            "Share the most meaningful proverb you know.",
            "Capture the most beautiful sunset you see.",
            "Show us your weirdest possession.",
            "Take a photo of something that made you smile today.",
            "Share a childhood memory in one sentence.",
            "Take a photo of your view right now.",
            "What is your biggest fear? Explain in one sentence.",
            "Take a selfie with a stranger (with permission!).");

    private static final List<String> TYPES = List.of(
            "photo", "text", "photo_text", "photo", "photo", "photo", "text", "photo", "text", "photo");

    private final RoomRepository rooms;
    private final ChallengeRepository challenges;

    public DailyChallengeJob(RoomRepository rooms, ChallengeRepository challenges) {
        this.rooms = rooms;
        this.challenges = challenges;
    }

    @Scheduled(cron = "${app.daily-challenge.cron}", zone = "UTC")
    @Transactional
    public void createDailyChallenges() {
        LocalDate today = LocalDate.now(ZoneOffset.UTC);
        int created = 0;
        for (Room room : rooms.findAll()) {
            if (challenges.existsByRoomIdAndChallengeDate(room.getId(), today)) {
                continue; // idempotent — mirrors ON CONFLICT DO NOTHING
            }
            int index = ThreadLocalRandom.current().nextInt(POOL.size());
            Challenge challenge = new Challenge();
            challenge.setRoomId(room.getId());
            challenge.setChallengeText(POOL.get(index));
            challenge.setChallengeType(TYPES.get(index));
            challenge.setChallengeDate(today);
            challenges.save(challenge);
            created++;
        }
        log.info("Daily challenge job created {} challenge(s) for {}", created, today);
    }

    /**
     * Exposed so an admin/dev can trigger generation without waiting for the cron.
     */
    public void runNow() {
        createDailyChallenges();
    }
}
