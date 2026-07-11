package com.kanzi.api.room;

import com.kanzi.api.common.ApiException;
import com.kanzi.api.common.AuthorizationService;
import com.kanzi.api.room.dto.CreateRoomRequest;
import com.kanzi.api.room.dto.RoomMemberResponse;
import com.kanzi.api.room.dto.RoomResponse;
import com.kanzi.api.room.dto.UpdateRoomRequest;
import com.kanzi.api.user.User;
import com.kanzi.api.user.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class RoomService {

    private static final String CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    private static final int CODE_LENGTH = 6;
    private static final SecureRandom RANDOM = new SecureRandom();

    private final RoomRepository rooms;
    private final RoomMemberRepository members;
    private final UserRepository users;
    private final AuthorizationService authz;

    public RoomService(RoomRepository rooms, RoomMemberRepository members, UserRepository users,
                       AuthorizationService authz) {
        this.rooms = rooms;
        this.members = members;
        this.users = users;
        this.authz = authz;
    }

    @Transactional(readOnly = true)
    public List<RoomResponse> getUserRooms(UUID userId) {
        List<Room> userRooms = rooms.findAllForMember(userId);
        if (userRooms.isEmpty()) {
            return List.of();
        }
        List<UUID> roomIds = userRooms.stream().map(Room::getId).toList();
        List<RoomMember> allMembers = members.findByRoomIdIn(roomIds);

        Map<UUID, Long> countByRoom = allMembers.stream()
                .collect(Collectors.groupingBy(RoomMember::getRoomId, Collectors.counting()));
        Map<UUID, String> myRoleByRoom = allMembers.stream()
                .filter(m -> m.getUserId().equals(userId))
                .collect(Collectors.toMap(RoomMember::getRoomId, RoomMember::getRole));

        return userRooms.stream()
                .map(r -> RoomResponse.from(r,
                        countByRoom.getOrDefault(r.getId(), 0L),
                        myRoleByRoom.get(r.getId())))
                .toList();
    }

    @Transactional(readOnly = true)
    public RoomResponse getRoomById(UUID roomId, UUID userId) {
        RoomMember membership = authz.requireMembership(roomId, userId);
        Room room = rooms.findById(roomId)
                .orElseThrow(() -> ApiException.notFound("Room not found."));
        return RoomResponse.from(room, members.countByRoomId(roomId), membership.getRole());
    }

    @Transactional
    public RoomResponse createRoom(UUID userId, CreateRoomRequest request) {
        Room room = new Room();
        room.setName(request.name().trim());
        room.setDescription(request.description() == null ? null : request.description().trim());
        room.setCode(generateUniqueCode());
        room.setCreatedBy(userId);
        rooms.saveAndFlush(room); // flush so @CreationTimestamp/@UpdateTimestamp populate before we map the response

        RoomMember creator = new RoomMember();
        creator.setRoomId(room.getId());
        creator.setUserId(userId);
        creator.setRole(RoomMember.ROLE_ADMIN);
        members.save(creator);

        return RoomResponse.from(room, 1, RoomMember.ROLE_ADMIN);
    }

    @Transactional
    public RoomResponse joinRoomByCode(UUID userId, String code) {
        // Lookup by code deliberately does NOT require membership — you're joining.
        Room room = rooms.findByCode(code.trim().toUpperCase())
                .orElseThrow(() -> ApiException.notFound(
                        "No room found with that code. Please check and try again."));

        if (members.existsByRoomIdAndUserId(room.getId(), userId)) {
            throw ApiException.conflict("You are already a member of this room.");
        }

        RoomMember member = new RoomMember();
        member.setRoomId(room.getId());
        member.setUserId(userId);
        member.setRole(RoomMember.ROLE_MEMBER);
        members.save(member);

        return RoomResponse.from(room, members.countByRoomId(room.getId()), RoomMember.ROLE_MEMBER);
    }

    @Transactional
    public RoomResponse updateRoom(UUID roomId, UUID userId, UpdateRoomRequest request) {
        authz.assertAdmin(roomId, userId);
        Room room = rooms.findById(roomId)
                .orElseThrow(() -> ApiException.notFound("Room not found."));

        if (request.name() != null) {
            room.setName(request.name().trim());
        }
        if (request.description() != null) {
            room.setDescription(request.description().trim());
        }
        rooms.saveAndFlush(room); // flush so the refreshed @UpdateTimestamp is in the response
        return RoomResponse.from(room, members.countByRoomId(roomId), RoomMember.ROLE_ADMIN);
    }

    @Transactional
    public void deleteRoom(UUID roomId, UUID userId) {
        authz.assertAdmin(roomId, userId);
        rooms.deleteById(roomId); // FK ON DELETE CASCADE removes members/challenges/etc.
    }

    @Transactional
    public void leaveRoom(UUID roomId, UUID userId) {
        RoomMember membership = authz.requireMembership(roomId, userId);

        boolean onlyAdmin = membership.isAdmin()
                && members.countByRoomIdAndRole(roomId, RoomMember.ROLE_ADMIN) == 1;

        if (onlyAdmin) {
            long total = members.countByRoomId(roomId);
            if (total > 1) {
                throw ApiException.badRequest(
                        "You are the only admin. Assign another admin before leaving, or delete the room.");
            }
            // Last member and sole admin — delete the whole room.
            rooms.deleteById(roomId);
            return;
        }

        members.deleteByRoomIdAndUserId(roomId, userId);
    }

    @Transactional(readOnly = true)
    public List<RoomMemberResponse> getRoomMembers(UUID roomId, UUID userId) {
        authz.assertMember(roomId, userId);
        List<RoomMember> roomMembers = members.findByRoomIdOrderByJoinedAt(roomId);

        List<UUID> userIds = roomMembers.stream().map(RoomMember::getUserId).toList();
        Map<UUID, User> usersById = users.findAllById(userIds).stream()
                .collect(Collectors.toMap(User::getId, Function.identity()));

        return roomMembers.stream()
                .map(m -> RoomMemberResponse.from(m, usersById.get(m.getUserId())))
                .toList();
    }

    @Transactional
    public void removeMember(UUID roomId, UUID actorId, UUID targetUserId) {
        if (targetUserId.equals(actorId)) {
            throw ApiException.badRequest("Use \"leave room\" to remove yourself.");
        }
        authz.assertAdmin(roomId, actorId);
        members.deleteByRoomIdAndUserId(roomId, targetUserId);
    }

    private String generateUniqueCode() {
        for (int attempt = 0; attempt < 10; attempt++) {
            String code = randomCode();
            if (!rooms.existsByCode(code)) {
                return code;
            }
        }
        throw ApiException.conflict("Could not generate a unique room code, please retry.");
    }

    private static String randomCode() {
        StringBuilder sb = new StringBuilder(CODE_LENGTH);
        for (int i = 0; i < CODE_LENGTH; i++) {
            sb.append(CODE_ALPHABET.charAt(RANDOM.nextInt(CODE_ALPHABET.length())));
        }
        return sb.toString();
    }
}
