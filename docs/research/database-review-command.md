# Riset: Command `/database-review` Generik (Multi-Engine SQL + NoSQL) dengan Review Penamaan Bisnis

- **Tanggal riset**: 2026-11-04
- **Motivasi**: User meminta command review database yang generik — tidak hanya PostgreSQL, mencakup SQL populer dan NoSQL — plus kemampuan menilai/mengusulkan penamaan tabel & kolom sesuai kebutuhan bisnis di codebase.
- **Metode**: Codebase grounding (2 explore subagent paralel) + external multi-source search (websearch/webfetch; Exa MCP mengembalikan 0 hasil untuk semua query — dicatat sebagai keterbatasan harness, bukan sebagai tidak adanya sumber).

---

## 1. Executive Summary

**Bottom line:** Bangun `/database-review` sebagai orchestrator 6 fase: deteksi engine/ORM fail-closed → scope perubahan → review engine-specific via dispatch ke skill yang sudah ada → **review penamaan & domain-fit** (pembeda utama vs linter biasa) → migration safety → laporan terstruktur. Agent `database-reviewer` yang ada harus digeneralisasi dari PostgreSQL-hardwired menjadi dispatcher ber-modul engine. Dua skill baru diperlukan: `mongodb-patterns` dan `dynamodb-patterns`. Skill eksternal (Atlas, MongoDB resmi, Microsoft postgres-skills) layak dijadikan **referensi adaptasi**, bukan instalasi, karena terkopla CLI/MCP pihak ketiga.

**Effort:** Medium (1-2 hari). **Risko utama:** deteksi engine salah → review dangkal; mitigasi wajib fail-closed dengan konfirmasi user.

---

## 2. Codebase Context & Compatibility

### 2.1 Aset yang sudah ada (hasil Phase 0 grounding)

| Aset | Path | Cakupan |
|---|---|---|
| `database-reviewer` (agent) | `agents/database-reviewer.md` | **PostgreSQL/Supabase-hardwired** — diagnostik `psql`, `pg_stat_statements`, RLS |
| `postgres-patterns` | `skills/postgres-patterns/` | PostgreSQL lengkap (index, RLS, pooling) |
| `mysql-patterns` | `skills/mysql-patterns/` | MySQL/MariaDB (InnoDB, replikasi, lock) |
| `database-migrations` | `skills/database-migrations/` | Multi-engine expand-contract, zero-downtime |
| `clickhouse-io` | `skills/clickhouse-io/` | OLAP MergeTree, materialized views |
| `prisma-patterns` | `skills/prisma-patterns/` | Multi-engine ORM (termasuk MongoDB) |
| `redis-patterns` | `skills/redis-patterns/` | Key-value, lock, rate limit |
| `jpa/mybatis/kotlin-exposed` | `skills/` | ORM per-ekosistem Java/Kotlin |
| `context-and-decisions` | `skills/context-and-decisions/` | Glosarium domain, disambiguasi istilah |

**Gap terverifikasi:** tidak ada command DB sama sekali; MongoDB hanya terselip di `java-reviewer`/`prisma-patterns`; DynamoDB/Cassandra/Firestore tidak ada; SQLite tanpa skill dedikasi.

### 2.2 Wiring chain (untuk command + agent baru)

1. `commands/database-review.md` (repo) + `.opencode/commands/database-review.md` (orchestrator)
2. `.opencode/opencode.json`: entri `command` (template `{file:commands/database-review.md}\n\n$ARGUMENTS`) + modifikasi entri `agent` `database-reviewer` (prompt + tools)
3. `.opencode/prompts/agents/database-reviewer.txt` (prompt aktif OpenCode)
4. `agent.yaml` (commands array, alphabetical — ditegakkan `tests/ci/agent-yaml-surface.test.js`)
5. `manifests/pi-core.json` (kategorisasi command aktif/excluded)
6. `npm run catalog:sync` + `npm run command-registry:write` (counts + registry)
7. `COMMANDS-QUICK-REF.md` + `docs/COMMAND-AGENT-MAP.md`
8. `.opencode/opencode.json` **tidak boleh** memuat field `model` (ditegakkan `tests/opencode-config.test.js`) — pin model hidup di `~/.config/opencode/opencode.jsonc`
9. Validator: `scripts/ci/validate-commands.js` (frontmatter + referensi agent/skill harus resolve)

