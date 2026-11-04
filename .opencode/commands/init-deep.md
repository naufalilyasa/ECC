---
description: Generate deep, high-fidelity hierarchical AGENTS.md files (root + complexity-scored subdirectories down to leaf modules). Excludes vendor/build artifacts, computes exact 30-point directory scores, and captures granular file LOC and gotchas.
argument-hint: "[--create-new] [--max-depth=N]"
---

# Init-Deep Command (OmO Native High-Fidelity Architecture)

You are the Lead Orchestrator handling the `/init-deep` command. Your mission is to construct an exhaustive, hierarchical, high-fidelity `AGENTS.md` knowledge base across the codebase matching the gold standard of OmO native architecture (root overview + deep leaf module guides with exact line counts, 30-point scoring metrics, symbol roles, and concrete anti-patterns).

**User Arguments**: $ARGUMENTS

---

## 0. Hard Exclusions (STRICT OFF-LIMITS)
Under NO circumstances should files inside these directories be scanned, scored, or receive an `AGENTS.md`:
- Package managers & dependencies: `vendor/`, `node_modules/`, `Pods/`, `.venv/`, `venv/`, `go/pkg/`
- Build artifacts & intermediates: `build/`, `dist/`, `out/`, `target/`, `.gradle/`, `.next/`, `.turbo/`, `storage/framework/`, `storage/app/`
- IDE & VCS internals: `.git/`, `.idea/`, `.vscode/`, `.DS_Store`
- Generated code & caches: `coverage/`, `tmp/`, `*.lock`, `*.min.js`, `*.min.css`

---

## Orchestration Workflow

### Step 0: Tracking Scope Negotiation (MANDATORY Question)
Before generating or updating files, ask the user how `AGENTS.md` should be tracked:

Use the `question` tool:
- **Header**: "Penyimpanan AGENTS.md"
- **Question**: "Bagaimana Anda ingin menyimpan file AGENTS.md di repositori ini?"
- **Options**:
  1. **Committed / Siap di-push (Recommended)**: File `AGENTS.md` masuk ke Git repository agar bisa dibaca oleh rekan tim, CI/CD, dan agen di remote session.
  2. **Local Only / Private**: File `AGENTS.md` hanya ada di laptop ini (otomatis ditambahkan ke `.git/info/exclude`) sehingga tidak akan ter-commit atau ter-push.

---

### Step 1: Pre-Calculation Sizing & 30-Point Scoring Script
Run a deterministic Node/Python eval script on the host to measure the real project surface:

1. **Calculate Global Metrics**:
   - Total source files (excluding blacklist)
   - Total source lines of code (LOC)
   - Maximum directory depth (respect `--max-depth`, default 4)
   - Identify all **Hotspot Files (>500 lines)** with their exact LOC and paths.

2. **Compute 30-Point Scoring Matrix per Directory**:
   Score each candidate folder against the 8-factor rubric:
   - **File count (max 6 pts)**: >10 files (3 pts), >20 files (6 pts).
   - **LOC density (max 6 pts)**: >1,000 LOC (3 pts), >3,000 LOC (6 pts).
   - **Subdir count (max 4 pts)**: >3 subdirs (2 pts), >5 subdirs (4 pts).
   - **Hotspot files present (max 4 pts)**: 1 file >500 LOC (2 pts), >=2 files >500 LOC (4 pts).
   - **Module boundary (max 4 pts)**: Has barrel `index.ts`, `__init__.py`, or dedicated DTO/contract layer (4 pts).
   - **Export & symbol density (max 3 pts)**: High concentration of exported services, controllers, or models (3 pts).
   - **Distinct business domain (max 3 pts)**: Encapsulates a distinct business feature (e.g., auth, billing, robot vacuum, pairing, visits, orders).

3. **Placement Decision**:
   - **Root (`.`)**: ALWAYS created (full comprehensive treatment, 50–150 lines).
   - **Score >= 12**: MUST create dedicated `<dir>/AGENTS.md` (even if nested at depth 3–5).
   - **Score 8–11**: Create if it represents a distinct business domain or high fan-in library.
   - **Score < 8**: Skip (covered by parent directory).

Emit target locations:
```json
AGENTS_LOCATIONS = [
  { "path": ".", "type": "root" },
  { "path": "shared/src/commonMain/.../ui/home", "score": 20, "loc": 3700, "files": 19, "reason": "widest feature VM, 8 injected repos" },
  { "path": "app/Services", "score": 24, "loc": 6200, "files": 14, "reason": "core domain workflows, approval chains" }
]
```

