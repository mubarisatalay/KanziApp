# KanziApp

Babaların uygulaması.

## What is this?

KanziApp is a social challenge app built around friend groups. Every day, each room receives the same surprise challenge at a random time (like BeReal — nobody knows when it's coming). Submissions are hidden from each other until 21:00, when everything reveals at once and voting opens. Points are tallied daily and weekly.

---

## Stack

| Layer | Tech |
|---|---|
| Mobile / Desktop | Flutter (Dart) |
| REST API | Spring Boot 4, Java 21 |
| Database | PostgreSQL 15 with Liquibase migrations |
| Object storage | MinIO (S3-compatible, challenge images) |
| Auth | JWT — access + refresh token pair |
| Dev email | Mailpit (SMTP catcher, no real mail sent) |

---

## Features

### Challenge system
- One challenge per room per day, drawn automatically from a curated pool at midnight.
- The challenge goes live at a **random time between 12:00–20:00** (same seed per date, so all rooms get the same window).
- Challenge types: `photo`, `text`, or `photo_text`.
- **Blind mode** — all submissions are locked until reveal time. You can see that others submitted, but not what they submitted.

### Reveal ceremony
- Results unlock at **21:00 Istanbul time**.
- At reveal, all submissions become visible, author identities are unmasked, and rankings are calculated (avg score, then vote count as tiebreaker, then submission time).

### Voting
- Users vote on other members' submissions (not their own) before reveal.
- Pre-reveal, vote aggregates are hidden — no early feedback that could bias others.
- Post-reveal, full vote breakdowns are shown.

### Leaderboard
- **Daily** — ranked by votes received on today's challenge.
- **Overall** — all-time total votes per member in a room.
- **Weekly MVP (room)** — normalized score across the week's challenges in a room.
- **Weekly MVP (global)** — same, but across all rooms. Scores are normalized by room size so a member in a 3-person room isn't penalized vs. one in a 20-person room.

### Challenge pool
- 60+ hand-curated prompts live in `backend/src/main/resources/challenge-pool.yml`.
- Loaded into the database on startup. New entries are inserted automatically; existing ones are never overwritten.
- To retire a prompt: set `active = false` directly in the DB — don't delete it.
- Pool is split by type: `photo` (poses, reactions), `text` (captions, one-liners), `photo_text` (image + caption combos).

### Localization
- Full **English and Turkish** support via Flutter's `l10n` / ARB system.

---

## Quick Start

### 1. Start backend infrastructure

```bash
cd backend
docker compose up postgres minio minio-init mailpit
mvn spring-boot:run
```

Verify the backend is up:

```bash
curl http://localhost:8080/actuator/health
# → {"status":"UP"}
```

> See [`backend/README.md`](backend/README.md) for full backend docs — Docker-only mode, env vars, migrations, etc.

### 2. Run the Flutter app

The API base URL is injected at build time via `--dart-define`. Pick the right one for your platform:

| Platform | Command |
|---|---|
| Windows / macOS / iOS Simulator | `flutter run` |
| Android Emulator | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1` |
| Real Android / iOS device | `flutter run --dart-define=API_BASE_URL=http://<your-machine-ip>:8080/api/v1` |

Find your machine's local IP (for real device):

```powershell
# Windows
ipconfig | findstr "IPv4"

# macOS / Linux
ipconfig getifaddr en0
```

---

## Troubleshooting

### "Failed to sign in" — app cannot reach the backend

The most common cause is a **wrong base URL**. The default `localhost` only works on desktop.

**Android Emulator** — `localhost` inside the emulator is the emulator itself, not your host machine.

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
```

**Real device** — device and machine must be on the same Wi-Fi network.

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.x:8080/api/v1
```

**Backend not running or crashed**

```bash
curl http://localhost:8080/actuator/health      # should return {"status":"UP"}
docker compose logs backend                     # check for startup errors
```

If the backend starts before Postgres is ready, Liquibase will fail — always bring up infra first (`docker compose up postgres minio minio-init mailpit`), then start the app.

**Windows Firewall (real device only)**
Windows may block inbound connections on port 8080. Add an inbound rule to allow TCP 8080.
