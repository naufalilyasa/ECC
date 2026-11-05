---
description: Create, verify, or list workflow checkpoints after running verification checks.
---

# Checkpoint Command

Create or verify a checkpoint in your workflow.

## Usage

`/checkpoint [create|verify|list] [name]`

## Create Checkpoint

When creating a checkpoint:

1. Run `/verify quick` to ensure current state is clean
2. Append the checkpoint to the markdown record `.claude/checkpoints.md`
   (create it with a header row if it does not exist yet):

```bash
mkdir -p .claude
[ -f .claude/checkpoints.md ] || printf '| Timestamp | Name | Tests | Coverage | Build |\n|---|---|---|---|---|\n' >> .claude/checkpoints.md
echo "| $(date +%Y-%m-%d-%H:%M) | $CHECKPOINT_NAME | X/Y passed | XX% | PASS/FAIL |" >> .claude/checkpoints.md
```

3. Report checkpoint created

## Verify Checkpoint

When verifying against a checkpoint:

1. Read the checkpoint row from `.claude/checkpoints.md`
2. Compare current state to the recorded checkpoint:
   - Files changed since the checkpoint (from your own edit history since that
     timestamp — no git required)
   - Test pass rate now vs then
   - Coverage now vs then

3. Report:
```
CHECKPOINT COMPARISON: $NAME
============================
Files changed: X
Tests: +Y passed / -Z failed
Coverage: +X% / -Y%
Build: [PASS/FAIL]
```

## List Checkpoints

Show all checkpoints from `.claude/checkpoints.md` with:
- Name
- Timestamp
- Recorded tests / coverage / build
- Status (current, superseded)

## Workflow

Typical checkpoint flow:

```
[Start] --> /checkpoint create "feature-start"
   |
[Implement] --> /checkpoint create "core-done"
   |
[Test] --> /checkpoint verify "core-done"
   |
[Refactor] --> /checkpoint create "refactor-done"
   |
[PR] --> /checkpoint verify "feature-start"
```

## Arguments

$ARGUMENTS:
- `create <name>` - Create named checkpoint
- `verify <name>` - Verify against named checkpoint
- `list` - Show all checkpoints
- `clear` - Remove old checkpoints (keeps last 5)
