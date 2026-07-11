package com.kanzi.api.challenge;

import com.kanzi.api.challenge.dto.SubmissionResponse;
import com.kanzi.api.challenge.dto.VoteRequest;
import com.kanzi.api.common.CurrentUserId;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/submissions")
public class SubmissionController {

    private final ChallengeService challenges;

    public SubmissionController(ChallengeService challenges) {
        this.challenges = challenges;
    }

    @PatchMapping(value = "/{submissionId}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public SubmissionResponse update(@CurrentUserId UUID userId, @PathVariable UUID submissionId,
                                     @RequestParam(required = false) String textContent,
                                     @RequestParam(required = false) MultipartFile image) {
        return challenges.updateSubmission(submissionId, userId, textContent, image);
    }

    @DeleteMapping("/{submissionId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@CurrentUserId UUID userId, @PathVariable UUID submissionId) {
        challenges.deleteSubmission(submissionId, userId);
    }

    @PutMapping("/{submissionId}/vote")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void vote(@CurrentUserId UUID userId, @PathVariable UUID submissionId,
                     @Valid @RequestBody VoteRequest request) {
        challenges.voteOnSubmission(submissionId, userId, request.voteValue());
    }

    @DeleteMapping("/{submissionId}/vote")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void removeVote(@CurrentUserId UUID userId, @PathVariable UUID submissionId) {
        challenges.removeVote(submissionId, userId);
    }
}
