# Implementation Plan: `/database-review` — Multi-Engine SQL + NoSQL + Business-Naming Review

## Overview

A generic `/database-review` Lead Orchestrator command with 6 phases: fail-closed engine/ORM detection → change scoping → engine-specific review via dispatch to existing ECC skills → business naming & domain-fit review (the differentiator vs. plain SQL linters) → migration safety → structured report. The existing PostgreSQL-hardwired `database-reviewer` agent is generalized into a modular engine dispatcher, and two new skills (`mongodb-patterns`, `dynamodb-patterns`) close the verified NoSQL gap. Authoritative source: `docs/research/database-review-command.md`.

Effort: Medium (1–2 days). Owner decisions taken (this session): defer prose translations of the agent's 7 locale copies; leave `manifests/pi-core.json` / `pi/core/` untouched; mirror the command + prompt into `~/.config/opencode/`.

## Requirements

### Functional
- R1. Phase 0 — Engine & ORM detection, FAIL-CLOSED. Scan deterministic signals: `package.json` deps (`pg`, `mysql2`, `mongodb`, `@aws-sdk/client-dynamodb`, `ioredis`, `clickhouse`, `redis`), `schema.prisma`, `drizzle.config.ts`, `settings.py` `DATABASES` block, `application.yml`, `alembic.ini`, `knexfile.*`, mongo/clickhouse/redis config files. Output an engine matrix `{engine, orm, confidence, evidence file:line}`. Low/zero confidence → ask the user via the question tool. Never silently default to Postgres.
- R2. Phase 1 — Scope: `git diff --name-only HEAD` filtered to migrations/schema/ORM/SQL files. Argument modes: explicit path | full-schema | `--naming` (naming-focused). No DB files in scope → say so and stop.
- R3. Phase 2 — Engine-specific review by dispatch to `database-reviewer` (generalized), which routes to repo-native skills: `postgres-patterns`, `mysql-patterns`, `clickhouse-io`, `redis-patterns`, `prisma-patterns`, `jpa-patterns`, `mybatis-patterns`, `kotlin-exposed-patterns`, plus the new `mongodb-patterns` / `dynamodb-patterns`; SQLite gets inline guidance (no dedicated skill — YAGNI). Every finding MUST cite `file:line`. Severity requires evidence (PoC gate in the style of `security-reviewer`); unsupported claims are downgraded, not asserted.
- R4. Phase 3 — Business naming & domain-fit review: (1) extract codebase vocabulary (entity/class/DTO/API names, `CONTEXT.md` glossary if present); (2) check names against (a) ubiquitous language, (b) local conventions — if the codebase is already consistent (e.g. singular snake_case), follow it; greenfield default is plural snake_case tables + singular columns + `<entity>_id` FKs + `created_at/updated_at/deleted_at` + `idx_/uq_/fk_` prefixes; (c) per-engine reserved words (e.g. `order`); (d) identifier length limits. Output = Rename Proposal Table `current → proposed → rationale → domain source (file:line)`. PROPOSAL-ONLY: never auto-apply, never rewrite a consistent local convention.
- R5. Phase 4 — Migration safety via `database-migrations` skill: expand-contract, concurrent index creation, lock timeouts, batched backfill.
- R6. Phase 5 — Structured report: engine coverage table, findings by severity (each with file:line), rename proposal table, out_of_scope list (Cassandra, Firestore, Neo4j, dedicated SQLite skill explicitly labeled).
- R7. Distinct entry points: the new command must not overlap `/code-review`, `/security`, or the plain `database-reviewer` agent invocation — its value is routing + the business-fit/naming layer.

### Non-functional
- R8. Zero new runtime dependencies. No new scripts. No `node scripts/*.js` references inside the new command files (keeps `tests/scripts/npm-publish-surface.test.js` allowlist untouched).
- R9. No absolute personal paths (`/Users/<name>`) in `commands/`, `agents/`, `docs/`, `.opencode/commands/` (enforced by `scripts/ci/validate-no-personal-paths.js`).
- R10. No `model` field in `.opencode/opencode.json` (root or per-agent) — enforced by `tests/opencode-config.test.js`.
- R11. Skill house style: `skills/<name>/SKILL.md` with frontmatter `name` matching directory, inline-scalar `description` (not `|` block), "When to Activate", "Anti-Patterns", < 500 lines (800 max), `origin: ECC`.
- R12. Codex copies: `.agents/skills/<name>/SKILL.md` frontmatter restricted to `name`, `description`, `license`, `metadata`, `allowed-tools`; `name` must equal directory; companion `.agents/skills/<name>/agents/openai.yaml` with `display_name`, `short_description` (25–64 chars), `default_prompt` containing `$<name>` — enforced by `tests/ci/codex-skill-surface.test.js`.

