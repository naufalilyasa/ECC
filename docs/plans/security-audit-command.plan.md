# Implementation Plan: `/security-audit` Command — Cloudflare 6-Phase Harness + Docker Lima Sandbox

## Overview

A dedicated OpenCode `/security-audit` command that replicates the Cloudflare
`security-audit-skill` vulnerability-discovery harness: reconnaissance →
coverage-led hunting → adversarial candidate validation → structured
`findings.json` output → independent record verification → target-neutral
reporting. PoC exploit code runs in the local Lima VM (`ga-proof`, nerdctl
2.4.1) inside an unprivileged, no-network container, behind a
confirmation-first gate with an optional `--auto-exec` bypass.

This is intentionally **distinct** from the two existing commands:

| Command | Scope | Output |
|---|---|---|
| `/security` | Daily diff review of recently changed code (session-scoped) | Inline verdict from `security-reviewer` |
| `/security-scan` | AgentShield scan of agent/hook/MCP/permission/secret **config** surfaces | Scanner grade + remediation plan |
| **`/security-audit`** (new) | Full codebase penetration test / vulnerability discovery | `findings.json` + 3 report artifacts + coverage ledger |

## Requirements

### Functional
- R1. Full 6-phase audit, in order, per the Cloudflare harness:
  1. **Reconnaissance** — `explore` subagents map architecture, trust boundaries, entry surfaces, local-build visibility; parent writes `architecture.md` + `coverage-ledger.json`.
  2. **Coverage-led hunting** — isolated `security-hunter` subagents assigned per ledger unit, per attack class; mandatory post-wave coverage-critic passes.
  3. **Candidate validation** — a **fresh** `security-verifier` subagent (never the hunter that found it) tries to disprove each unique candidate.
  4. **Structured output** — parent writes `findings.json` with `confirmed` / `needs_validation` / `rejected` verdicts; validated by `report-schema.json` + `validate-findings.cjs`.
  5. **Independent record verification** — fresh verifier agents re-verify final source claims; material replacements get another independent verifier.
  6. **Final reporting** — parent derives `REPORT.md`, `FINDINGS-DETAIL.md`, `NEEDS-VALIDATION.md` from verified records + ledger.
- R2. Terminal states only: (a) all Phase 6 artifacts written and both validators pass, or (b) `run_status: "incomplete"` recorded with its exact reason and disclosed in the report. Never stop mid-phase.
- R3. Verdict taxonomy preserved: `confirmed` (complete source trace + bounded observed result) / `needs_validation` (exact unresolved fact, **no severity**) / `rejected` (disproved candidate).
- R4. Run profiles `quick` / `standard` / `deep` + scoped runs, and an agent-invocation budget gate (reserve critics + verifiers before hunters).
- R5. Prior-run additivity: read prior `coverage-ledger.json` / `findings.json` under the same repo root; carry forward only unchanged-source `confirmed` records; changed source forces revalidation.
- R6. Lima `ga-proof` PoC execution, **confirmation-first**: by default PoCs are proposed (command, input, sandbox limits recorded) but **not** executed; the user approves each execution. `--auto-exec` executes approved-path PoCs without per-PoC confirmation.
- R7. If any sandbox control is unavailable (VM down, network isolation impossible, resource limits unenforceable), the run **fails closed**: the candidate stays `needs_validation` with the exact missing capability as the blocker. No target code runs on the host.
- R8. Distinct entry points: `subagent(agent="explore")` for recon, `subagent(agent="security-hunter")` for hunting, `subagent(agent="security-verifier")` for validation/verification/critic waves.

### Non-functional
- R9. All new files live under `.opencode/` (OpenCode-local harness surface). Nothing enters the ECC npm publish surface or the `skills/` canonical surface.
- R10. Vendored Cloudflare material stays byte-close to upstream (pinned commit) with MIT attribution, so future re-syncs are diffs, not rewrites.
- R11. Zero new runtime dependencies. Validators are the upstream zero-dependency `.cjs` files; the sandbox runner is plain `bash` + `limactl` + `nerdctl`.

## Architecture Changes

### New file layout (all under `.opencode/`, mirrored to `~/.config/opencode/` where noted)

