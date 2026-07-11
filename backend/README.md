# KanziApp Backend (Spring Boot 4)

Self-hosted REST API replacing the Supabase backend. See [`../MIGRATION_PLAN.md`](../MIGRATION_PLAN.md)
for the full plan.

## Stack
- Java 21, Spring Boot 4.1
- PostgreSQL 15 (Liquibase XML migrations)
- Spring Security + JWT (access + refresh) — *Phase 1*
- MinIO / S3 for images — *Phase 3*
- Docker Compose stack; backend image built by **Jib** (no Dockerfile)

## Prerequisites
- JDK 21
- Docker + Docker Compose
- Maven 3.6.3+ (or use the wrapper once generated)

## Run the whole stack (recommended)
```bash
# 1. Build the backend image (needs a local Docker daemon)
mvn compile jib:dockerBuild

# 2. Bring up Postgres + MinIO + Mailpit + backend
docker compose up                       # x86_64
docker compose -f docker-compose.arm64.yml up   # Apple Silicon
```

Services:
| Service | URL |
|---|---|
| API | http://localhost:8080 |
| Health | http://localhost:8080/actuator/health |
| MinIO console | http://localhost:9001 (minioadmin / minioadmin) |
| Mailpit (caught emails) | http://localhost:8025 |
| Postgres | localhost:5432 (kanzi / kanzi) |

## Run the app locally, infra in Docker
```bash
docker compose up postgres minio minio-init mailpit
mvn spring-boot:run
```
The app defaults in `application.yml` point at `localhost` for exactly this workflow.

## Database migrations
Liquibase runs automatically on startup against the configured Postgres. Changelogs live in
`src/main/resources/db/changelog/` (XML). Master: `db.changelog-master.xml`. Hibernate is set to
`ddl-auto: validate` — Liquibase owns the schema, the entities only validate against it.

## Configuration
All wiring is env-overridable (see `application.yml`): `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`,
`S3_ENDPOINT`, `S3_ACCESS_KEY`, `S3_SECRET_KEY`, `S3_BUCKET`, `SPRING_MAIL_HOST`, `SPRING_MAIL_PORT`,
`JWT_ACCESS_TTL`, `JWT_REFRESH_TTL`.
