package com.kanzi.api.challenge;

import com.kanzi.api.challenge.dto.ChallengeResponse;
import com.kanzi.api.challenge.dto.CreateChallengeRequest;
import com.kanzi.api.challenge.dto.SubmissionResponse;
import com.kanzi.api.common.CurrentUserId;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1")
public class ChallengeController {

    private final ChallengeService challenges;

    public ChallengeController(ChallengeService challenges) {
        this.challenges = challenges;
    }

    @GetMapping("/rooms/{roomId}/challenges/today")
    public ResponseEntity<ChallengeResponse> getTodayChallenge(@CurrentUserId UUID userId,
                                                               @PathVariable UUID roomId) {
        ChallengeResponse challenge = challenges.getTodayChallenge(roomId, userId);
        return challenge == null ? ResponseEntity.noContent().build() : ResponseEntity.ok(challenge);
    }

    @GetMapping("/rooms/{roomId}/challenges")
    public List<ChallengeResponse> getHistory(@CurrentUserId UUID userId, @PathVariable UUID roomId) {
        return challenges.getChallengeHistory(roomId, userId);
    }

    @PostMapping("/rooms/{roomId}/challenges")
    @ResponseStatus(HttpStatus.CREATED)
    public ChallengeResponse createChallenge(@CurrentUserId UUID userId, @PathVariable UUID roomId,
                                             @Valid @RequestBody CreateChallengeRequest request) {
        return challenges.createChallenge(roomId, userId, request);
    }

    @GetMapping("/challenges/{challengeId}")
    public ChallengeResponse getChallenge(@CurrentUserId UUID userId, @PathVariable UUID challengeId) {
        return challenges.getChallengeById(challengeId, userId);
    }

    @GetMapping("/challenges/{challengeId}/submissions")
    public List<SubmissionResponse> getSubmissions(@CurrentUserId UUID userId, @PathVariable UUID challengeId) {
        return challenges.getSubmissions(challengeId, userId);
    }

    @PostMapping(value = "/challenges/{challengeId}/submissions", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    public SubmissionResponse submit(@CurrentUserId UUID userId, @PathVariable UUID challengeId,
                                     @RequestParam(required = false) String textContent,
                                     @RequestParam(required = false) MultipartFile image) {
        return challenges.submitResponse(challengeId, userId, textContent, image);
    }
}
