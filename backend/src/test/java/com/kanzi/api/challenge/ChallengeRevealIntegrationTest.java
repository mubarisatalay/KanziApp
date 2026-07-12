package com.kanzi.api.challenge;

import com.kanzi.api.challenge.dto.RevealResponse;
import com.kanzi.api.challenge.dto.SubmissionResponse;
import com.kanzi.api.common.ApiException;
import com.kanzi.api.room.Room;
import com.kanzi.api.room.RoomMember;
import com.kanzi.api.room.RoomMemberRepository;
import com.kanzi.api.room.RoomRepository;
import com.kanzi.api.user.User;
import com.kanzi.api.user.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.http.HttpStatus;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.postgresql.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Full-stack service-layer test against a real Postgres: Liquibase changelog 005 applies and
 * Hibernate validates on context boot; anonymization, sealing, 409 gating, ceremony ranking and
 * RevealJob idempotence are exercised through {@link ChallengeService}.
 */
@SpringBootTest
@Testcontainers
class ChallengeRevealIntegrationTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgres = new PostgreSQLContainer("postgres:15");

    @Autowired ChallengeService service;
    @Autowired ChallengeRepository challenges;
    @Autowired SubmissionRepository submissions;
    @Autowired UserRepository users;
    @Autowired RoomRepository rooms;
    @Autowired RoomMemberRepository members;
    @Autowired PoolChallengeRepository poolChallenges;
    @Autowired DailyChallengeJob dailyChallengeJob;
    @Autowired TransactionTemplate tx;

    // --- fixtures ---

    private User newUser(String tag) {
        User user = new User();
        String unique = tag + "-" + UUID.randomUUID();
        user.setEmail(unique + "@test.local");
        user.setUsername(unique);
        user.setDisplayName(tag);
        user.setPasswordHash("test-hash");
        user.setEmailVerified(true);
        return users.save(user);
    }

    private Room newRoom(User admin, User... memberUsers) {
        Room room = new Room();
        room.setName("room");
        room.setCode(UUID.randomUUID().toString().substring(0, 8));
        room.setCreatedBy(admin.getId());
        room = rooms.save(room);
        addMember(room, admin, RoomMember.ROLE_ADMIN);
        for (User u : memberUsers) {
            addMember(room, u, RoomMember.ROLE_MEMBER);
        }
        return room;
    }

    private void addMember(Room room, User user, String role) {
        RoomMember member = new RoomMember();
        member.setRoomId(room.getId());
        member.setUserId(user.getId());
        member.setRole(role);
        members.save(member);
    }

    private Challenge newChallenge(Room room, boolean blind, Instant revealAt) {
        Challenge challenge = new Challenge();
        challenge.setRoomId(room.getId());
        challenge.setChallengeText("test challenge");
        challenge.setChallengeType("text");
        challenge.setChallengeDate(LocalDate.now());
        challenge.setRevealAt(revealAt);
        challenge.setBlind(blind);
        return challenges.save(challenge);
    }

    private Submission newSubmission(Challenge challenge, User author, String text) {
        Submission submission = new Submission();
        submission.setChallengeId(challenge.getId());
        submission.setUserId(author.getId());
        submission.setRoomId(challenge.getRoomId());
        submission.setTextContent(text);
        return submissions.save(submission);
    }

    private void forceReveal(Challenge challenge) {
        challenge.setRevealAt(Instant.now().minusSeconds(60));
        challenges.save(challenge);
    }

    private Instant inOneHour() {
        return Instant.now().plusSeconds(3600);
    }

    private static void assertConflict(org.junit.jupiter.api.function.Executable call) {
        assertEquals(HttpStatus.CONFLICT, assertThrows(ApiException.class, call).getStatus());
    }

    // --- blind challenge, pre-reveal ---

    @Test
    void blindPreRevealHidesAuthorsButNeverContent() {
        User admin = newUser("admin");
        User alice = newUser("alice");
        User bob = newUser("bob");
        Room room = newRoom(admin, alice, bob);
        Challenge challenge = newChallenge(room, true, inOneHour());
        newSubmission(challenge, alice, "alice text");
        newSubmission(challenge, bob, "bob text");
        service.voteOnSubmission(
                submissions.findByChallengeIdOrderBySubmittedAt(challenge.getId()).getFirst().getId(),
                admin.getId(), 5);

        List<SubmissionResponse> seenByAdmin = service.getSubmissions(challenge.getId(), admin.getId());
        assertEquals(2, seenByAdmin.size());
        for (SubmissionResponse s : seenByAdmin) {
            assertTrue(s.anonymous());
            assertNull(s.userId());
            assertNull(s.username());
            assertNull(s.displayName());
            assertNull(s.avatarUrl());
            assertNotNull(s.textContent()); // content stays visible — it's what gets voted on
            assertEquals(0, s.totalVotes()); // aggregates sealed for everyone
            assertEquals(0, s.voteCount());
            assertFalse(s.ownSubmission());
        }
        // Voter still sees their own vote despite sealed aggregates.
        assertTrue(seenByAdmin.stream().anyMatch(s -> Integer.valueOf(5).equals(s.currentUserVote())));

        // The author's own entry stays fully identified.
        List<SubmissionResponse> seenByAlice = service.getSubmissions(challenge.getId(), alice.getId());
        SubmissionResponse own = seenByAlice.stream().filter(SubmissionResponse::ownSubmission)
                .findFirst().orElseThrow();
        assertFalse(own.anonymous());
        assertEquals(alice.getId(), own.userId());
        assertEquals(alice.getUsername(), own.username());
        SubmissionResponse other = seenByAlice.stream().filter(s -> !s.ownSubmission())
                .findFirst().orElseThrow();
        assertTrue(other.anonymous());

        // Stable shuffle: ordered by submission id, identical across reads.
        List<UUID> expectedOrder = submissions.findByChallengeIdOrderBySubmittedAt(challenge.getId()).stream()
                .map(Submission::getId)
                .sorted()
                .toList();
        assertEquals(expectedOrder, seenByAdmin.stream().map(SubmissionResponse::id).toList());
        assertEquals(expectedOrder, service.getSubmissions(challenge.getId(), admin.getId()).stream()
                .map(SubmissionResponse::id).toList());
    }

    @Test
    void nonBlindPreRevealShowsAuthorsButSealsAggregates() {
        User admin = newUser("admin");
        User alice = newUser("alice");
        Room room = newRoom(admin, alice);
        Challenge challenge = newChallenge(room, false, inOneHour());
        Submission submission = newSubmission(challenge, alice, "hello");
        service.voteOnSubmission(submission.getId(), admin.getId(), 4);

        SubmissionResponse seen = service.getSubmissions(challenge.getId(), admin.getId()).getFirst();
        assertFalse(seen.anonymous());
        assertEquals(alice.getId(), seen.userId());
        assertEquals(alice.getUsername(), seen.username());
        assertEquals(0, seen.totalVotes());
        assertEquals(0, seen.voteCount());
        assertEquals(4, seen.currentUserVote());
    }

    // --- gating ---

    @Test
    void revealResultsReturn409BeforeReveal() {
        User admin = newUser("admin");
        Room room = newRoom(admin);
        Challenge challenge = newChallenge(room, true, inOneHour());

        assertConflict(() -> service.getRevealResults(challenge.getId(), admin.getId()));
    }

    @Test
    void votesAndSubmissionsCloseAtReveal() {
        User admin = newUser("admin");
        User alice = newUser("alice");
        Room room = newRoom(admin, alice);
        Challenge challenge = newChallenge(room, false, inOneHour());
        Submission submission = newSubmission(challenge, alice, "hello");
        service.voteOnSubmission(submission.getId(), admin.getId(), 3);
        forceReveal(challenge);

        assertConflict(() -> service.voteOnSubmission(submission.getId(), admin.getId(), 5));
        assertConflict(() -> service.removeVote(submission.getId(), admin.getId()));
        assertConflict(() -> service.submitResponse(challenge.getId(), admin.getId(), "too late", null));
        assertConflict(() -> service.updateSubmission(submission.getId(), alice.getId(), "edited", null));
        assertConflict(() -> service.deleteSubmission(submission.getId(), alice.getId()));
    }

    // --- post-reveal ---

    @Test
    void afterRevealIdentityAggregatesAndRankingOpen() {
        User admin = newUser("admin");
        User alice = newUser("alice");
        User bob = newUser("bob");
        Room room = newRoom(admin, alice, bob);
        Challenge challenge = newChallenge(room, true, inOneHour());
        Submission alicesEntry = newSubmission(challenge, alice, "alice text");
        Submission bobsEntry = newSubmission(challenge, bob, "bob text");
        service.voteOnSubmission(alicesEntry.getId(), admin.getId(), 5);
        service.voteOnSubmission(alicesEntry.getId(), bob.getId(), 4);
        service.voteOnSubmission(bobsEntry.getId(), admin.getId(), 3);
        forceReveal(challenge);

        // Submissions list opens up.
        List<SubmissionResponse> seen = service.getSubmissions(challenge.getId(), admin.getId());
        SubmissionResponse aliceSeen = seen.stream()
                .filter(s -> alice.getId().equals(s.userId())).findFirst().orElseThrow();
        assertFalse(aliceSeen.anonymous());
        assertEquals(alice.getUsername(), aliceSeen.username());
        assertEquals(9, aliceSeen.totalVotes());
        assertEquals(2, aliceSeen.voteCount());

        // Ceremony: alice avg 4.5 beats bob avg 3.0.
        RevealResponse reveal = service.getRevealResults(challenge.getId(), bob.getId());
        assertEquals(2, reveal.totalSubmissions());
        assertEquals(alice.getId(), reveal.winner().userId());
        assertEquals(1, reveal.winner().rank());
        assertEquals(4.5, reveal.winner().avgScore());
        assertEquals(2, reveal.entries().get(1).rank());
        assertEquals(bob.getId(), reveal.entries().get(1).userId());
        assertEquals(2, reveal.currentUserRank()); // bob asked
        assertNull(service.getRevealResults(challenge.getId(), admin.getId()).currentUserRank());
    }

    @Test
    void ceremonyUsesCompetitionRankingOnTies() {
        User admin = newUser("admin");
        User alice = newUser("alice");
        User bob = newUser("bob");
        User cara = newUser("cara");
        Room room = newRoom(admin, alice, bob, cara);
        Challenge challenge = newChallenge(room, false, inOneHour());
        Submission a = newSubmission(challenge, alice, "a");
        Submission b = newSubmission(challenge, bob, "b");
        Submission c = newSubmission(challenge, cara, "c");
        // alice and bob tie exactly (same avg, same count); cara trails.
        service.voteOnSubmission(a.getId(), admin.getId(), 4);
        service.voteOnSubmission(b.getId(), admin.getId(), 4);
        service.voteOnSubmission(c.getId(), admin.getId(), 2);
        forceReveal(challenge);

        RevealResponse reveal = service.getRevealResults(challenge.getId(), admin.getId());
        assertEquals(1, reveal.entries().get(0).rank());
        assertEquals(1, reveal.entries().get(1).rank());
        assertEquals(3, reveal.entries().get(2).rank()); // 1, 1, 3 — competition ranking
    }

    @Test
    void ceremonyHandlesZeroSubmissionsAndZeroVotes() {
        User admin = newUser("admin");
        User alice = newUser("alice");
        Room room = newRoom(admin, alice);

        Challenge empty = newChallenge(room, false, Instant.now().minusSeconds(60));
        RevealResponse noEntries = service.getRevealResults(empty.getId(), admin.getId());
        assertTrue(noEntries.entries().isEmpty());
        assertNull(noEntries.winner());
        assertNull(noEntries.currentUserRank());

        Room otherRoom = newRoom(admin, alice);
        Challenge unvoted = newChallenge(otherRoom, false, inOneHour());
        newSubmission(unvoted, alice, "nobody voted");
        forceReveal(unvoted);
        RevealResponse noVotes = service.getRevealResults(unvoted.getId(), admin.getId());
        assertEquals(0.0, noVotes.winner().avgScore());
        assertEquals(1, noVotes.winner().rank());
    }

    // --- Daily challenge pool ---

    @Test
    void dailyJobDrawsFromSeededPool() {
        assertEquals(10, poolChallenges.count()); // changelog 006 seed

        User admin = newUser("admin");
        Room room = newRoom(admin);
        dailyChallengeJob.runNow();

        Challenge created = challenges
                .findByRoomIdAndChallengeDate(room.getId(), LocalDate.now(java.time.ZoneOffset.UTC))
                .orElseThrow();
        PoolChallenge origin = poolChallenges.findByActiveTrue().stream()
                .filter(p -> p.getChallengeText().equals(created.getChallengeText()))
                .findFirst().orElseThrow();
        assertEquals(origin.getChallengeType(), created.getChallengeType());
        assertEquals(origin.isBlind(), created.isBlind());
        assertNotNull(created.getRevealAt());

        // Idempotent: a second run creates nothing new for this room.
        dailyChallengeJob.runNow();
        assertEquals(1, challenges.findTop30ByRoomIdOrderByChallengeDateDesc(room.getId()).size());
    }

    // --- RevealJob ---

    @Test
    void revealJobFlipIsIdempotent() {
        User admin = newUser("admin");
        Room room = newRoom(admin);
        Challenge challenge = newChallenge(room, false, inOneHour());
        assertFalse(challenges.findById(challenge.getId()).orElseThrow().isRevealed());

        // Simulate the job at a time past this challenge's reveal_at.
        Instant simulatedNow = inOneHour().plusSeconds(60);
        int first = tx.execute(status -> challenges.markRevealed(simulatedNow));
        assertTrue(first >= 1);
        assertTrue(challenges.findById(challenge.getId()).orElseThrow().isRevealed());

        Integer second = tx.execute(status -> challenges.markRevealed(simulatedNow));
        assertEquals(0, second); // nothing left to flip — safe across restarts
    }
}