## Architecture Changes

### New files
```
skills/mongodb-patterns/SKILL.md                     # canonical skill (adapted from MongoDB official agent-skills — reference only)
skills/dynamodb-patterns/SKILL.md                    # canonical skill (Alex DeBrie single-table, AWS GSI docs, konishi key-design dictionary)
.agents/skills/mongodb-patterns/SKILL.md             # Codex copy (frontmatter allowlist)
.agents/skills/mongodb-patterns/agents/openai.yaml   # Codex metadata
.agents/skills/dynamodb-patterns/SKILL.md            # Codex copy
.agents/skills/dynamodb-patterns/agents/openai.yaml  # Codex metadata
commands/database-review.md                          # canonical command (frontmatter + Lead Orchestrator body)
.opencode/commands/database-review.md                # OpenCode orchestrator body
```

### Modified files
```
agents/database-reviewer.md                          # PostgreSQL-hardwired → modular multi-engine dispatcher (keep Prompt Defense Baseline)
.opencode/prompts/agents/database-reviewer.txt       # mirror of the generalized prompt (active OpenCode prompt)
.opencode/opencode.json                              # + command["database-review"]; agent["database-reviewer"].tools → read-only pattern
~/.config/opencode/opencode.json                     # mirror command entry (backup first)
~/.config/opencode/prompts/agents/database-reviewer.txt  # mirror prompt
agent.yaml                                           # + "- database-review" (between "cpp-test" and "ecc-guide")
package.json                                         # files[] += "skills/dynamodb-patterns/", "skills/mongodb-patterns/"
manifests/install-modules.json                       # database module paths[] += the 2 new skills
docs/COMMAND-REGISTRY.json                           # regenerated (99 commands)
COMMANDS-QUICK-REF.md                                # + row
docs/COMMAND-AGENT-MAP.md                            # + row
README.md, AGENTS.md, SOUL.md, .gemini/GEMINI.md, README.zh-CN.md,
docs/zh-CN/README.md, docs/zh-CN/AGENTS.md,
.claude-plugin/plugin.json, .claude-plugin/marketplace.json   # counts via catalog:sync (318→320 skills, 98→99 commands)
```

### Deliberately NOT touched (owner decision, this session)
- `manifests/pi-core.json` and `pi/core/` — new command + skills are simply absent from the portable bundle. `scripts/build-pi-core.js` only validates that manifest-referenced files exist; unclassified is legal, so there is no CI drift. Upgrade path when portability is wanted: add to `commands.exclude` / `skills.include`, then `node scripts/build-pi-core.js` and commit the regenerated `pi/core`.
- Prose of the 7 locale agent copies `docs/{es,ja-JP,ko-KR,pt-BR,tr,zh-CN,zh-TW}/agents/database-reviewer.md`. `tests/ci/locale-agent-frontmatter.test.js` compares only `name`/`model`/`tools`, which stay byte-identical (`database-reviewer` / `sonnet` / `Read, Grep, Glob, Bash`), so deferral is test-safe.
- `skills/` translation mirrors, `.opencode/MIGRATION.md`, `.opencode/README.md`, `.opencode/instructions/INSTRUCTIONS.md` agent-table prose (cosmetic, follow-up).

### Key contracts

**`.opencode/opencode.json` additions (no `model` key anywhere):**
```json
"command": {
  "database-review": {
    "description": "Multi-engine database review (PostgreSQL/MySQL/SQLite/ClickHouse/MongoDB/DynamoDB/Redis + ORMs): fail-closed engine detection, engine-specific review, business naming proposals, migration safety",
    "template": "{file:commands/database-review.md}\n\n$ARGUMENTS"
  }
},
"agent": {
  "database-reviewer": {
    "description": "...",
    "mode": "subagent",
    "prompt": "{file:prompts/agents/database-reviewer.txt}",
    "tools": { "read": true, "grep": true, "glob": true, "bash": true, "write": false, "edit": false }
  }
}
```
Tool change rationale: canonical frontmatter is `Read, Grep, Glob, Bash`; research §5.2 says retain exactly that; the current `write/edit: true` contradicts the read-only reviewer contract (the historical locale-drift bug this repo already fixed for `security-reviewer`/`database-reviewer`). The orchestrator (main agent) owns all report writing.

