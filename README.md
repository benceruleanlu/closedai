# closedai

A private Next.js application using Google sign-in through Better Auth, Drizzle ORM, and PostgreSQL. The production target is Google Cloud Run with Cloud SQL in project `closedai-505222`.

## Local setup

```bash
cp .env.example .env.local
docker compose up -d --wait
pnpm install
pnpm db:migrate
pnpm dev
```

Create Google OAuth credentials and put the client ID and secret in `.env.local`. For local development, register this authorized redirect URI:

```text
http://localhost:3000/api/auth/callback/google
```

Generate `BETTER_AUTH_SECRET` with at least 32 random characters. For example:

```bash
openssl rand -base64 32
```

## Authentication boundary

All application routes require a valid database-backed session. The only anonymous surfaces are `/sign-in`, Better Auth's `/api/auth/*` endpoints needed to complete OAuth, and framework static assets.

`src/proxy.ts` performs an optimistic cookie check. The authenticated route-group layout then validates the session against PostgreSQL, so a forged or expired cookie does not grant access.

This is an authentication boundary, not yet an invite or email allowlist. Any Google account allowed by the OAuth consent configuration can create an application user until an authorization policy is added.

## Schema and migrations

Better Auth describes the auth tables, but Drizzle is the only migration ledger:

```bash
# Regenerate src/db/schema/auth.ts after changing Better Auth options/plugins.
pnpm auth:schema

# Review the generated schema, then create a SQL migration.
pnpm db:generate

# Apply checked-in migrations to the configured database.
pnpm db:migrate
```

Do not run Better Auth's direct `migrate` command. It is not the production migration path for this project.

## Checks

```bash
pnpm lint
pnpm typecheck
pnpm db:check
pnpm build
```

The included `Dockerfile` builds Next.js standalone output and runs it on port `8080`, which matches Cloud Run's container contract. Standalone output is disabled automatically when Vercel builds the repository because Vercel supplies its own Next.js packaging.
