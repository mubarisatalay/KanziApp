package com.kanzi.api.challenge;

import com.kanzi.api.challenge.dto.ChallengeResponse;
import com.kanzi.api.challenge.dto.CreateChallengeRequest;
import com.kanzi.api.challenge.dto.SubmissionResponse;
import com.kanzi.api.common.ApiException;
import com.kanzi.api.common.AuthorizationService;
import com.kanzi.api.storage.StorageService;
import com.kanzi.api.user.User;
import com.kanzi.api.user.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDate;
import java.time.ZoneOffset;
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

    public ChallengeService(ChallengeRepository challenges, SubmissionRepository submissions, VoteRepository votes,
                            UserRepository users, AuthorizationService authz, StorageService storage) {
        this.challenges = challenges;
        this.submissions = submissions;
        this.votes = votes;
        this.users = users;
        this.authz = authz;
        this.storage = storage;
    }

    // --- Challenges ---

    @Transactional(readOnly = true)
    public ChallengeResponse getTodayChallenge(UUID roomId, UUID userId) {
        authz.assertMember(roomId, userId);
        return challenges.findByRoomIdAndChallengeDate(roomId, LocalDate.now(ZoneOffset.UTC))
                .map(c -> ChallengeResponse.from(c,
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
                .map(c -> ChallengeResponse.from(c,
                        submittedByMe.contains(c.getId()),
                        countByChallenge.getOrDefault(c.getId(), 0L).intValue()))
                .toList();
    }

    @Transactional(readOnly = true)
    public ChallengeResponse getChallengeById(UUID challengeId, UUID userId) {
        Challenge challenge = requireChallenge(challengeId);
        authz.assertMember(challenge.getRoomId(), userId);
        return ChallengeResponse.from(challenge,
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
        challenges.saveAndFlush(challenge);
        return ChallengeResponse.from(challenge, false, 0);
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
        List<UUID> submissionIds = subs.stream().map(Submission::getId).toList();
        List<UUID> userIds = subs.stream().map(Submission::getUserId).toList();

        Map<UUID, User> usersById = users.findAllById(userIds).stream()
                .collect(Collectors.toMap(User::getId, Function.identity()));
        Map<UUID, List<Vote>> votesBySubmission = votes.findBySubmissionIdIn(submissionIds).stream()
                .collect(Collectors.groupingBy(Vote::getSubmissionId));

        return subs.stream()
                .map(s -> toResponse(s, usersById.get(s.getUserId()),
                        votesBySubmission.getOrDefault(s.getId(), List.of()), userId))
                .toList();
    }

    @Transactional
    public SubmissionResponse submitResponse(UUID challengeId, UUID userId, String textContent, MultipartFile image) {
        Challenge challenge = requireChallenge(challengeId);
        authz.assertMember(challenge.getRoomId(), userId);

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
            submission.setImageUrl(storage.uploadChallengeImage(image, challenge.getRoomId(), challengeId, userId));
        }
        submissions.saveAndFlush(submission);

        return toResponse(submission, users.findById(userId).orElse(null), List.of(), userId);
    }

    @Transactional
    public SubmissionResponse updateSubmission(UUID submissionId, UUID userId, String textContent, MultipartFile image) {
        Submission submission = requireSubmission(submissionId);
        if (!submission.getUserId().equals(userId)) {
            throw ApiException.forbidden("You can only edit your own submission.");
        }
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
                    image, submission.getRoomId(), submission.getChallengeId(), userId));
        }
        submissions.saveAndFlush(submission);

        List<Vote> submissionVotes = votes.findBySubmissionIdIn(List.of(submission.getId()));
        return toResponse(submission, users.findById(userId).orElse(null), submissionVotes, userId);
    }

    @Transactional
    public void deleteSubmission(UUID submissionId, UUID userId) {
        Submission submission = requireSubmission(submissionId);
        if (!submission.getUserId().equals(userId)) {
            throw ApiException.forbidden("You can only delete your own submission.");
        }
        submissions.delete(submission); // votes removed via FK ON DELETE CASCADE
    }

    // --- Votes ---

    @Transactional
    public void voteOnSubmission(UUID submissionId, UUID userId, int voteValue) {
        Submission submission = requireSubmission(submissionId);
        authz.assertMember(submission.getRoomId(), userId);
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
        votes.deleteBySubmissionIdAndVoterId(submissionId, userId);
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

    private SubmissionResponse toResponse(Submission s, User author, List<Vote> submissionVotes, UUID currentUserId) {
        int totalVotes = submissionVotes.stream().mapToInt(Vote::getVoteValue).sum();
        Integer currentUserVote = submissionVotes.stream()
                .filter(v -> v.getVoterId().equals(currentUserId))
                .map(Vote::getVoteValue)
                .findFirst()
                .orElse(null);
        return new SubmissionResponse(
                s.getId(),
                s.getChallengeId(),
                s.getUserId(),
                s.getRoomId(),
                s.getImageUrl(),
                s.getTextContent(),
                s.getSubmittedAt(),
                author != null ? author.getUsername() : null,
                author != null ? author.getDisplayName() : null,
                author != null ? author.getAvatarUrl() : null,
                totalVotes,
                submissionVotes.size(),
                currentUserVote,
                s.getUserId().equals(currentUserId)
        );
    }
}