**Command body structure** (`commands/database-review.md` and `.opencode/commands/database-review.md`):
- Frontmatter: `description` (explicitly distinguishing `/code-review` and direct agent use) + `argument-hint: "[path | --naming | --full-schema]"`. No `agent:` frontmatter (it is an orchestrator, like `/security-audit` and `/deep-research`; declaring one would force single-agent routing).
- Phase 0 detection table (signal → engine/orm) + the fail-closed rule + the question-tool fallback.
- Phase 1 scope command + stop rule.
- Phase 2 dispatch table naming `@database-reviewer` and the skill per engine (the `@database-reviewer` mention also lets `generate-command-registry.js` record `primaryAgents`).
- Phase 3 naming rules + Rename Proposal Table template.
- Phase 4 migration checklist pointer.
- Phase 5 report skeleton (engine coverage, findings by severity with file:line, rename proposals, out_of_scope).
- Prohibitions: never auto-apply renames; never assume Postgres; never edit schema files.

## Implementation Steps

### Phase 1 — Two new canonical skills (no dependents; independently verifiable)
1. **Write `skills/dynamodb-patterns/SKILL.md`**
   - Action: access-pattern-first design; PK/SK composite keys and item collections; GSI overloading; GSI-vs-LSI decision matrix; hot-partition avoidance (write sharding, partition-key cardinality); Scan-as-antipattern; TTL items; capacity/cost notes. Cite Alex DeBrie, AWS GSI docs, hidekazu-konishi dictionary in a References section; state adaptation (not verbatim copy).
   - Why: R3/R6 — DynamoDB is a verified gap; F5 says meaningful NoSQL review is access-pattern-first.
   - Dependencies: none. Risk: Low.
2. **Write `skills/mongodb-patterns/SKILL.md`**
   - Action: schema validation rules; index–query alignment; antipattern "unnecessary collections"; embedding vs referencing; connection pooling / serverless patterns; aggregation basics. Reference MongoDB official agent-skills content as adaptation source.
   - Why: R3/R6 — MongoDB gap (currently only incidental coverage in `prisma-patterns`/`java-reviewer`).
   - Dependencies: none. Risk: Low.
3. **Verify**: `node scripts/ci/validate-skills.js` and `node scripts/ci/validate-skill-host-compat.js` (canonical checklist: When to Activate, Anti-Patterns, name==dir, line caps). Fix findings before proceeding.

### Phase 2 — Codex mirrors (independently verifiable)
4. **Write `.agents/skills/{mongodb,dynamodb}-patterns/SKILL.md` + `agents/openai.yaml`**
   - Action: copy the canonical skills; strip frontmatter to the Codex allowlist (`name`, `description`, `license: MIT`, `metadata` — no `origin`); rewrite any `${CLAUDE_*}` substitutions in executable fences (none planned). openai.yaml per the api-design template: `interface.display_name`, `short_description` (count characters: must be 25–64), `brand_color`, `default_prompt: "Use $mongodb-patterns ..."` (must contain `$<skill-name>`).
   - Why: R12 — Codex parity, enforced by test.
   - Dependencies: steps 1–2. Risk: Low — the 25–64 char `short_description` window is the easiest thing to fail; verify with `node tests/ci/codex-skill-surface.test.js`.

### Phase 3 — Generalize the agent (independently verifiable)
5. **Rewrite `agents/database-reviewer.md`**
   - Action: keep frontmatter `name: database-reviewer`, `model: sonnet`, `tools: Read, Grep, Glob, Bash` (comma scalar — NOT a YAML sequence; enforced by `scripts/ci/validate-agents.js`) and the Prompt Defense Baseline block verbatim. New description: multi-engine database specialist. Body becomes a dispatcher: (a) engine-detection signal table (same as command Phase 0); (b) routing table engine/ORM → skill (`postgres-patterns`, `mysql-patterns`, `clickhouse-io`, `redis-patterns`, `prisma-patterns`, `jpa-patterns`, `mybatis-patterns`, `kotlin-exposed-patterns`, `mongodb-patterns`, `dynamodb-patterns`, SQLite inline); (c) Postgres module = the current prompt's content preserved (diagnostics, RLS, indexes, anti-patterns); (d) per-engine compact checklists for MySQL/SQLite/ClickHouse/Mongo/Dynamo/Redis that defer depth to the skills; (e) naming/domain-fit rules supporting command Phase 3 (vocabulary grounding, proposal-only); (f) evidence gate: findings cite file:line, severity needs proof; (g) read-only bash diagnostics per engine (`psql`, `mysql EXPLAIN`, `redis-cli INFO`, `mongosh --eval` read-only) documented honestly as the residual need for Bash.
   - Why: research §5.2. Dependencies: steps 1–2 (routing targets exist). Risk: Medium — prompt bloat; keep per-engine modules as short checklists that point at skills, target < ~250 lines.
