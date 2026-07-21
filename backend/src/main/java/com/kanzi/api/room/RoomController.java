package com.kanzi.api.room;

import com.kanzi.api.common.CurrentUserId;
import com.kanzi.api.room.dto.CreateRoomRequest;
import com.kanzi.api.room.dto.JoinRoomRequest;
import com.kanzi.api.room.dto.RoomDiscoverResponse;
import com.kanzi.api.room.dto.RoomMemberResponse;
import com.kanzi.api.room.dto.RoomResponse;
import com.kanzi.api.room.dto.UpdateRoomRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/rooms")
public class RoomController {

    private final RoomService rooms;

    public RoomController(RoomService rooms) {
        this.rooms = rooms;
    }

    @GetMapping
    public List<RoomResponse> getUserRooms(@CurrentUserId UUID userId) {
        return rooms.getUserRooms(userId);
    }

    @GetMapping("/discover")
    public List<RoomDiscoverResponse> discoverRooms(@CurrentUserId UUID userId) {
        return rooms.getDiscoverRooms(userId);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public RoomResponse createRoom(@CurrentUserId UUID userId, @Valid @RequestBody CreateRoomRequest request) {
        return rooms.createRoom(userId, request);
    }

    @PostMapping("/join")
    public RoomResponse joinRoom(@CurrentUserId UUID userId, @Valid @RequestBody JoinRoomRequest request) {
        return rooms.joinRoomByCode(userId, request.code());
    }

    @GetMapping("/{roomId}")
    public RoomResponse getRoom(@CurrentUserId UUID userId, @PathVariable UUID roomId) {
        return rooms.getRoomById(roomId, userId);
    }

    @PatchMapping("/{roomId}")
    public RoomResponse updateRoom(@CurrentUserId UUID userId, @PathVariable UUID roomId,
                                   @Valid @RequestBody UpdateRoomRequest request) {
        return rooms.updateRoom(roomId, userId, request);
    }

    @DeleteMapping("/{roomId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteRoom(@CurrentUserId UUID userId, @PathVariable UUID roomId) {
        rooms.deleteRoom(roomId, userId);
    }

    @DeleteMapping("/{roomId}/membership")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void leaveRoom(@CurrentUserId UUID userId, @PathVariable UUID roomId) {
        rooms.leaveRoom(roomId, userId);
    }

    @GetMapping("/{roomId}/members")
    public List<RoomMemberResponse> getMembers(@CurrentUserId UUID userId, @PathVariable UUID roomId) {
        return rooms.getRoomMembers(roomId, userId);
    }

    @DeleteMapping("/{roomId}/members/{targetUserId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void removeMember(@CurrentUserId UUID userId, @PathVariable UUID roomId,
                             @PathVariable UUID targetUserId) {
        rooms.removeMember(roomId, userId, targetUserId);
    }
}