---

## 3. Key Findings (bertriangulasi)

### F1. Deteksi engine dari config repo adalah praktik standar dan reliabel
Sinyal deterministik: `package.json` deps (`pg`, `mysql2`, `mongodb`, `@aws-sdk/client-dynamodb`, `ioredis`), file config (`schema.prisma`, `drizzle.config.ts`, `settings.py` blok `DATABASES`, `application.yml`, `alembic.ini`, `knexfile`). **[UNVERIFIED - SINGLE SOURCE]** tidak ditemukan benchmark false-positive rate untuk heuristik ini — karena itu desain wajib fail-closed: confidence rendah → tanya user, jangan default Postgres.

### F2. Plural vs singular: konsistensi mengalahkan pilihan; default aman = plural
- **Bytebase (Okt 2025)**: "Pick one style, document it, and stick to it... plural tables (`users`, `orders`) are a safe default" — konvensi copy-paste: tabel plural snake_case; join table plural+plural alphabetical (`orders_products`, `roles_users`); kolom singular (`id`, `user_id`, `created_at`); view berprefiks (`v_active_users`, `mv_daily_signups`); reserved-word avoidance (`orders` aman dari `order`).
- **Navicat**: "most DBAs go with singular names" — plural berujung nama aneh (`users_have_roles`).
- **databasestar / Prisma blog / Rails**: plural snake_case sebagai konvensi modern dominan.
- **Kesimpulan**: dua kamp legitimated; rekomendasi = **plural tabel + singular kolom + snake_case untuk greenfield**, singular dihormati bila codebase sudah konsisten singular (ikuti konvensi lokal, jangan rewrite). Aturan tunggal yang tidak bisa ditawar: **konsistensi + terdokumentasi**.

### F3. DDD Ubiquitous Language adalah metodologi jangkar penamaan bisnis
- **Evans (Wikipedia/MSDN archive)**: vocabulary bersama domain sebagai cornerstone; setiap bounded context memiliki bahasanya sendiri.
- **Milan Jovanović (practical guide)**: "The Translation Problem" — kode berkata "insert/DTO/entity" alih-alih bahasa domain; FAQ: CRUD language bukan bagian ubiquitous language.
- **Enterprise Craftsmanship**: DDD explicitly emphasizes naming via Ubiquitous Language.
- **arXiv 2607.06471 (2026, empirical)**: Ubiquit Language surfaces directly in code (Policy entity, Premium, Coverage).
- **Aplikasi ke command**: penamaan diekstrak dari kosakata yang SUDAH ada di codebase (nama class/entity/DTO/API/glosarium `CONTEXT.md`), bukan dikarang LLM. Nama tabel = jamak dari istilah domain; kolom = atribut istilah; FK = `<entity_singular>_id`.

### F4. Ekosistem skill AI untuk DB sudah matang — dan semuanya engine-per-engine
| Sumber | Isi | Verdict untuk ECC |
|---|---|---|
| **Atlas Agent Skills** (atlasgo.io) | Skill resmi mengikuti Agent Skills open standard; `atlas-postgres`, `atlas-mysql`, `atlas-mssql`, ...; workflow inspect→validate→diff→lint→dry-run | **Referensi.** Terkopla Atlas CLI; ECC `database-migrations` sudah menutup expand-contract. Catat sebagai alternatif governance. |
| **MongoDB official** (`mongodb/agent-skills`) | `mongodb-schema-design` (+ `antipattern-unnecessary-collections`), `mongodb-query-optimizer`, `mongodb-connection`, `mongodb-search-and-ai` | **Adaptasi.** MongoDB adalah gap nyata di ECC. Pola validation+index masuk ke skill baru `mongodb-patterns`. |
| **Microsoft postgres-skills** | 32 sub-skill + `postgres-mcp` (live schema/roles/extensions) | **Referensi.** `postgres-patterns` ECC (basis Supabase) sudah komprehensif; MCP live-context bisa dicatat sebagai upgrade opsional. |
| **Supabase postgres-best-practices** | Sudah menjadi basis `postgres-patterns` | Sudah teradopsi. |
| **VoltAgent/awesome-agent-skills** | Katalog 1000+ (termasuk entri di atas) | Sumber discovery. |