6. **Mirror to `.opencode/prompts/agents/database-reviewer.txt`**
   - Action: same content, OpenCode prompt conventions (no YAML frontmatter in the `.txt`). Dependencies: step 5. Risk: Low.
7. **Verify**: `node scripts/ci/validate-agents.js`, `node tests/ci/validate-agents-tools.test.js`, `node tests/ci/locale-agent-frontmatter.test.js` (proves frontmatter parity with the 7 locale copies), `node tests/ci/agent-instruction-safety.test.js` if the agent is in its target list.

### Phase 4 — Command files (independently verifiable)
8. **Write `commands/database-review.md`**
   - Action: full 6-phase orchestrator per "Key contracts" above; argument modes path | `--naming` | `--full-schema`; include the engine-detection signal table, the dispatch table (mentioning `@database-reviewer` and each skill by `skills/<name>/` path so validators resolve them), the naming rule set, the Rename Proposal Table template, the report skeleton, and the out_of_scope label list. Reference `agents/database-reviewer.md` by path at least once.
   - Why: R1–R7. Dependencies: steps 1–2 (skill refs resolve), step 5 (agent ref resolves). Risk: Medium — cross-reference typos fail `validate-commands.js`; run it immediately.
9. **Write `.opencode/commands/database-review.md`**
   - Action: same body under OpenCode conventions (frontmatter `description` + `argument-hint`, `$ARGUMENTS` placeholder, Lead Orchestrator framing like `security-audit.md`). Dependencies: step 8. Risk: Low.
10. **Verify**: `node scripts/ci/validate-commands.js` (frontmatter parses; every `` `/command` `` ref exists in `commands/`; `agents/<name>.md` and `skills/<name>/` refs resolve). Also `node tests/scripts/npm-publish-surface.test.js`-relevant check: the command must contain no `node scripts/...js` references.

### Phase 5 — Wiring (each step independently verifiable)
11. **`agent.yaml`**: insert `- database-review` between `- cpp-test` and `- ecc-guide` (alphabetical; `tests/ci/agent-yaml-surface.test.js` deep-equals this list against `commands/`).
    - Verify: `node tests/ci/agent-yaml-surface.test.js`.
12. **`package.json` files[]**: add `"skills/dynamodb-patterns/"` (after `skills/dynamic-workflow-mode/`) and `"skills/mongodb-patterns/"` (between `skills/mybatis-patterns/` and `skills/mysql-patterns/`). Membership/coverage is what tests check; position is convention.
    - Verify: `python3 -m json.tool package.json > /dev/null` + `git diff package.json` review.
13. **`manifests/install-modules.json`**: add both paths to the `database` module's `paths[]` (sorted: clickhouse-io, database-migrations, dynamodb-patterns, jpa-patterns, mongodb-patterns, mybatis-patterns, mysql-patterns, postgres-patterns, prisma-patterns, redis-patterns).
    - Why: `scripts/ci/validate-install-manifests.js` errors when a curated `skills/` directory is not referenced by any module (`INTENTIONALLY_UNSHIPPED_SKILL_IDS` is empty).
    - Verify: `python3 -m json.tool` + `node scripts/ci/validate-install-manifests.js`.
14. **`.opencode/opencode.json`**: add the `command["database-review"]` entry (template `{file:commands/database-review.md}\n\n$ARGUMENTS`) and change `agent["database-reviewer"].tools` to the read-only pattern per "Key contracts". Do not add any `model` field.
    - Verify: `python3 -m json.tool .opencode/opencode.json > /dev/null` + `node tests/opencode-config.test.js` (proves: no root/agent `model`, every `{file:...}` ref resolves, command agent ids registered — our command declares none, so only the prompt ref is checked).
