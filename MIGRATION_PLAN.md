# KanziApp — Supabase → Spring Boot 4 Migration Plan

> **Goal:** Replace the Supabase backend (auth, PostgREST data API, storage, RLS, RPC, cron)
> with a self-hosted **Java + Spring Boot 4** REST API, while keeping the Flutter app's UI and
> business logic essentially untouched.

## Working agreement

- **I write all the code** — backend and Flutter.
- **You review, discuss, and steer** the application. I'll present work for review and justify/revise
  design choices as we go.

## Locked decisions

| Concern | Decision |
|---|---|
| **Database** | New self-hosted PostgreSQL owned by Spring Boot. No `auth.users` coupling, no RLS. |
| **DB migrations** | **Liquibase**, changelogs authored in **XML**. |
| **Auth** | JWT **access + refresh** tokens. Spring issues both; Flutter stores them in secure storage. |
| **Image storage** | S3-compatible object storage (MinIO self-hosted / AWS S3 in cloud). |
| **Email verification** | **Kept.** Signup sends a verification email; account inactive until verified. |
| **Environment** | **Fully Dockerized** (Docker Compose): Postgres + MinIO + mail catcher + backend. |
| **Backend image** | Built with the **Jib Maven plugin** (no hand-written Dockerfile for the Java app). |

---

## 1. Why this migration is smaller than it looks

The friend built the Flutter app with a clean **repository pattern**. Every screen and Riverpod
provider talks to an *abstract interface* (`RoomRepository`, `ChallengeRepository`, …), never to
Supabase directly. Supabase only appears inside:

