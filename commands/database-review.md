---
description: Multi-engine database review (PostgreSQL/MySQL/SQLite/ClickHouse/MongoDB/DynamoDB/Redis + ORMs) with fail-closed engine detection, engine-specific review, business naming proposals, and migration safety
argument-hint: "[path | --naming | --full-schema]"
---

# Database Review Command

You are the Lead Orchestrator handling the `/database-review` command. Your mission is to run a 6-phase database review that works across every common engine, never assumes PostgreSQL, and adds a business naming/domain-fit layer that plain SQL linters do not provide.

**Arguments**: $ARGUMENTS

## Phase 0 — Engine & ORM Detection (FAIL-CLOSED)

Scan deterministic signals before reviewing anything:

| Signal | Engine / ORM |
|--------|--------------|
| `package.json` deps: `pg`, `postgres`, `@supabase/supabase-js` | PostgreSQL |
| `package.json` deps: `mysql2`, `mariadb` | MySQL |
| `package.json` deps: `mongodb`, `mongoose` | MongoDB |
| `package.json` deps: `@aws-sdk/client-dynamodb`, `dynamoose` | DynamoDB |
| `package.json` deps: `ioredis`, `redis` | Redis |
| `package.json` deps: `clickhouse`, `@clickhouse/client` | ClickHouse |
| `package.json` deps: `better-sqlite3`, `sqlite3` | SQLite |
| `schema.prisma` | Prisma ORM — read `datasource` block |
| `drizzle.config.ts` | Drizzle ORM — read dialect |
| `settings.py` `DATABASES` block | Django ORM |
| `application.yml` + JPA deps | JPA/Hibernate |
| `alembic.ini` | Alembic (SQLAlchemy) |
| `knexfile.*` | Knex — read `client` |

Output an engine matrix: `{engine, orm, confidence, evidence file:line}`.

**Fail-closed rule**: zero or ambiguous signals → ask the user via the question tool to confirm the engine. NEVER silently default to PostgreSQL. Stop here if the user cannot confirm.

## Phase 1 — Scope

Filter changed files to database surfaces:

```bash
git diff --name-only HEAD
```

Keep: `*.sql`, migrations directories, `schema.prisma`, `drizzle.config.ts`, ORM model files, `settings.py`, `application.yml`, `alembic.ini`, `knexfile.*`, DynamoDB table-definition files (CDK/Terraform), Mongo model/schema files.

Argument modes:
- explicit path → review that file/directory only
- `--full-schema` → review the whole schema, not just the diff
- `--naming` → jump straight to Phase 3 (naming-focused)

If no database files are in scope, say so and stop. Do not manufacture work.

## Phase 2 — Engine-Specific Review

Dispatch the `@database-reviewer` agent (`agents/database-reviewer.md`) with the engine matrix, the scoped file list, and the review directives. The agent routes to the matching repo-native skill for depth:

| Engine / ORM | Skill |
|--------------|-------|
| PostgreSQL | `skills/postgres-patterns/` |
| MySQL / MariaDB | `skills/mysql-patterns/` |
| ClickHouse | `skills/clickhouse-io/` |
| Redis | `skills/redis-patterns/` |
| Prisma ORM | `skills/prisma-patterns/` |
| JPA / Hibernate | `skills/jpa-patterns/` |
| MyBatis | `skills/mybatis-patterns/` |
| Kotlin Exposed | `skills/kotlin-exposed-patterns/` |
| MongoDB | `skills/mongodb-patterns/` |
| DynamoDB | `skills/dynamodb-patterns/` |
| Migrations (any engine) | `skills/database-migrations/` |
| SQLite | inline guidance (no dedicated skill) |

**Evidence gate**: every finding MUST cite `file:line`. Severity requires evidence (explain/plan output or quoted schema); unsupported claims are downgraded, not asserted.

## Phase 3 — Business Naming & Domain-Fit Review

Run when schema files changed or `--naming` was passed:

1. **Extract codebase vocabulary** — entity/class/DTO/API names, plus `CONTEXT.md` glossary if present.
2. **Check each name against:**
   - (a) **Ubiquitous language** — does the table/column name match the vocabulary the codebase already uses?
   - (b) **Local conventions** — if the codebase is already consistent (even singular snake_case), FOLLOW it. Greenfield default: plural snake_case tables, singular columns, `<entity>_id` FKs, `created_at`/`updated_at`/`deleted_at`, `idx_`/`uq_`/`fk_` prefixes.
   - (c) **Reserved words** — flag per-engine reserved words (e.g. `order`) with quoting guidance.
   - (d) **Length limits** — PostgreSQL 63 bytes, MySQL 64 chars.
3. **Output the Rename Proposal Table** (PROPOSAL-ONLY):

| Current | Proposed | Rationale | Domain Source |
|---------|----------|-----------|---------------|
| `tbl_usr_recs` | `user_records` | mixed prefix convention; `user_records` matches class `UserRecord` | `src/models/UserRecord.ts:12` |

Rules: every proposal MUST cite a vocabulary source (`file:line` or `CONTEXT.md`); unsourced proposals are dropped. NEVER auto-apply a rename. NEVER rewrite a consistent local convention.

## Phase 4 — Migration Safety

If migrations are in scope, check against the `skills/database-migrations/` skill:
- Expand-contract for renames/drops (no destructive DDL in one deploy)
- Concurrent index creation (`CREATE INDEX CONCURRENTLY` / pt-osc / gh-ost for large tables)
- Lock timeouts set; batched backfills for data changes
- Rollback path documented

## Phase 5 — Structured Report

```markdown
## Engine Coverage
| Engine | ORM | Confidence | Evidence |
|--------|-----|------------|----------|

## Findings by Severity
### CRITICAL / HIGH / MEDIUM / LOW
- <finding> — `<file>:<line>`

## Rename Proposals (proposal-only)
<table from Phase 3>

## Out of Scope
- Cassandra, Firestore, Neo4j (no engine signals / no dedicated skill)
- SQLite (inline guidance only)
```

## Prohibitions

- Never auto-apply renames; the table is a proposal for the owner
- Never assume PostgreSQL when detection failed
- Never edit schema files, run migrations, or touch the database
- Never emit a finding without `file:line` evidence
