---
description: Run AgentShield against agent, hook, MCP, permission, and secret surfaces.
argument-hint: "[path] [--format text|json|markdown|html] [--min-severity low|medium|high|critical] [--fix]"
---

# Security Scan Command

**User Arguments**: $ARGUMENTS

Run AgentShield against the current project or a target path, then turn the findings into a prioritized remediation plan.

## Usage

`/security-scan [path] [--format text|json|markdown|html] [--min-severity low|medium|high|critical] [--fix]`

- `path` (optional): defaults to the current project. Use a `.claude/` path, a repo root, or a checked-in template directory.
- `--format`: output format. Use `json` for CI, `markdown` for handoffs, and `html` for standalone review reports.
- `--min-severity`: filters lower-priority findings.
- `--fix`: applies only AgentShield fixes explicitly marked as safe and auto-fixable.

## Deterministic Engine

The engine version is **pinned**. An unpinned `npx` fetch is itself the supply-chain
pattern this command exists to detect, so the scan refuses to improvise when the
engine cannot be resolved.

```bash
AGENTSHIELD_VERSION="1.6.0"
TARGET_PATH="${TARGET_PATH:-.}"

if [[ -x "node_modules/.bin/ecc-agentshield" ]]; then
  node_modules/.bin/ecc-agentshield scan --path "$TARGET_PATH" --format text
elif command -v ecc-agentshield >/dev/null 2>&1; then
  ecc-agentshield scan --path "$TARGET_PATH" --format text
else
  echo "AgentShield engine not found locally." >&2
  echo "Install the pinned version, then re-run:" >&2
  echo "  npm install --save-dev ecc-agentshield@$AGENTSHIELD_VERSION" >&2
  exit 1
fi
```

A one-off pinned fetch is acceptable when the user explicitly opts in:
`npx --yes ecc-agentshield@$AGENTSHIELD_VERSION scan --path "$TARGET_PATH" --format text`.
Report which resolution path was used in the output contract below.

Do not invent findings. Use AgentShield output as the source of truth and separate scanner facts from follow-up judgment.

## Review Checklist

1. Identify active runtime findings first:
   - hardcoded secrets
   - broad permissions
   - executable hooks
   - MCP servers with shell, filesystem, remote transport, or unpinned `npx`
   - agent prompts that handle untrusted content without defenses
2. Separate lower-confidence inventory:
   - docs examples
   - template examples
   - plugin manifests
   - project-local optional settings
3. For each critical or high finding, return:
   - file path
   - severity
   - runtime confidence
   - why it matters
   - exact remediation
   - whether it is safe to auto-fix
4. If `--fix` is requested, state the planned edits before applying fixes.
5. Re-run the scan after fixes and report the before/after score.

## Output Contract

Return:

1. Security grade and score.
2. Counts by severity and runtime confidence.
3. Critical/high findings with exact paths.
4. Lower-confidence findings grouped separately.
5. A remediation order.
6. Commands run and whether the scan was local, CI, or npx-backed.

## Arguments

$ARGUMENTS:
- optional target path
- optional AgentShield flags

## CI Pattern

Use the pinned version in GitHub Actions for enforced gates (an unpinned `@v1`
tag is a mutable ref):

```yaml
- uses: affaan-m/agentshield@v1.6.0
  with:
    path: "."
    min-severity: "medium"
    fail-on-findings: true
```

## Links

- Skill: `skills/security-scan/SKILL.md`
- Agent (active in this harness): `.opencode/prompts/agents/security-reviewer.txt` — registered in `.opencode/opencode.json` with the PoC Gate prompt.
- Agent (canonical ECC reference): `agents/security-reviewer.md` — the upstream definition; the OpenCode prompt above is a tuned superset. When editing behavior, change the active prompt and note the delta here.
- Scanner: <https://github.com/affaan-m/agentshield>