### F5. Review NoSQL yang bermakna = access-pattern-first, bukan schema-first
- **DynamoDB** (Alex DeBrie — single-table design; hidekazu-konishi key design dictionary; AWS GSI docs): PK/SK composite key, item collections, **GSI overloading**, hot-partition avoidance via sharding, GSI vs LSI decision matrix. Review checklist: setiap query pattern punya akses path; tidak ada Scan sebagai pola normal; partition key kardinalitas cukup.
- **MongoDB** (skill resmi MongoDB): schema validation rules, index keselarasan query, antipattern koleksi tidak perlu, connection pool/serverless patterns.
- **Redis**: key naming namespaced, TTL discipline, eviction policy — sebagian sudah di `redis-patterns`.

---

## 4. Adversarial Trade-offs

| Argumen tahan | Mitigasi dalam desain |
|---|---|
| Command generik → lowest-common-denominator, trap engine-specific terlewat (MySQL DDL auto-commit, SQLite write lock, Postgres RLS) | Deteksi fail-closed + dispatch ke skill engine spesifik; engine tak terdeteksi → **tanya user**, bukan asumsi Postgres |
| LLM mengarang nama yang tidak grounded | Nama harus cite sumber kosakata (file:line di codebase atau glosarium); output rename = **tabel proposal** (current → proposed → rationale → sumber), tidak pernah auto-apply |
| Overlap dengan linter existing (Atlas lint, Bytebase SQL advisor) | Nilai command = routing + lapisan business-fit/penamaan yang tidak dimiliki linter; bukan re-implementasi lint SQL |
| Scope creep: Cassandra, Neo4j, Firestore, SQLite... | In-scope: PostgreSQL, MySQL/MariaDB, SQLite, ClickHouse, MongoDB, DynamoDB, Redis (+ ORM terdeteksi). Sisanya `out_of_scope` eksplisit di laporan |
| Naming review jadi bikeshaft di setiap PR | Command mengusulkan **hanya saat diminta** atau saat schema file berubah; default-nya enforce konvensi existing (ikuti lokal), bukan rewrite |

---

## 5. Actionable Recommendation (siap untuk `/plan`)

### 5.1 Desain command `/database-review` (6 fase)

```
Phase 0 — Engine & ORM Detection (FAIL-CLOSED)
  Scan: package.json deps, schema.prisma, drizzle.config.ts, settings.py,
        application.yml, alembic.ini, knexfile, clickhouse/mongo/redis configs
  Output: engine matrix {engine, orm, confidence, evidence file:line}
  Confidence rendah → question tool minta user deklarasi; DILARANG default Postgres

Phase 1 — Scope & Change Detection
  git diff --name-only HEAD → migrations/schema/ORM/SQL files
  Mode argumen: path spesifik | full-schema | --naming (fokus review penamaan)

Phase 2 — Engine-Specific Review (dispatch database-reviewer generalisasi)
  SQL: postgres-patterns | mysql-patterns | clickhouse-io | sqlite-inline
  NoSQL: mongodb-patterns (baru) | dynamodb-patterns (baru) | redis-patterns
  ORM: prisma-patterns | jpa-patterns | mybatis-patterns | kotlin-exposed-patterns
  Semua temuan WAJIB cite file:line; severity butuh bukti (PoC gate gaya security-reviewer)

Phase 3 — Business Naming & Domain-Fit Review (PEMBEDA UTAMA)
  1. Ekstrak kosakata domain dari codebase (entity/class/DTO/API + CONTEXT.md bila ada)
  2. Cek nama vs: (a) ubiquitous language, (b) konvensi (plural snake_case tabel,
     singular kolom, <entity>_id, created_at/updated_at/deleted_at, idx_/uq_/fk_),
     (c) reserved words per-engine, (d) panjang identifier
  3. Output: Rename Proposal Table — current → proposed → rationale → domain source
     ATURAN: proposal only, never auto-apply; ikuti konvensi lokal yang sudah konsisten

Phase 4 — Migration Safety (skills/database-migrations)
  expand-contract, concurrent index, lock timeout, batched backfill

Phase 5 — Report
  Engine coverage table + findings by severity + rename proposal table
```

### 5.2 Generalisasi agent `database-reviewer`

