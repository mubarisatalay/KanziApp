# Local testing (Chrome, no Android Studio)

Everything below is verified working: backend compiles + runs, CORS is enabled for
localhost, and the Flutter app analyzes clean and builds for web.

## Prerequisites (already installed)
- Flutter SDK (`/opt/homebrew/bin/flutter`) — no Android Studio needed for web.
- Docker + Docker Compose.
- JDK 21 + Maven.
- Google Chrome.

If `flutter` isn't found, add Homebrew's bin to PATH: `export PATH="/opt/homebrew/bin:$PATH"`.

## The three terminals

**1) Infra (Postgres + MinIO + Mailpit) in Docker**
```bash
cd backend
docker compose -f docker-compose.arm64.yml up -d postgres minio minio-init mailpit
```

**2) Backend API on the host** (uses localhost defaults from application.yml)
```bash
cd backend
mvn spring-boot:run
# health: http://localhost:8080/actuator/health  -> {"status":"UP"}
```

**3) Flutter web app in Chrome**
```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```
> First time only: web support must be on (`flutter config --enable-web`).
> No Google Chrome? Any Chromium browser works — point Flutter at it, e.g. Brave:
> ```bash
> export CHROME_EXECUTABLE="/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
> ```
> (add that line to `~/.zshrc` to make it stick). Or use any browser via
> `flutter run -d web-server --web-port=3000 ...` and open http://localhost:3000 yourself.
Flutter opens Chrome on a random localhost port; the backend CORS allows any
`http://localhost:*` origin, so it just works.

## Signing up (email verification is ON)
1. In the app, create an account.
2. Open **Mailpit** at http://localhost:8025 — the verification email is there.
3. Click the verification link (hits the backend, returns "Email verified").
4. Back in the app, sign in.

## Handy URLs
| What                    | URL                                                     |
|-------------------------|---------------------------------------------------------|
| API                     | http://localhost:8080                                   |
| Health                  | http://localhost:8080/actuator/health                   |
| Mailpit (caught emails) | http://localhost:8025                                   |
| MinIO console           | http://localhost:9001 (minioadmin / minioadmin)         |
| API contract            | `backend/openapi.yaml` (load into Swagger UI / Postman) |

## Web-specific notes
- **Images**: uploads use `XFile` + bytes (`MultipartFile.fromBytes`) so they work on web.
  The "Take Photo" option falls back to a file picker in the browser.
- **Tokens**: `flutter_secure_storage` on web keeps the JWTs in the browser (localStorage/
  WebCrypto). Fine for dev.
- **Live updates**: submissions refresh via 6-second polling (the replacement for Supabase
  Realtime).
- The `flutter build web` "WebAssembly incompatibilities" message is only a WASM dry-run
  warning (secure-storage uses `dart:html`); the normal JS build is unaffected.

## Reset the data
```bash
cd backend
docker compose -f docker-compose.arm64.yml down -v   # wipes Postgres + MinIO volumes
```
