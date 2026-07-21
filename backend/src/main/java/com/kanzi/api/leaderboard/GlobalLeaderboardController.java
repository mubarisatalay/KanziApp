package com.kanzi.api.leaderboard;

import com.kanzi.api.common.CurrentUserId;
import com.kanzi.api.leaderboard.dto.WeeklyMvpEntry;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/leaderboard")
public class GlobalLeaderboardController {

    private final LeaderboardService leaderboard;

    public GlobalLeaderboardController(LeaderboardService leaderboard) {
        this.leaderboard = leaderboard;
    }

    @GetMapping("/weekly")
    public List<WeeklyMvpEntry> weeklyGlobal(@CurrentUserId UUID userId) {
        return leaderboard.weeklyGlobal(userId);
    }
}
