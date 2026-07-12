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
import java.util.Optional;
import java.util.UUID;

/**
 * Creates one challenge per room per day, drawn from the first {@link ChallengeSource} (in bean
 * order) with something to offer. Today that's the curated DB pool; the user-submitted dare
 * pool will register as an earlier, room-scoped source without this job changing.
 */
@Component
public class DailyChallengeJob {

    private static final Logger log = LoggerFactory.getLogger(DailyChallengeJob.class);

    private final RoomRepository rooms;
    private final ChallengeRepository challenges;
    private final List<ChallengeSource> sources;
    private final RevealPolicy revealPolicy;

    public DailyChallengeJob(RoomRepository rooms, ChallengeRepository challenges,
                             List<ChallengeSource> sources, RevealPolicy revealPolicy) {
        this.rooms = rooms;
        this.challenges = challenges;
        this.sources = sources;
        this.revealPolicy = revealPolicy;
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
            Optional<ChallengeDraft> draft = draw(room.getId(), today);
            if (draft.isEmpty()) {
                log.warn("No challenge source could offer a prompt for room {} on {}", room.getId(), today);
                continue;
            }
            Challenge challenge = new Challenge();
            challenge.setRoomId(room.getId());
            challenge.setChallengeText(draft.get().challengeText());
            challenge.setChallengeType(draft.get().challengeType().db());
            challenge.setChallengeDate(today);
            challenge.setRevealAt(revealPolicy.revealAtFor(today));
            challenge.setBlind(draft.get().blind());
            challenges.save(challenge);
            created++;
        }
        log.info("Daily challenge job created {} challenge(s) for {}", created, today);
    }

    private Optional<ChallengeDraft> draw(UUID roomId, LocalDate date) {
        return sources.stream()
                .map(source -> source.draw(roomId, date))
                .flatMap(Optional::stream)
                .findFirst();
    }

    /**
     * Exposed so an admin/dev can trigger generation without waiting for the cron.
     */
    public void runNow() {
        createDailyChallenges();
    }
}