```
.opencode/
├── commands/
│   └── security-audit.md                  # Lead Orchestrator command (6 phases, flags)
├── prompts/
│   ├── agents/
│   │   ├── security-hunter.txt            # NEW subagent prompt (adversarial hunter)
│   │   └── security-verifier.txt          # NEW subagent prompt (adversarial verifier + critic)
│   └── security-audit/                    # vendored Cloudflare knowledge (MIT, pinned)
│       ├── RECONNAISSANCE.md
│       ├── HUNTING.md
│       ├── ATTACK-CLASSES.md
│       ├── AI-AND-LLM.md
│       ├── CLIENT-SIDE.md
│       ├── CLOUD-AND-DEPLOYMENT.md
│       ├── DATA-ISOLATION-AND-LIFECYCLE.md
│       ├── DESKTOP-MOBILE-AND-LOCAL-IPC.md
│       ├── MEMORY-SAFETY-AND-BINARY.md
│       ├── PROTOCOLS-RPC-AND-MESSAGING.md
│       ├── RESOURCE-EXHAUSTION-AND-AVAILABILITY.md
│       ├── SUPPLY-CHAIN-AND-RELEASE.md
│       ├── WEB-PROTOCOL-AND-AUTH.md
│       ├── VALIDATION-AND-REPORTING.md
│       └── LICENSE-CLOUDFLARE.txt
└── scripts/
    └── security-audit/
        ├── lima-sandbox-runner.sh         # PoC staging + unprivileged nerdctl execution
        ├── report-schema.json
        ├── validate-findings.cjs
        ├── validate-coverage-ledger.cjs
        ├── validate-findings.test.cjs
        ├── validate-coverage-ledger.test.cjs
        └── self-check.sh                  # assert-based runner smoke test
```

### Config registrations — `.opencode/opencode.json` AND `~/.config/opencode/opencode.json`

```jsonc
"agent": {
  // ...existing...
  "security-hunter": {
    "description": "Adversarial vulnerability hunter for the /security-audit 6-phase harness. Reads source and executes PoCs only inside the Lima sandbox. Returns exactly one structured JSON result per assigned coverage unit.",
    "mode": "subagent",
    "prompt": "{file:prompts/agents/security-hunter.txt}",
    "tools": { "read": true, "grep": true, "glob": true, "bash": true, "write": false, "edit": false }
  },
  "security-verifier": {
    "description": "Independent adversarial verifier for /security-audit. Tries to DISPROVE candidates produced by other hunters. Never the same agent instance that produced the candidate. Also runs coverage-critic passes.",
    "mode": "subagent",
    "prompt": "{file:prompts/agents/security-verifier.txt}",
    "tools": { "read": true, "grep": true, "glob": true, "bash": true, "write": false, "edit": false }
  }
},
"command": {
  // ...existing...
  "security-audit": {
    "description": "Full codebase penetration test / vulnerability discovery (Cloudflare 6-phase harness with Lima sandbox PoC execution). Distinct from /security (diff review) and /security-scan (config scan).",
    "template": "{file:commands/security-audit.md}\n\n$ARGUMENTS"
  }
}
```

Tool-scope note: hunters/verifiers get `bash` (needed to stage PoCs into the sandbox and call the runner) but **no** `write`/`edit` — the parent owns every shared file, matching Cloudflare's write-isolation rule. Agents write only inside their own `<output-dir>/agents/<agent-id>/scratch/`.

### Platform-terminology mapping (command file owns this table)

| Cloudflare skill term | OpenCode equivalent |
|---|---|
| Parent | The `build` agent executing the `/security-audit` command template |
| Task tool | OpenCode `subagent(...)` dispatch |
| `research` agent | `subagent(agent="explore", ...)` |
| `general` agent | `subagent(agent="security-hunter", ...)` / `subagent(agent="security-verifier", ...)` |
| OS-enforced sandbox | Lima VM `ga-proof` + unprivileged `nerdctl` container (no network, RO target, scratch-only writes, resource limits) |

Vendored docs stay near-verbatim; the mapping table above appears in `commands/security-audit.md` and in both agent prompts, so no invasive rewording of upstream text is needed.

