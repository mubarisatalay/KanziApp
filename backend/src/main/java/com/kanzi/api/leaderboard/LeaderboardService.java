package com.kanzi.api.leaderboard;

import com.kanzi.api.challenge.Challenge;
import com.kanzi.api.challenge.ChallengeRepository;
import com.kanzi.api.challenge.Submission;
import com.kanzi.api.challenge.SubmissionRepository;
import com.kanzi.api.challenge.Vote;
import com.kanzi.api.challenge.VoteRepository;
import com.kanzi.api.common.AuthorizationService;
import com.kanzi.api.leaderboard.dto.LeaderboardEntry;
import com.kanzi.api.user.User;
import com.kanzi.api.user.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class LeaderboardService {

    private final ChallengeRepository challenges;
    private final SubmissionRepository submissions;
    private final VoteRepository votes;
    private final UserRepository users;
    private final AuthorizationService authz;

    public LeaderboardService(ChallengeRepository challenges, SubmissionRepository submissions,
                              VoteRepository votes, UserRepository users, AuthorizationService authz) {
        this.challenges = challenges;
        this.submissions = submissions;
        this.votes = votes;
        this.users = users;
        this.authz = authz;
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

        List<LeaderboardEntry> entries = new ArrayList<>(sorted.size());
        int rank = 0;
        int previousVotes = Integer.MIN_VALUE;
        for (int i = 0; i < sorted.size(); i++) {
            Aggregate a = sorted.get(i);
            if (a.totalVotes != previousVotes) {
                rank = i + 1; // competition ranking: 1, 2, 2, 4, ...
                previousVotes = a.totalVotes;
            }
            User u = usersById.get(a.userId);
            entries.add(new LeaderboardEntry(
                    a.userId,
                    u != null ? u.getUsername() : "Unknown",
                    u != null ? u.getDisplayName() : null,
                    u != null ? u.getAvatarUrl() : null,
                    a.totalVotes,
                    a.submissionCount,
                    rank));
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
