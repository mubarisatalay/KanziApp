package com.kanzi.api.challenge;

import com.kanzi.api.challenge.dto.ChallengeResponse;
import com.kanzi.api.challenge.dto.CreateChallengeRequest;
import com.kanzi.api.challenge.dto.RevealEntry;
import com.kanzi.api.challenge.dto.RevealResponse;
import com.kanzi.api.challenge.dto.SubmissionResponse;
import com.kanzi.api.common.ApiException;
import com.kanzi.api.common.AuthorizationService;
import com.kanzi.api.common.Rankings;
import com.kanzi.api.storage.StorageService;
import com.kanzi.api.user.User;
import com.kanzi.api.user.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class ChallengeService {

    private final ChallengeRepository challenges;
    private final SubmissionRepository submissions;
    private final VoteRepository votes;
    private final UserRepository users;
    private final AuthorizationService authz;
    private final StorageService storage;
    private final RevealPolicy revealPolicy;

    public ChallengeService(ChallengeRepository challenges, SubmissionRepository submissions, VoteRepository votes,
                            UserRepository users, AuthorizationService authz, StorageService storage,
                            RevealPolicy revealPolicy) {
        this.challenges = challenges;
        this.submissions = submissions;
        this.votes = votes;
        this.users = users;
        this.authz = authz;
        this.storage = storage;
        this.revealPolicy = revealPolicy;
    }

    // --- Challenges ---

    @Transactional(readOnly = true)
    public ChallengeResponse getTodayChallenge(UUID roomId, UUID userId) {
        authz.assertMember(roomId, userId);
        return challenges.findByRoomIdAndChallengeDate(roomId, LocalDate.now(ZoneOffset.UTC))
                .map(c -> toChallengeResponse(c,
                        submissions.existsByChallengeIdAndUserId(c.getId(), userId),
                        (int) submissions.countByChallengeId(c.getId())))
                .orElse(null);
    }

    @Transactional(readOnly = true)
    public List<ChallengeResponse> getChallengeHistory(UUID roomId, UUID userId) {
        authz.assertMember(roomId, userId);
        List<Challenge> history = challenges.findTop30ByRoomIdOrderByChallengeDateDesc(roomId);
        if (history.isEmpty()) {
            return List.of();
        }
        List<UUID> ids = history.stream().map(Challenge::getId).toList();
        List<Submission> subs = submissions.findByChallengeIdIn(ids);
        Set<UUID> submittedByMe = subs.stream()
                .filter(s -> s.getUserId().equals(userId))
                .map(Submission::getChallengeId)
                .collect(Collectors.toSet());
        Map<UUID, Long> countByChallenge = subs.stream()
                .collect(Collectors.groupingBy(Submission::getChallengeId, Collectors.counting()));
        return history.stream()
                .map(c -> toChallengeResponse(c,
                        submittedByMe.contains(c.getId()),
                        countByChallenge.getOrDefault(c.getId(), 0L).intValue()))
                .toList();
    }

    @Transactional(readOnly = true)
    public ChallengeResponse getChallengeById(UUID challengeId, UUID userId) {
        Challenge challenge = requireChallenge(challengeId);
        authz.assertMember(challenge.getRoomId(), userId);
        return toChallengeResponse(challenge,
                submissions.existsByChallengeIdAndUserId(challengeId, userId),
                (int) submissions.countByChallengeId(challengeId));
    }

    @Transactional
    public ChallengeResponse createChallenge(UUID roomId, UUID userId, CreateChallengeRequest request) {
        authz.assertAdmin(roomId, userId);
        ChallengeType type = ChallengeType.fromDb(request.challengeType())
                .orElseThrow(() -> ApiException.badRequest("Invalid challenge type: " + request.challengeType()));
        if (challenges.existsByRoomIdAndChallengeDate(roomId, request.challengeDate())) {
            throw ApiException.conflict("A challenge already exists for this date.");
        }
        Challenge challenge = new Challenge();
        challenge.setRoomId(roomId);
        challenge.setChallengeText(request.challengeText().trim());
        challenge.setChallengeType(type.db());
        challenge.setChallengeDate(request.challengeDate());
        challenge.setScheduledAt(revealPolicy.scheduledAtFor(request.challengeDate()));
        challenge.setRevealAt(revealPolicy.revealAtFor(request.challengeDate()));
        challenge.setBlind(request.blindOrDefault());
        challenges.saveAndFlush(challenge);
        return toChallengeResponse(challenge, false, 0);
    }

    // --- Submissions ---

    @Transactional(readOnly = true)
    public List<SubmissionResponse> getSubmissions(UUID challengeId, UUID userId) {
        Challenge challenge = requireChallenge(challengeId);
        authz.assertMember(challenge.getRoomId(), userId);

        List<Submission> subs = submissions.findByChallengeIdOrderBySubmittedAt(challengeId);
        if (subs.isEmpty()) {
            return List.of();
        }
        boolean revealed = revealPolicy.isRevealed(challenge);
        boolean authorsHidden = challenge.isBlind() && !revealed;
        if (authorsHidden) {
            // Stable pseudo-random shuffle: submission ids are gen_random_uuid(), so ordering by
            // id is deterministic across refreshes yet uncorrelated with submission time.
            subs = subs.stream()
                    .sorted(Comparator.comparing(Submission::getId))
                    .toList();
        }
        List<UUID> submissionIds = subs.stream().map(Submission::getId).toList();
        // While authors are hidden, only the caller's own entry shows identity — skip loading the rest.
        List<UUID> userIds = authorsHidden
                ? List.of(userId)
                : subs.stream().map(Submission::getUserId).toList();
        // Pre-reveal, aggregates are sealed and only the caller's own vote is served — don't load the rest.
        List<Vote> voteRows = revealed
                ? votes.findBySubmissionIdIn(submissionIds)
                : votes.findBySubmissionIdInAndVoterId(submissionIds, userId);

        Map<UUID, User> usersById = authorsOf(userIds);
        Map<UUID, List<Vote>> votesBySubmission = voteRows.stream()
                .collect(Collectors.groupingBy(Vote::getSubmissionId));

        return subs.stream()
                .map(s -> toResponse(s, usersById.get(s.getUserId()),
                        votesBySubmission.getOrDefault(s.getId(), List.of()), userId, challenge, revealed))
                .toList();
    }

    @Transactional
    public SubmissionResponse submitResponse(UUID challengeId, UUID userId, String textContent, MultipartFile image) {
        Challenge challenge = requireChallenge(challengeId);
        authz.assertMember(challenge.getRoomId(), userId);

        assertSubmissionsOpen(challenge);

        boolean hasText = textContent != null && !textContent.trim().isEmpty();
        boolean hasImage = image != null && !image.isEmpty();
        if (!hasText && !hasImage) {
            throw ApiException.badRequest("Provide text, an image, or both.");
        }
        if (submissions.existsByChallengeIdAndUserId(challengeId, userId)) {
            throw ApiException.conflict("You have already submitted a response to this challenge.");
        }

        Submission submission = new Submission();
        submission.setChallengeId(challengeId);
        submission.setUserId(userId);
        submission.setRoomId(challenge.getRoomId());
        submission.setTextContent(hasText ? textContent.trim() : null);
        if (hasImage) {
            submission.setImageUrl(storage.uploadChallengeImage(image, challenge.getRoomId(), challengeId));
        }
        submissions.saveAndFlush(submission);

        // assertSubmissionsOpen above guarantees we're pre-reveal here.
        return toResponse(submission, users.findById(userId).orElse(null), List.of(), userId, challenge, false);
    }

    @Transactional
    public SubmissionResponse updateSubmission(UUID submissionId, UUID userId, String textContent, MultipartFile image) {
        Submission submission = requireSubmission(submissionId);
        if (!submission.getUserId().equals(userId)) {
            throw ApiException.forbidden("You can only edit your own submission.");
        }
        Challenge challenge = requireChallenge(submission.getChallengeId());
        assertSubmissionsOpen(challenge);
        boolean hasText = textContent != null;
        boolean hasImage = image != null && !image.isEmpty();
        if (!hasText && !hasImage) {
            throw ApiException.badRequest("Nothing to update.");
        }
        if (hasText) {
            submission.setTextContent(textContent.trim());
        }
        if (hasImage) {
            submission.setImageUrl(storage.uploadChallengeImage(
                    image, submission.getRoomId(), submission.getChallengeId()));
        }
        submissions.saveAndFlush(submission);

        List<Vote> submissionVotes = votes.findBySubmissionIdIn(List.of(submission.getId()));
        // assertSubmissionsOpen above guarantees we're pre-reveal here.
        return toResponse(submission, users.findById(userId).orElse(null), submissionVotes, userId, challenge, false);
    }

    @Transactional
    public void deleteSubmission(UUID submissionId, UUID userId) {
        Submission submission = requireSubmission(submissionId);
        if (!submission.getUserId().equals(userId)) {
            throw ApiException.forbidden("You can only delete your own submission.");
        }
        assertSubmissionsOpen(requireChallenge(submission.getChallengeId()));
        submissions.delete(submission); // votes removed via FK ON DELETE CASCADE
    }

    // --- Votes ---

    @Transactional
    public void voteOnSubmission(UUID submissionId, UUID userId, int voteValue) {
        Submission submission = requireSubmission(submissionId);
        authz.assertMember(submission.getRoomId(), userId);
        assertVotingOpen(requireChallenge(submission.getChallengeId()));
        if (submission.getUserId().equals(userId)) {
            throw ApiException.badRequest("You cannot vote on your own submission.");
        }
        Vote vote = votes.findBySubmissionIdAndVoterId(submissionId, userId)
                .orElseGet(() -> {
                    Vote v = new Vote();
                    v.setSubmissionId(submissionId);
                    v.setVoterId(userId);
                    return v;
                });
        vote.setVoteValue(voteValue);
        votes.save(vote);
    }

    @Transactional
    public void removeVote(UUID submissionId, UUID userId) {
        Submission submission = requireSubmission(submissionId);
        authz.assertMember(submission.getRoomId(), userId);
        assertVotingOpen(requireChallenge(submission.getChallengeId()));
        votes.deleteBySubmissionIdAndVoterId(submissionId, userId);
    }

    // --- Reveal ceremony ---

    @Transactional(readOnly = true)
    public RevealResponse getRevealResults(UUID challengeId, UUID userId) {
        Challenge challenge = requireChallenge(challengeId);
        authz.assertMember(challenge.getRoomId(), userId);
        if (!revealPolicy.isRevealed(challenge)) {
            throw ApiException.conflict("Results are not revealed yet.");
        }

        List<Submission> subs = submissions.findByChallengeIdOrderBySubmittedAt(challengeId);
        if (subs.isEmpty()) {
            return new RevealResponse(challenge.getId(), challenge.getChallengeText(),
                    challenge.getChallengeType(), challenge.getChallengeDate(), challenge.getRevealAt(),
                    List.of(), null, null, 0);
        }
        Map<UUID, User> usersById = authorsOf(subs.stream().map(Submission::getUserId).toList());
        Map<UUID, List<Vote>> votesBySubmission = votes
                .findBySubmissionIdIn(subs.stream().map(Submission::getId).toList())
                .stream().collect(Collectors.groupingBy(Vote::getSubmissionId));

        List<Scored> scored = subs.stream()
                .map(s -> {
                    List<Vote> vs = votesBySubmission.getOrDefault(s.getId(), List.of());
                    return new Scored(s, usersById.get(s.getUserId()),
                            vs.stream().mapToInt(Vote::getVoteValue).sum(), vs.size());
                })
                .toList();

        List<RevealEntry> entries = rank(scored);
        RevealEntry winner = entries.isEmpty() ? null : entries.getFirst();
        Integer currentUserRank = entries.stream()
                .filter(e -> userId.equals(e.userId()))
                .map(RevealEntry::rank)
                .findFirst()
                .orElse(null);
        return new RevealResponse(challenge.getId(), challenge.getChallengeText(),
                challenge.getChallengeType(), challenge.getChallengeDate(), challenge.getRevealAt(),
                entries, winner, currentUserRank, entries.size());
    }

    /** A submission with its computed vote stats, pre-ranking. */
    private record Scored(Submission submission, User author, int totalVotes, int voteCount) {

        double avgScore() {
            return voteCount == 0 ? 0.0 : totalVotes / (double) voteCount;
        }

        RevealEntry toEntry(int rank) {
            return new RevealEntry(rank, submission.getId(), submission.getUserId(),
                    author != null ? author.getUsername() : null,
                    author != null ? author.getDisplayName() : null,
                    author != null ? author.getAvatarUrl() : null,
                    submission.getImageUrl(), submission.getTextContent(), submission.getSubmittedAt(),
                    avgScore(), voteCount, totalVotes);
        }
    }

    /**
     * Orders by avgScore desc, voteCount desc (more votes wins a tie), submittedAt asc. Entries
     * share a rank only when both avgScore and voteCount are equal; submittedAt merely orders
     * their display.
     */
    private static List<RevealEntry> rank(List<Scored> scored) {
        List<Scored> ordered = scored.stream()
                .sorted(Comparator.comparingDouble(Scored::avgScore).reversed()
                        .thenComparing(Comparator.comparingInt(Scored::voteCount).reversed())
                        .thenComparing(s -> s.submission().getSubmittedAt()))
                .toList();
        int[] ranks = Rankings.competitionRanks(ordered,
                (a, b) -> a.avgScore() == b.avgScore() && a.voteCount() == b.voteCount());
        List<RevealEntry> entries = new ArrayList<>(ordered.size());
        for (int i = 0; i < ordered.size(); i++) {
            entries.add(ordered.get(i).toEntry(ranks[i]));
        }
        return entries;
    }

    // --- helpers ---

    private Challenge requireChallenge(UUID challengeId) {
        return challenges.findById(challengeId)
                .orElseThrow(() -> ApiException.notFound("Challenge not found."));
    }

    private Submission requireSubmission(UUID submissionId) {
        return submissions.findById(submissionId)
                .orElseThrow(() -> ApiException.notFound("Submission not found."));
    }

    private void assertVotingOpen(Challenge challenge) {
        assertScheduled(challenge, "Voting is");
        assertBeforeReveal(challenge, "Voting is");
    }

    private void assertSubmissionsOpen(Challenge challenge) {
        assertScheduled(challenge, "Submissions are");
        assertBeforeReveal(challenge, "Submissions are");
    }

    private void assertScheduled(Challenge challenge, String subject) {
        if (!revealPolicy.isScheduled(challenge)) {
            throw ApiException.conflict(subject + " not open yet — the challenge hasn't started.");
        }
    }

    private void assertBeforeReveal(Challenge challenge, String subject) {
        if (revealPolicy.isRevealed(challenge)) {
            throw ApiException.conflict(subject + " closed — this challenge has been revealed.");
        }
    }

    /** Bulk-load users keyed by id (submission author lookup for both the list and the ceremony). */
    private Map<UUID, User> authorsOf(List<UUID> userIds) {
        return users.findAllById(userIds).stream()
                .collect(Collectors.toMap(User::getId, Function.identity()));
    }

    /** Central place deriving {@code revealed} for challenge DTOs — time-based, never the lagging entity flag. */
    private ChallengeResponse toChallengeResponse(Challenge challenge, boolean hasSubmitted, int submissionCount) {
        return ChallengeResponse.from(challenge, revealPolicy.isRevealed(challenge), hasSubmitted, submissionCount);
    }

    /**
     * Pre-reveal, vote aggregates are sealed for everyone (suspense until the ceremony) and, on
     * blind challenges, other members' author identity is hidden — never the content itself.
     * {@code revealed} is sampled once per request by the caller so a reveal moment crossing
     * mid-request can't produce a half-anonymized response.
     */
    private SubmissionResponse toResponse(Submission s, User author, List<Vote> submissionVotes,
                                          UUID currentUserId, Challenge challenge, boolean revealed) {
        boolean own = s.getUserId().equals(currentUserId);
        boolean anonymous = challenge.isBlind() && !revealed && !own;
        int totalVotes = revealed ? submissionVotes.stream().mapToInt(Vote::getVoteValue).sum() : 0;
        int voteCount = revealed ? submissionVotes.size() : 0;
        Integer currentUserVote = submissionVotes.stream()
                .filter(v -> v.getVoterId().equals(currentUserId))
                .map(Vote::getVoteValue)
                .findFirst()
                .orElse(null);
        return new SubmissionResponse(
                s.getId(),
                s.getChallengeId(),
                anonymous ? null : s.getUserId(),
                s.getRoomId(),
                s.getImageUrl(),
                s.getTextContent(),
                s.getSubmittedAt(),
                !anonymous && author != null ? author.getUsername() : null,
                !anonymous && author != null ? author.getDisplayName() : null,
                !anonymous && author != null ? author.getAvatarUrl() : null,
                totalVotes,
                voteCount,
                currentUserVote,
                own,
                anonymous
        );
    }
}
