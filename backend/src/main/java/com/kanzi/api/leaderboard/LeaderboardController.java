package com.kanzi.api.leaderboard;

import com.kanzi.api.common.CurrentUserId;
import com.kanzi.api.leaderboard.dto.LeaderboardEntry;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/rooms/{roomId}/leaderboard")
public class LeaderboardController {

    private final LeaderboardService leaderboard;

    public LeaderboardController(LeaderboardService leaderboard) {
        this.leaderboard = leaderboard;
    }

    @GetMapping("/daily")
    public List<LeaderboardEntry> daily(@CurrentUserId UUID userId, @PathVariable UUID roomId,
                                        @RequestParam(required = false)
                                        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        LocalDate target = date != null ? date : LocalDate.now(ZoneOffset.UTC);
        return leaderboard.daily(roomId, userId, target);
    }

    @GetMapping("/overall")
    public List<LeaderboardEntry> overall(@CurrentUserId UUID userId, @PathVariable UUID roomId) {
        return leaderboard.overall(roomId, userId);
    }
}