15. **Mirror to `~/.config/opencode/`** (owner-approved): copy `.opencode/opencode.json`'s new command entry into `~/.config/opencode/opencode.json` (make a `.bak-<timestamp>` copy first — the dir already carries that convention) and copy `.opencode/prompts/agents/database-reviewer.txt` to `~/.config/opencode/prompts/agents/database-reviewer.txt`.
    - Verify: `python3 -m json.tool ~/.config/opencode/opencode.json > /dev/null`; confirm the prompt file exists at the mirrored path.
16. **CAUTION (repo history)**: a previous insert-sorted script edited the wrong JSON arrays twice. After EVERY JSON edit in this phase run `python3 -m json.tool` and review `git diff` on that single file before moving on.

### Phase 6 — Regeneration (independently verifiable)
17. **`npm run catalog:sync`** — updates counts (skills 318→320, commands 98→99) in README.md, AGENTS.md, SOUL.md, .gemini/GEMINI.md, README.zh-CN.md, docs/zh-CN/{README,AGENTS}.md, .claude-plugin/plugin.json, .claude-plugin/marketplace.json.
    - Verify: `npm run catalog:check`.
18. **`npm run command-registry:write`** (`scripts/ci/generate-command-registry.js`) — regenerates `docs/COMMAND-REGISTRY.json` (totalCommands 99; new entry with `primaryAgents: ["database-reviewer"]` and the dispatched skills).
    - Verify: `npm run command-registry:check`; inspect the new entry.
19. **Confirm no pi/core drift**: `git status --porcelain pi/core manifests/pi-core.json` must be empty (we deliberately did not touch them).

### Phase 7 — Docs rows
20. **`COMMANDS-QUICK-REF.md`**: add a `/database-review` row in the Code Review section (next to `/code-review` / `/issue-review`). Do not "fix" the stale header count (out of scope).
21. **`docs/COMMAND-AGENT-MAP.md`**: add `| /database-review | database-reviewer | Multi-engine DB review + business naming proposals (proposal-only) |` after the `/code-review` row.

### Phase 8 — Full gate
22. **`npm test`** — runs `test:validators` (unicode-safety, validate-agents, validate-commands, validate-rules, validate-skills, validate-skill-host-compat, validate-hooks, hooks-schema-keys, validate-install-manifests, validate-context-profiles, validate-carrier-closure, validate-no-personal-paths, catalog:check, command-registry:check) plus `node tests/run-all.js`. All must pass.
23. **TDD evidence**: if any behavior-bearing helper is added (none planned — this change is prompt/config only), follow the `tdd-workflow` RED→GREEN cycle and write the evidence report. For this change the validators ARE the tests; record the command list and outcomes in the commit body.

## Testing Strategy

- **Unit / contract (the validators, per phase above)**: `validate-skills.js`, `validate-skill-host-compat.js`, `tests/ci/codex-skill-surface.test.js`, `validate-agents.js`, `tests/ci/validate-agents-tools.test.js`, `tests/ci/locale-agent-frontmatter.test.js`, `validate-commands.js`, `tests/ci/agent-yaml-surface.test.js`, `tests/opencode-config.test.js`, `validate-install-manifests.js`, `catalog:check`, `command-registry:check`.
- **JSON integrity**: `python3 -m json.tool` after each JSON edit + single-file `git diff` review (repo-history risk).
- **Fixture smoke test (detection, fail-closed)**: throwaway repo A with `package.json` deps `pg` + `mongodb` + a `schema.prisma` → engine matrix must list PostgreSQL/Prisma and MongoDB with file:line evidence. Throwaway repo B with zero DB signals → command must ask the user (question tool), and must NOT emit a Postgres assumption. Throwaway repo C with `application.yml` + `alembic.ini` → MySQL/Postgres detection with evidence.
- **Fixture smoke test (naming, proposal-only)**: fixture with a mixed-convention schema (`tbl_usr_recs`, `order` table, `userID` column) → Rename Proposal Table must (a) ground every proposal in a codebase vocabulary source with file:line, (b) respect an already-consistent local convention when present (add a second fixture that is consistently singular → expect "follow local convention", no rewrite proposals), (c) flag reserved words, (d) never modify files.
- **Fixture smoke test (engine review)**: one planted issue per engine family (e.g. missing FK index in Postgres, Scan-as-access-pattern in DynamoDB, unvalidated collection in MongoDB) → each must appear with file:line and correct severity; the DynamoDB one must route to `dynamodb-patterns`.
- **E2E**: invoke `/database-review` in OpenCode against a fixture repo (both scope modes), then against the ECC repo itself to exercise the "no schema files in scope" stop path. Confirm the command is listed by `opencode` in both workspace and (post-mirror) global scope.
- **Negative/regression**: `npm test` full suite; confirm `/code-review`, `/security`, `/security-audit` descriptions and the `database-reviewer` agent description do not collide.