- 4 `*RepositoryImpl` classes (`auth`, `rooms`, `challenges`, `leaderboard`)
- `main.dart` (init), `app_router.dart` (auth redirect), `auth_provider.dart` (auth state stream)
- `supabase_provider.dart`, `supabase_constants.dart`
- Model `fromJson` factories (they parse Supabase's nested-join JSON shape)

**~10 Dart files change. The other ~40 stay as-is.** The bulk of the work is the *new* Spring Boot
project, not editing Flutter.

---

## 2. The conceptual shift: RLS → service-layer authorization

Today, authorization lives **inside Postgres** as Row-Level Security — Postgres itself refuses to
return rows a user shouldn't see. Once Spring owns a plain Postgres DB, **the database trusts every
query**, so every RLS policy must be re-implemented as an explicit check in Java. This is the
highest-risk part of the migration: a missed check is a data leak.

Direct mapping of every existing policy:

| Table | RLS policy (current) | Spring Boot equivalent |
|---|---|---|
| profiles | viewable by everyone | `GET /profiles/{id}` open to any authenticated user |
| profiles | insert/update own | self-only on update; creation handled at signup |
| rooms | view if member | `RoomService.getById` verifies caller ∈ room_members |
| rooms | create if `created_by = self` | set `createdBy` from JWT principal, never from body |
| rooms | update/delete if admin | `assertAdmin(roomId, userId)` before mutate |
| room_members | view if member of that room | membership check in service |
| room_members | join self only | `userId` from principal, not body |
| room_members | admin updates roles / removes; user leaves self | branching check in `leaveRoom` / `removeMember` |
| challenges | view if room member | membership check |
| challenges | create if room admin | `assertAdmin` |
| submissions | view if room member | membership check |
| submissions | create/update/delete **own** | `assertOwner(submissionId, userId)` |
| votes | view if member (via submission's room) | join submission→room, membership check |
| votes | vote if `voter = self` AND **not own submission** | explicit check: reject vote on own submission |
| votes | update/delete own | ownership check |

> **Recommendation:** centralize these in a small `AuthorizationService`
> (`assertMember` / `assertAdmin` / `assertOwner`) so the rules live in one auditable place, with a
> focused unit test per rule.

---

## 3. Target backend architecture (Spring Boot 4)

### Tech stack

| Layer | Choice | Notes |
|---|---|---|
| Runtime | **Java 21 (LTS)** | Boot 4 needs 17+; 21 is the current LTS |
| Framework | **Spring Boot 4.1.x** (Spring Framework 7) | verified: needs Java 17+, Tomcat 11, Maven 3.6.3+ |
| Build | **Maven** | + Jib plugin for the image |
| Web | `spring-boot-starter-web` | REST controllers |
| Data | `spring-boot-starter-data-jpa` + PostgreSQL driver | |
| Migrations | **Liquibase**, **XML** changelogs | replaces the manual `database_schema.sql` |
| Security | `spring-boot-starter-security` + `spring-boot-starter-oauth2-resource-server` | JWT validation; add `JwtEncoder` for issuance |
| Validation | `spring-boot-starter-validation` | `@Valid` on request DTOs |
| Storage | AWS SDK v2 S3 client (works with MinIO) | |
| Mail | `spring-boot-starter-mail` | verification emails |
| Passwords | `BCryptPasswordEncoder` | |
| Container | **Jib Maven plugin** | `mvn compile jib:dockerBuild` / `jib:build` |

### Package layout (feature-first, mirrors the Flutter structure)

```
com.kanzi.api
├── KanziApiApplication.java
├── config/           SecurityConfig, S3Config, MailConfig, JwtConfig, CorsConfig
├── common/           error handling (@RestControllerAdvice), base DTOs, AuthorizationService
├── auth/             AuthController, AuthService, JwtService, RefreshToken entity
├── profile/          Profile/User entity, repo, service, controller
├── room/             Room + RoomMember entities, repos, RoomService, RoomController
├── challenge/        Challenge + Submission + Vote entities, repos, services, controllers
├── leaderboard/      LeaderboardService, LeaderboardController (aggregation queries)
└── storage/          StorageService (S3), image upload endpoint
```

### Liquibase changelog layout (XML)

```
src/main/resources/db/changelog/
├── db.changelog-master.xml         (includes the changesets in order)
├── 001-users-profiles.xml
├── 002-rooms-and-members.xml
├── 003-challenges-submissions-votes.xml
└── 004-refresh-tokens.xml
```

`application.yml` points `spring.liquibase.change-log` at the master changelog; Liquibase runs on
startup against the Dockerized Postgres.

---

## 4. Data model → JPA entities

The 6 tables map almost 1:1 to `@Entity` classes, expressed as Liquibase XML changesets. Key
changes vs. the Supabase schema:

- **`profiles.id` no longer references `auth.users`.** Add a `users` table (or fold auth into
  `profiles`) that Spring owns: `id (UUID PK)`, `email (unique)`, `password_hash`,
  `email_verified (bool)`, `verification_token`, plus the profile fields (`username`,
  `display_name`, `avatar_url`). One table is simplest.
- **`gen_random_uuid()` / `DEFAULT NOW()`** → `@GeneratedValue`/`UUID.randomUUID()` and
  `@CreationTimestamp`/`@UpdateTimestamp` in the entity; columns still declared in Liquibase.
- **Unique constraints** (`rooms.code`, `room_members(room_id,user_id)`,
  `challenges(room_id,challenge_date)`, `submissions(challenge_id,user_id)`,
  `votes(submission_id,voter_id)`) → `<uniqueConstraint>` in XML. These power the app's "already a
  member" / "already submitted" / duplicate-vote logic (currently keyed off Postgres error `23505`),
  so preserving them keeps that behavior.
- **`updated_at` triggers** → `@UpdateTimestamp` (no DB trigger).

The three DB functions become plain Java:
- `generate_room_code()` → `RoomService.generateCode()` (6 chars from
  `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`, retry on unique clash — the client already retries).
- `ensure_profile_exists` / `handle_new_user` → handled inline during signup; no longer needed.
- `get_daily_leaderboard()` → a JPQL/native aggregation query in `LeaderboardService`. The Flutter
  code has a manual-aggregation fallback that documents the exact ranking logic to replicate.

---

## 5. REST API surface (replaces every repository method)

**Convention:** all endpoints under `/api/v1`, JWT bearer required except `/auth/signup`,
`/auth/login`, `/auth/verify`, `/auth/refresh`, `/auth/resend-verification`.

### Auth (replaces `AuthRepository` + GoTrue)
| Method | Endpoint | Replaces |
|---|---|---|
| POST | `/auth/signup` | `signUpWithEmail` — create user, send verification email |
| GET/POST | `/auth/verify?token=` | email confirmation |
| POST | `/auth/resend-verification` | `resendConfirmationEmail` |
| POST | `/auth/login` | `signInWithEmail` → `{accessToken, refreshToken, profile}` |
| POST | `/auth/refresh` | (new) rotate access token from refresh token |
| POST | `/auth/logout` | `signOut` — revoke refresh token |
| GET | `/auth/me` | `getCurrentUserProfile` |

### Rooms (replaces `RoomRepository`)
`GET /rooms` · `POST /rooms` · `GET /rooms/{id}` · `PATCH /rooms/{id}` · `DELETE /rooms/{id}` ·
`POST /rooms/join` · `DELETE /rooms/{id}/membership` (leave) · `GET /rooms/{id}/members` ·
`DELETE /rooms/{id}/members/{userId}`

### Challenges & submissions (replaces `ChallengeRepository`)
`GET /rooms/{roomId}/challenges/today` · `GET /rooms/{roomId}/challenges` (history, limit 30) ·
`POST /rooms/{roomId}/challenges` · `GET /challenges/{id}` · `GET /challenges/{id}/submissions` ·
`POST /challenges/{id}/submissions` (multipart) · `PATCH /submissions/{id}` (multipart) ·
`DELETE /submissions/{id}` · `PUT /submissions/{id}/vote` · `DELETE /submissions/{id}/vote`

### Leaderboard (replaces `LeaderboardRepository`)
`GET /rooms/{roomId}/leaderboard/daily?date=YYYY-MM-DD` · `GET /rooms/{roomId}/leaderboard/overall`

> **Error codes → client messages:** the Flutter repos map Postgres `23505` to friendly messages
> ("already a member", "already submitted"). The API returns **409 Conflict** for these so the client
> maps status codes to the same messages.

---

## 6. Auth flow in detail (JWT access + refresh + email verification)

1. **Signup** → BCrypt-hash password, store user with `email_verified=false` + random token, email a
   verification link. Return `202 Accepted` (mirrors current `emailConfirmationRequired`).
2. **Verify** → validate token, set `email_verified=true`.
3. **Login** → reject if unverified; else issue a short-lived **access JWT** (~15 min) + an opaque
   **refresh token** stored in a `refresh_tokens` table (~30 days).
4. **Authenticated requests** → `Authorization: Bearer <access>`; `oauth2-resource-server` validates
   via our `JwtDecoder` bean; a converter puts the user id into the `Authentication` principal.
5. **Refresh** → `POST /auth/refresh` → new access token (+ rotate refresh).
6. **Logout** → delete the refresh token row.

Signing key: RSA keypair — `JwtEncoder` signs with the private key, `JwtDecoder` verifies with the
public key. Keys via env/secrets, injected through Docker, never committed.

---

## 7. Image storage (S3 / MinIO, Dockerized)

`StorageService.upload(bytes, roomId, challengeId, userId)` writes to key
`challenge-images/{roomId}/{challengeId}/{userId}_{timestamp}.{ext}` (same scheme as today) and
returns a URL. The server-side upload replaces `_uploadImage` in `challenge_repository.dart`; the
Flutter side just POSTs multipart to `/challenges/{id}/submissions` and reads the returned
`image_url`. MinIO runs as a Compose service; config: bucket, endpoint, keys, public-read vs.
pre-signed URLs (public-read matches today's public bucket).

---

## 8. Scheduled daily challenges

The Supabase cron + `create_daily_challenges()` edge function → a Spring `@Scheduled(cron=...)` bean
(`DailyChallengeJob`) that at midnight inserts one random challenge per room from the same challenge
pool; the old `ON CONFLICT DO NOTHING` becomes "skip if a challenge already exists for that date".

---

## 9. Dockerized environment

`docker-compose.yml` services:

| Service | Image | Purpose |
|---|---|---|
| `postgres` | `postgres:16` | app database (volume-backed) |
| `minio` | `minio/minio` | S3-compatible storage + console |
| `mailpit` | mail catcher | catches verification emails in dev |
| `backend` | image built by **Jib** | the Spring Boot API |

Backend image: `mvn compile jib:dockerBuild` produces `kanzi-api:latest` locally (or `jib:build`
straight to a registry for deploy). Compose wires env (DB URL, MinIO creds, mail host, JWT keys) so
the whole stack comes up with `docker compose up`.

---

## 10. Flutter client changes (the ~10 files — I handle these)

| File | Change |
|---|---|
| `pubspec.yaml` | remove `supabase_flutter`; add `dio` + `flutter_secure_storage` |
| `main.dart` | remove `Supabase.initialize`; init `ApiClient` + load stored tokens |
| `core/constants/supabase_constants.dart` | → `api_constants.dart` (base URL) |
| `shared/providers/supabase_provider.dart` | → `api_client_provider.dart` (Dio + auth interceptor: attach bearer, auto-refresh on 401) |
| `auth/.../auth_repository.dart` | reimplement against `/auth/*`; manage token storage |
| `auth/.../auth_provider.dart` | rebuild the auth-state `Stream` from a local session notifier (replaces `onAuthStateChange`) |
| `core/router/app_router.dart` | drive redirect off the new auth notifier |
| `rooms\|challenges\|leaderboard/.../*_repository.dart` | swap `_client.from(...)` for HTTP calls |
| model `fromJson` factories | adjust only where API JSON nesting differs from Supabase's |

Domain entities, provider public APIs, and all screens/widgets stay unchanged.

---

## 11. Phased execution plan

**Phase 0 — Scaffold (backend + infra)**
Spring Boot 4 Maven project (Java 21), `docker-compose.yml` (Postgres + MinIO + Mailpit), Jib
config, Liquibase master changelog + `V1` schema (`001..003` XML changesets), health check.

**Phase 1 — Auth vertical slice**
`users` entity + signup/verify/login/refresh/logout/me, JWT (RSA) config, BCrypt, mail sending,
refresh-token table. Verify end-to-end.

**Phase 2 — Rooms**
Entities, `AuthorizationService` (member/admin), room endpoints, code generation, 409 mapping.

**Phase 3 — Challenges & submissions**
Entities, endpoints, multipart upload → MinIO, ownership + membership checks, `DailyChallengeJob`.

**Phase 4 — Leaderboard**
Daily + overall aggregation with ranking.

**Phase 5 — Flutter cutover**
Swap the ~10 files feature by feature (auth → rooms → challenges → leaderboard), pointed at the
local Dockerized backend, testing each flow against the running screens.

**Phase 6 — Data migration (if needed) & deploy**
If real users/data exist: one-off Supabase → Postgres script (note: Supabase passwords aren't
exportable — existing users need a password reset). Deploy via Jib image + Compose.

---

## 12. Risks & gotchas

- **Authorization gaps** — the #1 risk. Re-implement *every* RLS policy (§2); test one per rule.
- **Password migration** — Supabase auth hashes aren't portable; existing users must reset passwords
  after cutover. New signups unaffected.
- **Dead Supabase credentials** — the anon key/URL in `supabase_constants.dart` become dead; lock
  down / decommission the Supabase project post-cutover so old builds can't still write to it.
- **Timezone of "today"** — `getTodayChallenge` and the daily job both compute "today"; pick one
  timezone (server UTC vs. user local) to avoid off-by-one-day bugs.
- **CORS** — needed only if the Flutter *web* target is used; mobile doesn't enforce it.
- **Image URL reachability** — `cached_network_image` needs a reachable URL; ensure MinIO/S3 URLs
  are public (or switch to pre-signed and I'll adjust the client).

---

## 13. Open decisions for later (not blocking)

- Production deploy target (VPS + Compose vs. managed cloud / registry for Jib push)?
- MinIO (self-host) vs. AWS S3 (managed) in production?
- Password-reset flow in MVP scope, or after?
- Migrate existing Supabase images to the new bucket, or start fresh?
