package com.kanzi.api.common;

import com.kanzi.api.room.RoomMember;
import com.kanzi.api.room.RoomMemberRepository;
import org.springframework.stereotype.Service;

import java.util.UUID;

/**
 * Central home for the authorization rules that used to live in Postgres RLS policies.
 * Every room-scoped operation routes through here so the rules are auditable in one place.
 */
@Service
public class AuthorizationService {

    private final RoomMemberRepository members;

    public AuthorizationService(RoomMemberRepository members) {
        this.members = members;
    }

    /** The caller's membership, or 403 if they aren't in the room (replaces "view if member" RLS). */
    public RoomMember requireMembership(UUID roomId, UUID userId) {
        return members.findByRoomIdAndUserId(roomId, userId)
                .orElseThrow(() -> ApiException.forbidden("You are not a member of this room."));
    }

    public void assertMember(UUID roomId, UUID userId) {
        requireMembership(roomId, userId);
    }

    /** 403 unless the caller is an admin of the room (replaces the admin-only RLS policies). */
    public void assertAdmin(UUID roomId, UUID userId) {
        if (!requireMembership(roomId, userId).isAdmin()) {
            throw ApiException.forbidden("Only room admins can perform this action.");
        }
    }

    public boolean isAdmin(UUID roomId, UUID userId) {
        return members.findByRoomIdAndUserId(roomId, userId)
                .map(RoomMember::isAdmin)
                .orElse(false);
    }
}