## Risks & Mitigations

- **Risk: JSON corruption during wiring** (this repo has been bitten twice by an insert-sorted script hitting the wrong arrays). Mitigation: one JSON file per step, `python3 -m json.tool` immediately, `git diff --stat` review, Phase 5 split into single-file steps (11–15).
- **Risk: engine misdetection → shallow or wrong review.** Mitigation: fail-closed Phase 0 with the question-tool fallback; the "never default to Postgres" rule is stated in both the command and the agent prompt; the fixture tests (B) assert the ask-path.
- **Risk: naming review becomes a per-PR bikeshed.** Mitigation: proposal-only Rename Proposal Table; consistency-over-choice rule (follow an existing consistent convention); naming review runs on schema-file changes or `--naming` only.
- **Risk: LLM invents ungrounded names.** Mitigation: every proposal must cite a vocabulary source (`file:line` or `CONTEXT.md`); unsourced proposals are dropped from the table.
- **Risk: locale frontmatter drift breaks `locale-agent-frontmatter.test.js`.** Mitigation: frontmatter (`name`/`model`/`tools`) stays byte-identical; prose translation deferred by owner decision; the test is run in Phase 3.
- **Risk: `model` field regression in `.opencode/opencode.json`.** Mitigation: `tests/opencode-config.test.js` runs in Phase 5 and again in `npm test`.
- **Risk: Codex `short_description` length (25–64 chars) or frontmatter allowlist violations.** Mitigation: `tests/ci/codex-skill-surface.test.js` in Phase 2 before any wiring depends on the copies.
- **Risk: new curated skills unreferenced by install manifests.** Mitigation: `validate-install-manifests.js` in Phase 5; both skills added to the `database` module.
- **Risk: command/skill cross-reference typos.** Mitigation: `validate-commands.js` runs immediately after Phase 4; skills and agent exist before the command references them (phase ordering).
- **Risk: personal paths leak into shipped files.** Mitigation: `validate-no-personal-paths.js` in `npm test`; use env-var style (`$DATABASE_URL`) and relative paths only.
- **Risk: agent prompt bloat degrades review quality.** Mitigation: per-engine modules are short checklists deferring to skills; Postgres module preserved as the depth reference.

## Success Criteria

- [ ] `/database-review` exists in `commands/database-review.md` AND `.opencode/commands/database-review.md`, and is registered in both `.opencode/opencode.json` and `~/.config/opencode/opencode.json`; both JSON files parse (`python3 -m json.tool`).
- [ ] `agent.yaml` lists `database-review`; `node tests/ci/agent-yaml-surface.test.js` passes.
- [ ] `agents/database-reviewer.md` is a multi-engine dispatcher with unchanged frontmatter; `.opencode/prompts/agents/database-reviewer.txt` mirrors it; the OpenCode agent entry has no `model` and read-only tools; `node tests/opencode-config.test.js` passes.
- [ ] `skills/mongodb-patterns/` and `skills/dynamodb-patterns/` exist, validate (`validate-skills.js`), and have Codex copies passing `tests/ci/codex-skill-surface.test.js`; both are in `package.json` files[] and the `database` install module.
- [ ] `npm run catalog:check` and `npm run command-registry:check` pass with counts 320 skills / 99 commands; `docs/COMMAND-REGISTRY.json` contains the new entry with `primaryAgents: ["database-reviewer"]`.
- [ ] `git status --porcelain pi/core manifests/pi-core.json` is empty (portable bundle untouched, no CI drift).
- [ ] Fixture A produces a correct engine matrix with file:line evidence; fixture B asks the user instead of defaulting to Postgres; fixture C detects the ORM/config stack.
- [ ] The naming fixture yields a sourced Rename Proposal Table, respects an already-consistent local convention, flags reserved words, and modifies no files.
- [ ] Planted per-engine findings are reported with file:line and severity; unsupported findings are downgraded; Cassandra/Firestore/Neo4j appear only under `out_of_scope`.
- [ ] `COMMANDS-QUICK-REF.md` and `docs/COMMAND-AGENT-MAP.md` carry the new rows; full `npm test` passes.