---

### Step 2: Parallel Subtree Exploration & Generation
Do NOT generate all files in a single generic pass. Group target locations into subtrees and dispatch parallel `explore` subagents:

For each targeted directory:
1. **Inspect granular details**:
   - Record exact LOC for every file in the directory.
   - List public methods, actions, models, and state holders.
   - Extract non-obvious conventions (debouncing constants, rate-limit gotchas, serialization quirks).
   - Extract anti-patterns (forbidden imports, documented `ponytail:` stand-ins, line numbers of gotchas).
   - List relevant test files.

2. **Generate Subdirectory `AGENTS.md` (30–80 lines)**:
   Follow the exact OmO high-fidelity format:
   ```markdown
   # {MODULE NAME} — {Short Role} ({Scope/Package})

   **Why this file:** score {SCORE}/30 — {Concise rationale: file count, LOC, key classes, fan-in/fan-out, external consumers}.

   ## STRUCTURE
   ```text
   {dir}/ ({FILE_COUNT} files, {TOTAL_LOC} LOC)
   ├── {File1.ext}       # {LOC} LOC; {Primary classes, models, or state}
   ├── {File2.ext}       # {LOC} LOC; {Role}
   └── ...
   ```

   ## WHERE TO LOOK
   | Task | Location | Notes |
   |---|---|---|
   | {Specific action/domain task} | `{File.ext}` | {Key methods, invariants, behaviors} |

   ## CONVENTIONS
   - **{Load-bearing convention 1}**: {Explanation, e.g. state hoisting, specific qualified imports, debounce timers}.
   - **{Load-bearing convention 2}**: {Constants, retry limits, cache policies}.

   ## ANTI-PATTERNS
   - `{File.ext}:{LINE}` — {Exact gotcha, forbidden pattern, or temporary workaround}.
   - **DO NOT** {explicitly forbidden action in this module}.

   ## TESTS
   - `{Path to unit/feature test}`
   ```

---

### Step 3: Synthesize Root `AGENTS.md`
Synthesize the Root `AGENTS.md` from the subfolder digests. It must provide comprehensive repository navigation without duplicating low-level details:

```markdown
# {PROJECT NAME} — AGENTS.md

<!-- markdownlint-disable MD013 MD032 MD060 -->

## OVERVIEW
{1–2 sentences: what the application does + primary stack + architecture layers}

## STRUCTURE
```text
{root}/
├── {subsystem}/          # {High-level role and link to subsystem/AGENTS.md}
└── ...
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| {Core task} | `{path}/AGENTS.md` or `{path/file.ext}` | {Concrete notes} |

## CODE MAP
| Symbol | Type | Location | Refs | Role |
|--------|------|----------|------|------|
| `{Class/Interface}` | Model/Service/etc. | `{path}` | {Ref count} | {Core responsibility} |

## CONVENTIONS
Repo-wide rules, entry point architecture, cross-cutting concerns, and gotchas (e.g. Groovy vs KTS, dual surface API/Inertia routing, lockfile policies).

## ANTI-PATTERNS (THIS PROJECT)
- **DO NOT** {repo-wide forbidden patterns with rationale}

## COMMANDS
```bash
# Development, build, test, and lint commands
```
```

---

### Step 4: Storage Mode & Pinned Snapshot
1. **Apply Chosen Tracking Mode**:
   - If user chose **Local Only**:
     Add entries to `.git/info/exclude` if not already present (idempotent — re-runs must not stack duplicates):
     ```bash
     grep -qF '# Local agent knowledge base' .git/info/exclude 2>/dev/null || \
       printf '\n# Local agent knowledge base\n**/AGENTS.md\nAGENTS.md\n' >> .git/info/exclude
     ```
   - If user chose **Committed**:
     Ensure `AGENTS.md` is NOT ignored in `.gitignore` or `.git/info/exclude`.

2. **Save Snapshot**:
   Save metadata to `.opencode/init-deep.json`:
   ```json
   {
     "commitSha": "<short-sha>",
     "timestamp": "<iso-timestamp>",
     "mode": "committed | local",
     "fileCount": N,
     "loc": M,
     "locationsCount": K
   }
   ```

---

### Step 5: Summary Report
Present a summary:
- Total source files & LOC analyzed.
- List of all `AGENTS.md` files generated with their scores and line counts.
- Hotspot files documented.
- Storage mode status (Committed vs Local).
