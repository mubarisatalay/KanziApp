package com.kanzi.api.leaderboard;

import com.kanzi.api.challenge.Challenge;
import com.kanzi.api.challenge.ChallengeRepository;
import com.kanzi.api.challenge.Submission;
import com.kanzi.api.challenge.SubmissionRepository;
import com.kanzi.api.challenge.Vote;
import com.kanzi.api.challenge.VoteRepository;
import com.kanzi.api.common.AuthorizationService;
import com.kanzi.api.common.Rankings;
import com.kanzi.api.leaderboard.dto.LeaderboardEntry;
import com.kanzi.api.leaderboard.dto.WeeklyMvpEntry;
import com.kanzi.api.room.Room;
import com.kanzi.api.room.RoomMember;
import com.kanzi.api.room.RoomRepository;
import com.kanzi.api.room.RoomMemberRepository;
import com.kanzi.api.user.User;
import com.kanzi.api.user.UserRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class LeaderboardService {

    private final ChallengeRepository challenges;
    private final SubmissionRepository submissions;
    private final VoteRepository votes;
    private final UserRepository users;
    private final RoomMemberRepository members;
    private final RoomRepository rooms;
    private final AuthorizationService authz;
    private final ZoneId zone;

    public LeaderboardService(ChallengeRepository challenges, SubmissionRepository submissions,
                              VoteRepository votes, UserRepository users, RoomMemberRepository members,
                              RoomRepository rooms, AuthorizationService authz,
                              @Value("${app.reveal.zone:Europe/Istanbul}") String zoneId) {
        this.challenges = challenges;
        this.submissions = submissions;
        this.votes = votes;
        this.users = users;
        this.members = members;
        this.rooms = rooms;
        this.authz = authz;
        this.zone = ZoneId.of(zoneId);
    }

    @Transactional(readOnly = true)
    public List<LeaderboardEntry> daily(UUID roomId, UUID userId, LocalDate date) {
        authz.assertMember(roomId, userId);
        return challenges.findByRoomIdAndChallengeDate(roomId, date)
                .map(Challenge::getId)
                .map(submissions::findByChallengeIdOrderBySubmittedAt)
                .map(this::rank)
                .orElseGet(List::of);
    }

    @Transactional(readOnly = true)
    public List<LeaderboardEntry> overall(UUID roomId, UUID userId) {
        authz.assertMember(roomId, userId);
        return rank(submissions.findByRoomId(roomId));
    }

    // ── Weekly MVP ────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<WeeklyMvpEntry> weeklyRoom(UUID roomId, UUID userId) {
        authz.assertMember(roomId, userId);

        LocalDate weekStart = LocalDate.now(zone).with(DayOfWeek.MONDAY);
        LocalDate weekEnd = weekStart.plusDays(6);

        List<Challenge> weekChallenges = challenges.findByRoomIdAndChallengeDateBetween(roomId, weekStart, weekEnd);
        if (weekChallenges.isEmpty()) return List.of();

        long memberCount = members.countByRoomId(roomId);
        long eligible = Math.max(memberCount - 1, 1);

        List<UUID> challengeIds = weekChallenges.stream().map(Challenge::getId).toList();
        List<Submission> weekSubs = submissions.findByChallengeIdIn(challengeIds);
        if (weekSubs.isEmpty()) return List.of();

        List<UUID> subIds = weekSubs.stream().map(Submission::getId).toList();
        Map<UUID, Integer> votesBySubmission = votes.findBySubmissionIdIn(subIds).stream()
                .collect(Collectors.groupingBy(Vote::getSubmissionId, Collectors.summingInt(Vote::getVoteValue)));

        Map<UUID, MvpAggregate> byUser = new LinkedHashMap<>();
        for (Submission s : weekSubs) {
            MvpAggregate agg = byUser.computeIfAbsent(s.getUserId(), MvpAggregate::new);
            int raw = votesBySubmission.getOrDefault(s.getId(), 0);
            agg.addScore(raw / (eligible * 5.0) * 10.0);
        }

        Map<UUID, User> usersById = users.findAllById(byUser.keySet()).stream()
                .collect(Collectors.toMap(User::getId, Function.identity()));
        return buildMvpEntries(byUser, usersById, null);
    }

    /** Platform-wide weekly MVP — all rooms, normalized so room size doesn't matter. */
    @Transactional(readOnly = true)
    public List<WeeklyMvpEntry> weeklyGlobal(UUID requestingUserId) {
        List<UUID> allRoomIds = rooms.findAll().stream().map(Room::getId).toList();
        if (allRoomIds.isEmpty()) return List.of();

        LocalDate weekStart = LocalDate.now(zone).with(DayOfWeek.MONDAY);
        LocalDate weekEnd = weekStart.plusDays(6);

        List<Challenge> weekChallenges = challenges.findByRoomIdInAndChallengeDateBetween(allRoomIds, weekStart, weekEnd);
        if (weekChallenges.isEmpty()) return List.of();

        // Member count per room for normalization
        Map<UUID, Long> memberCountByRoom = members.findByRoomIdIn(allRoomIds).stream()
                .collect(Collectors.groupingBy(RoomMember::getRoomId, Collectors.counting()));

        Map<UUID, UUID> roomByChallenge = weekChallenges.stream()
                .collect(Collectors.toMap(Challenge::getId, Challenge::getRoomId));

        List<UUID> challengeIds = weekChallenges.stream().map(Challenge::getId).toList();
        List<Submission> allSubs = submissions.findByChallengeIdIn(challengeIds);
        if (allSubs.isEmpty()) return List.of();

        List<UUID> subIds = allSubs.stream().map(Submission::getId).toList();
        Map<UUID, Integer> votesBySubmission = votes.findBySubmissionIdIn(subIds).stream()
                .collect(Collectors.groupingBy(Vote::getSubmissionId, Collectors.summingInt(Vote::getVoteValue)));

        Map<UUID, MvpAggregate> byUser = new LinkedHashMap<>();
        Map<UUID, Set<UUID>> roomsByUser = new HashMap<>();

        for (Submission s : allSubs) {
            UUID roomId = roomByChallenge.get(s.getChallengeId());
            long memberCount = memberCountByRoom.getOrDefault(roomId, 2L);
            long eligible = Math.max(memberCount - 1, 1);
            MvpAggregate agg = byUser.computeIfAbsent(s.getUserId(), MvpAggregate::new);
            int raw = votesBySubmission.getOrDefault(s.getId(), 0);
            agg.addScore(raw / (eligible * 5.0) * 10.0);
            roomsByUser.computeIfAbsent(s.getUserId(), k -> new HashSet<>()).add(roomId);
        }

        Map<UUID, String> roomContext = byUser.keySet().stream().collect(Collectors.toMap(
                uid -> uid,
                uid -> {
                    int count = roomsByUser.getOrDefault(uid, Set.of()).size();
                    return count + " room" + (count == 1 ? "" : "s");
                }));

        Map<UUID, User> usersById = users.findAllById(byUser.keySet()).stream()
                .collect(Collectors.toMap(User::getId, Function.identity()));
        return buildMvpEntries(byUser, usersById, roomContext);
    }

    private List<WeeklyMvpEntry> buildMvpEntries(Map<UUID, MvpAggregate> byUser,
                                                   Map<UUID, User> usersById,
                                                   Map<UUID, String> roomContext) {
        List<MvpAggregate> sorted = byUser.values().stream()
                .sorted(Comparator.comparingDouble(MvpAggregate::avgScore).reversed())
                .toList();

        List<WeeklyMvpEntry> result = new ArrayList<>(sorted.size());
        int rank = 1;
        for (int i = 0; i < sorted.size(); i++) {
            if (i > 0 && Math.abs(sorted.get(i).avgScore() - sorted.get(i - 1).avgScore()) >= 0.01) {
                rank = i + 1;
            }
            MvpAggregate a = sorted.get(i);
            User u = usersById.get(a.userId);
            result.add(new WeeklyMvpEntry(
                    a.userId,
                    u != null ? u.getUsername() : "Unknown",
                    u != null ? u.getDisplayName() : null,
                    u != null ? u.getAvatarUrl() : null,
                    Math.round(a.avgScore() * 10.0) / 10.0,
                    a.count,
                    rank,
                    roomContext != null ? roomContext.get(a.userId) : null));
        }
        return result;
    }

    private static final class MvpAggregate {
        final UUID userId;
        double totalScore;
        int count;

        MvpAggregate(UUID userId) { this.userId = userId; }

        void addScore(double s) { totalScore += s; count++; }

        double avgScore() { return count == 0 ? 0 : totalScore / count; }
    }

    // ── Legacy ranked leaderboard ─────────────────────────────────────────────

    /** Aggregate votes per user, then assign competition ranks (ties share a rank), matching get_daily_leaderboard. */
    private List<LeaderboardEntry> rank(List<Submission> subs) {
        if (subs.isEmpty()) {
            return List.of();
        }

        List<UUID> submissionIds = subs.stream().map(Submission::getId).toList();
        Map<UUID, Integer> votesBySubmission = votes.findBySubmissionIdIn(submissionIds).stream()
                .collect(Collectors.groupingBy(Vote::getSubmissionId, Collectors.summingInt(Vote::getVoteValue)));

        Map<UUID, Aggregate> byUser = new LinkedHashMap<>();
        for (Submission s : subs) {
            Aggregate agg = byUser.computeIfAbsent(s.getUserId(), Aggregate::new);
            agg.submissionCount++;
            agg.totalVotes += votesBySubmission.getOrDefault(s.getId(), 0);
        }

        Map<UUID, User> usersById = users.findAllById(byUser.keySet()).stream()
                .collect(Collectors.toMap(User::getId, Function.identity()));

        List<Aggregate> sorted = byUser.values().stream()
                .sorted(Comparator.comparingInt((Aggregate a) -> a.totalVotes).reversed())
                .toList();

        int[] ranks = Rankings.competitionRanks(sorted, (a, b) -> a.totalVotes == b.totalVotes);
        List<LeaderboardEntry> entries = new ArrayList<>(sorted.size());
        for (int i = 0; i < sorted.size(); i++) {
            Aggregate a = sorted.get(i);
            User u = usersById.get(a.userId);
            entries.add(new LeaderboardEntry(
                    a.userId,
                    u != null ? u.getUsername() : "Unknown",
                    u != null ? u.getDisplayName() : null,
                    u != null ? u.getAvatarUrl() : null,
                    a.totalVotes,
                    a.submissionCount,
                    ranks[i]));
        }
        return entries;
    }

    private static final class Aggregate {
        final UUID userId;
        int totalVotes;
        int submissionCount;

        Aggregate(UUID userId) {
            this.userId = userId;
        }
    }
}