### Run artifacts (per run, default `~/security-audit-runs/<repo-name>/run-<N>`)

Parent-owned: `run-metadata.json`, `architecture.md`, `coverage-ledger.json`, `findings.json`, `REPORT.md`, `FINDINGS-DETAIL.md`, `NEEDS-VALIDATION.md`.
Per-agent: `<output-dir>/agents/<agent-id>/{scratch,artifacts}/` — agents write only `scratch/`; `artifacts/` is parent-promoted.

### Lima sandbox contract (`lima-sandbox-runner.sh`)

```
Usage: lima-sandbox-runner.sh --run-dir <dir> --script <rel-path> [--auto-exec]
       [--cpu 1] [--memory 512m] [--pids 64] [--wall 120] [--stage <paths...>]
```

1. **Preflight (fail closed)** — `limactl list ga-proof` must report `Running` (attempt one `limactl start ga-proof`, else abort); `nerdctl` present in VM; sandbox image present in VM (pull once into the VM's own image store during setup, never at run time).
2. **Stage** — copy only the files the PoC declares (target files + PoC script) into the VM at `/tmp/secaudit-<runid>/scratch/` via `limactl shell ... rsync/scp` or `tar | limactl shell ... tar -x`. **Never** expose `/mnt/guardian-angel` (the live host mount) or `$HOME` to the container: the staged copy is the target, and a build that must write beside source writes only inside its `scratch/`.
3. **Execute** — unprivileged, non-root:
   `nerdctl run --network none --read-only --cpus <cpu> --memory <mem> --pids-limit <pids>`
   `  --user 65532:65532 --tmpfs /tmp:rw,size=64m -v <staged>:/target:ro -w /target`
   `  -- <script>` wrapped in the VM's `timeout <wall>`; environment is `env -i` plus an explicit allowlist (`PATH`, `HOME=/tmp/secaudit-<runid>/scratch`, `NODE_OPTIONS=--disable-warning`, safe values only).
4. **Capture** — stdout/stderr/exit code + wall time written to `<run-dir>/sandbox/<poc-id>/result.json` on the host after the container and all its processes terminate.
5. **Promote** — only predeclared, allowlisted scratch-relative files under per-file and cumulative byte limits are copied out by trusted parent-side code (no symlinks, FIFOs, dirs; regular files, link count 1). Anything else is discarded.
6. **Confirmation gate** — without `--auto-exec`, the script prints the exact command, input, limits, and staged file list, then exits `75` (pending-approval) unless an approval token file exists for that PoC id; the orchestrator asks the user and writes the token, then re-invokes.

## Implementation Steps

### Phase A: Vendor Cloudflare knowledge + validators (no ECC surface impact)
1. **Vendor the harness knowledge** (Files: `.opencode/prompts/security-audit/*.md`, `LICENSE-CLOUDFLARE.txt`)
   - Action: Pin upstream commit SHA of `cloudflare/security-audit-skill`; download the 14 companion `.md` files + `report-schema.json` + 4 `.cjs` validators; record SHA + source URL in `LICENSE-CLOUDFLARE.txt` alongside the MIT notice. Keep files verbatim **except** a one-line header comment in each `.md` stating it is vendored from the pinned commit.
   - Why: R10 — byte-close vendoring keeps future re-syncs as diffs and preserves the proven contract text (hunter prompt parts, promotion procedure, critic waves).
   - Dependencies: None.
   - Risk: Low. Drift from upstream is mitigated by pinning.

2. **Vendor validators into the script dir** (Files: `.opencode/scripts/security-audit/{report-schema.json, validate-findings.cjs, validate-coverage-ledger.cjs, validate-findings.test.cjs, validate-coverage-ledger.test.cjs}`)
   - Action: Copy verbatim from the same pinned commit. Run `node validate-findings.test.cjs` and `node validate-coverage-ledger.test.cjs` to confirm green on this host's Node.
   - Why: Zero-dependency contract enforcement for Phase 4/5 (R1, R2).
   - Dependencies: Step A1 (same commit).
   - Risk: Low.

### Phase B: Register the two new subagent types + command (both configs)
3. **Register agents + command** (Files: `.opencode/opencode.json`, `~/.config/opencode/opencode.json`)
   - Action: Add the `security-hunter` and `security-verifier` agent entries (tool scope per Architecture Changes) and the `security-audit` command entry, exactly as specified above, to both configs. Back up each JSON first (the dirs already carry `.bak-*` convention). Validate both files with `python3 -m json.tool` and confirm `opencode` lists the command.
   - Why: R8 — adversarial independence requires distinct agent identities and prompts, and the command must be invocable in both workspace and global scope.
   - Dependencies: Steps B4/B5 (prompt files) should exist first so `{file:...}` resolves.
   - Risk: Medium — JSON corruption in a live harness config. Mitigation: backup + `json.tool` + listing check.

4. **Write `security-hunter.txt`** (File: `.opencode/prompts/agents/security-hunter.txt`, mirror to `~/.config/opencode/prompts/agents/security-hunter.txt`)
   - Action: Prompt containing, in order: role preamble (find source-grounded invariant failures in assigned units; return exactly one JSON result); the platform-terminology mapping; the nine required hunter-prompt parts from HUNTING.md (architecture verbatim / assigned coverage IDs / selected attack-class blocks verbatim / explicit exclusions with reasons / core hunting method / promotion procedure block / validation rules / carried-prior exclusions / scratch paths + structured-result contract with the `confirmed` and `needs_validation` schema branches); the sandbox execution rules and confirmation gate (propose-only by default; run PoCs only through `lima-sandbox-runner.sh`; never on the host).
   - Why: Isolated, structured, non-prose-only hunting results (R1, anti-pattern #7).
   - Dependencies: A1 (HUNTING.md, ATTACK-CLASSES.md, report-schema.json).
   - Risk: Low.

5. **Write `security-verifier.txt`** (File: `.opencode/prompts/agents/security-verifier.txt`, mirror to global)
   - Action: Prompt for the candidate-verifier (from VALIDATION-AND-REPORTING.md Phase 3): "You did not write this candidate. Try to refute it from repository source and bounded local evidence."; re-read every cited line; independently reproduce the minimum observed result in the sandbox only; downgrade to `rejected` if refuted, keep `needs_validation` with the exact unresolved fact if blocked; plus the coverage-critic variant prompt (HUNTING.md critic waves) for gap-finding assignments.
   - Why: R1 Phase 3/5 independence; severity discipline (R3).
   - Dependencies: A1.
   - Risk: Low.

### Phase C: Write the Lead Orchestrator command
6. **Write `security-audit.md`** (File: `.opencode/commands/security-audit.md`, mirror to `~/.config/opencode/commands/security-audit.md`)
   - Action: Frontmatter `description` (explicitly distinguishing `/security` and `/security-scan`) + `argument-hint: "[target-path] [--profile quick|standard|deep] [--budget N] [--auto-exec] [--scope paths...] [--output-dir <dir>]"`. Body = Lead Orchestrator script:
     - **Setup block**: resolve target, repo name, source ref (`git rev-parse HEAD` + dirty check), output dir (`~/security-audit-runs/<repo>/run-<N>`, next unused N), prior runs scan (R5), `run-metadata.json` with `execution_policy: "sandboxed-source-and-local-only"`.
     - **Budget gate** before any dispatch (reserve 4 recon + critics + verifier reserve; `budget_cannot_fund_reconnaissance_and_reserves` → no agents launched, incomplete run).
     - **Phase 1**: dispatch 4 `explore` subagents in parallel (1a product/stack, 1b principals/authority, 1c entry surfaces/sinks, 1d local execution/deployment visibility) using the verbatim RECONNAISSANCE.md agent prompts; parent synthesizes `architecture.md` + seeds `coverage-ledger.json`; run `node .opencode/scripts/security-audit/validate-coverage-ledger.cjs`.
     - **Phase 2**: hunter waves — assign `planned` units to `security-hunter` subagents (parallel), choosing attack-class blocks from ATTACK-CLASSES.md + relevant domain companions for the target's stack; after each wave a `security-verifier` critic pass; update ledger; re-run the ledger validator after every update.
     - **Phase 3**: consolidate candidates by fingerprint + root cause; one fresh `security-verifier` per candidate (never the hunter that produced it); PoC confirmation gate here (R6) — collect PoC proposals, ask the user, then execute via the sandbox runner.
     - **Phase 4**: write `findings.json`; run `validate-findings.cjs` + `validate-coverage-ledger.cjs`.
     - **Phase 5**: fresh `security-verifier` agents verify final source claims; material replacements get another independent verifier; re-run validators after every replacement.
     - **Phase 6**: derive `REPORT.md`, `FINDINGS-DETAIL.md`, `NEEDS-VALIDATION.md` from records + ledger; no live-probe instructions; state profile, scope, budget, prior-run carry-forward, and any incomplete reason.
     - **Terminal-state enforcement** (R2) and the operating-modes note (guidance mode for security questions; full audit mode for explicit audit/pen-test requests).
   - Why: This is the orchestration brain; mirrors the proven `security.md` / `deep-research.md` Lead-Orchestrator style already in this harness.
   - Dependencies: A1, B3, B4, B5, D7.
   - Risk: Medium — prompt-size pressure (architecture.md + attack blocks are large). Mitigation: select only the companion blocks the target's stack needs; `quick` profile coarsens units; document the estimated prompt budget in the command.

### Phase D: Lima sandbox runner
7. **Write `lima-sandbox-runner.sh`** (File: `.opencode/scripts/security-audit/lima-sandbox-runner.sh`, do NOT mirror — host-local; the global config can reference the workspace path or carry its own copy under `~/.config/opencode/scripts/`)
   - Action: Implement the 6-part contract above (preflight → stage → execute → capture → promote → confirmation gate). Use `set -euo pipefail`, `limactl shell ga-proof -- nerdctl ...`, `timeout` for the wall clock, and `env -i` for environment sanitization. Exit codes: `0` success; `75` pending user approval; `76` sandbox control unavailable (caller records `needs_validation` blocker); `77` promotion rejected. Keep total under ~250 lines.
   - Why: R6/R7 — the only sanctioned path for target-controlled execution; keeps PoCs off the host and off the live `/mnt/guardian-angel` mount.
   - Dependencies: `ga-proof` VM (verified running, nerdctl 2.4.1, Ubuntu 6.8 aarch64).
   - Risk: High — this is the safety-critical component. Mitigations: defense in depth (no network, read-only target, scratch-only writes, `--user 65532`, pids/memory/cpu/wall limits), fail-closed exit codes, and the self-check in Step E9.

8. **VM provisioning note** (no new file)
   - Action: Confirm once that `ga-proof` has a minimal sandbox image (e.g. pull `ubuntu:24.04` into the VM image store) and that the host→VM copy path (`limactl shell ... tar`) works for a 10 MB payload. Record the image reference in `run-metadata.json` when used.
   - Why: R7 — image absence at run time must be a preflight failure, not a mid-run surprise.
   - Dependencies: D7.
   - Risk: Low.

### Phase E: Testing & verification
9. **Runner self-check** (File: `.opencode/scripts/security-audit/self-check.sh`)
   - Action: assert-based checks, no framework: (a) a `true` PoC returns 0 and its stdout is captured; (b) a PoC that tries to write outside `scratch/` fails; (c) a PoC that attempts an outbound connection fails/times out; (d) without `--auto-exec` the runner exits 75; (e) promotion rejects a symlinked scratch entry. Print PASS/FAIL per check.
   - Why: Non-trivial safety-critical logic leaves one runnable check behind (repo convention).
   - Dependencies: D7, D8.
   - Risk: Low.

10. **End-to-end fixture audit**
    - Action: Build a ~20-line throwaway fixture repo with one planted vulnerability (e.g. `eval(req.query.x)`) plus one false positive (defense-in-depth gap). Run `/security-audit --profile quick --output-dir /tmp/secaudit-fixture` and verify: 8 artifacts exist; validators pass; the planted vuln lands in `confirmed` with a full trace; the false positive lands in `rejected` or `needs_validation`; the verifier agent differs from the hunter agent for every candidate; no PoC executed on the host (only via the runner, with confirmation).
    - Why: R1–R3, R6 exercised together.
    - Dependencies: C6, D7, E9.
    - Risk: Medium — agent nondeterminism. Mitigation: assert on artifact structure + verdict taxonomy, not on prose.

11. **Registration & regression checks**
    - Action: `python3 -m json.tool` both `opencode.json` files; confirm `opencode` lists `/security-audit` and the two new agents; run `npm test` in the ECC repo to confirm the `.opencode/` additions trip no publish-surface or manifest test (all new paths are under `.opencode/`, outside `files`/`bin`).
    - Why: R9 — no ECC contribution-surface churn.
    - Dependencies: B3.
    - Risk: Low.

## Testing Strategy

- **Unit / contract**: run the two upstream `.test.cjs` validator suites (Step A2) — they cover schema branches, severity rules, and ledger transitions.
- **Sandbox safety**: `self-check.sh` (Step E9) asserts the five failure-mode controls (write-isolation, no-network, confirmation gate, promotion rejection, capture).
- **End-to-end**: fixture audit in `quick` profile (Step E10), then one `standard`-profile run against `guardian-angel` (the project already mounted at `/mnt/guardian-angel`) as the real-world smoke test, confirming prior-run additivity on a second invocation (R5).
- **Registration**: JSON validity + command/agent listing + `npm test` (Step E11).
- **Manual gates**: confirm the command's trigger surface does not overlap `/security` (diff review) or `/security-scan` (config scan) descriptions.

## Risks & Mitigations

- **Risk: PoC escape / host impact via the live mount.** Mitigation: staged read-only copy only; `--network none`; read-only `/target`; scratch-only writes; unprivileged UID; pids/memory/cpu/wall limits; never pass descriptors, `$HOME`, credentials, or `/mnt/guardian-angel` into the container; promotion is parent-side and path-confined (R7, D7, E9).
- **Risk: Confirmation gate bypassed by accident.** Mitigation: default is propose-only; `--auto-exec` is an explicit flag; the runner independently enforces the gate (exit 75) regardless of what the orchestrator claims; approval tokens are per-PoC-id.
- **Risk: Upstream drift / license compliance.** Mitigation: pinned commit SHA + MIT notice + vendored-header comments; re-sync procedure documented (re-download from the pinned-or-newer commit and diff).
- **Risk: Subagent prompt-size limits.** Mitigation: send only the companion blocks selected for the target stack, verbatim; `quick` profile coarsens units; architecture.md is summarized once, not re-sent per agent beyond need.
- **Risk: Cost overrun from many subagents.** Mitigation: the Cloudflare budget gate is adopted wholesale — reserve critics + verifiers before any hunter; `run_status: "incomplete"` with exact reason instead of silent thinning (R4).
- **Risk: Workspace/global drift (two copies of command + prompts).** Mitigation: workspace files are the single source; a one-line `cp` sync step is documented in the command's own header; the runner stays host-local and is referenced by absolute path or copied to `~/.config/opencode/scripts/`.
- **Risk: Verifier not truly independent (same underlying model).** Mitigation: distinct agent identity + distinct prompt that never receives the hunter's conclusion, only the candidate; carried prior confirmations still walk the current verification path.

## Success Criteria

- [ ] `/security-audit` is registered and listed in both `.opencode/opencode.json` and `~/.config/opencode/opencode.json`, and both files parse.
- [ ] `security-hunter` and `security-verifier` subagent types are registered in both configs with prompts resolving on disk.
- [ ] A `quick`-profile run produces all 8 artifacts; `validate-findings.cjs` and `validate-coverage-ledger.cjs` both pass.
- [ ] In the fixture run, the planted vulnerability is `confirmed` with a complete trace, and the defense-in-depth false positive is `rejected`/`needs_validation` — never `confirmed`.
- [ ] For every candidate, the verifying agent differs from the hunting agent (verdicts show distinct agent ids).
- [ ] No PoC executes on the host; without `--auto-exec` the runner exits 75 until the user approves; with the sandbox unavailable, candidates become `needs_validation` with the exact missing capability.
- [ ] A second run against the same repo carries forward unchanged-source `confirmed` records and revalidates changed source (R5).
- [ ] `npm test` in the ECC repo still passes; no file outside `.opencode/` is modified.
- [ ] The command description and trigger surface are provably distinct from `/security` and `/security-scan`.