- Prompt: dari PostgreSQL-hardwired → dispatcher ber-modul (Postgres module = prompt sekarang; MySQL/SQLite/ClickHouse/Mongo/Dynamo modules mengurut ke skill masing-masing)
- Tools: pertahankan `read/bash/grep/glob`; `bash` hanya untuk diagnostik read-only (psql/mysql explain/redis-cli INFO) — dokumentasikan jujur sebagai residual need
- Sinkronkan: `agents/database-reviewer.md`, `.opencode/prompts/agents/database-reviewer.txt`, 7 terjemahan `docs/*/agents/` (catat: terjemahan bisa menyusul, jangan blokir)

### 5.3 Skill baru (2, mengikuti pola house style ECC)

1. **`skills/mongodb-patterns/SKILL.md`** — schema validation, index-query alignment, antipattern unnecessary collections (adaptasi dari skill resmi MongoDB), connection pooling/serverless
2. **`skills/dynamodb-patterns/SKILL.md`** — access-pattern-first, PK/SK design, GSI overloading, hot partition sharding, GSI vs LSI matrix (sumber: Alex DeBrie, AWS docs, konishi dictionary)

Ditunda (YAGNI, sebut sebagai out_of_scope): Cassandra, Firestore, Neo4j, SQLite dedikasi (inline guidance di command sudah cukup).

### 5.4 Langkah implementasi (urutan)

1. `/plan database-review-command` — planner susun `.plan.md` dari rekomendasi ini
2. `plan-reviewer` verifikasi referensi disk
3. Implementasi: 2 skill baru + generalisasi agent + command + wiring (5.1/5.2/§2.2)
4. `npm run catalog:sync` + `command-registry:write` + validators + `npm test`
5. Mirror ke `~/.config/opencode/` (tanya owner dulu sesuai konvensi sesi)

---

## 6. Sumber

- [Bytebase — SQL Table Naming Dilemma: Singular vs. Plural (Okt 2025)](https://www.bytebase.com/blog/sql-table-naming-dilemma-singular-vs-plural/)
- [Navicat — A Quick Guide to Naming Conventions in SQL](https://www.navicat.com/en/company/aboutus/blog/2132-a-quick-guide-to-naming-conventions-in-sql-part-1)
- [databasestar — Database Table Naming Conventions](https://www.databasestar.com/database-table-naming-conventions/)
- [Adron — Pragmatic Database Schema Naming Conventions (kamp singular/snake-avoid)](https://dev.to/adron/pragmatic-database-schema-naming-conventions-practices-and-patterns-1od5)
- [Milan Jovanović — Ubiquitous Language in DDD: A Practical Guide](https://milanjovanovic.tech/blog/ubiquitous-language-ddd)
- [Enterprise Craftsmanship — Ubiquitous Language and Naming](https://enterprisecraftsmanship.com/posts/ubiquitous-language-naming/)
- [Wikipedia — Domain-driven design](https://en.wikipedia.org/wiki/Domain-driven_design)
- [arXiv 2607.06471 — DDD in Practice: A Large-Scale Empirical Study (2026)](https://arxiv.org/html/2607.06471)
- [Atlas — Agent Skills for Claude Code, Codex, Cursor](https://atlasgo.io/guides/ai-tools/agent-skills)
- [VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills)
- [MongoDB — Get Started with AI Agent Skills](https://medium.com/@MongoDB/get-started-with-mongodb-ai-agent-skills-8f572bd91d03)
- [Microsoft Tech Community — Postgres Skills](https://techcommunity.microsoft.com/blog/adforpostgresql/postgres-skills-give-your-ai-agent-postgresql-expertise/4556705)
- [Alex DeBrie — The What, Why, and When of Single-Table Design with DynamoDB](https://alexdebrie.com/posts/dynamodb-single-table/)
- [AWS Docs — Using Global Secondary Indexes in DynamoDB](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GSI.html)
- [hidekazu-konishi — DynamoDB Key Design Dictionary](https://hidekazu-konishi.com/entry/amazon_dynamodb_key_design_gsi_lsi_dictionary.html)

*Catatan keterbatasan: Exa MCP mengembalikan 0 hasil untuk 5 query; seluruh temuan eksternal bersumber dari websearch + webfetch. Triangulasi naming (F2) bersandar pada 4 sumber independen; F1 (deteksi engine) single-source — ditandai UNVERIFIED.*
