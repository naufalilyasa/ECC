---
description: Update documentation and codemaps by dispatching explore to analyze codebase evolution since the last commit baseline, then doc-updater to stamp verified commit markers
argument-hint: "[optional specific doc to update]"
---

# Update Docs Orchestration Command

You are the Lead Orchestrator handling the `/update-docs` command. Your job is to determine the documentation sync baseline, dispatch the `explore` subagent to analyze the codebase evolution since that baseline, and delegate to the `doc-updater` subagent to refresh documentation with verified commit markers.

**User Arguments**: $ARGUMENTS

## Orchestration Workflow

### 1. Determine Baseline & Target Scope
1. **Identify Target Document(s)**:
   - If `$ARGUMENTS` specifies a file, target that.
   - Otherwise, default to standard project docs: `README.md`, `docs/CODEMAPS/`, and `docs/GUIDES/`.
2. **Find the Last Documented Commit Baseline**:
   - Inspect the target doc header for an existing marker: `**Last Updated:** ... · Commit: `([a-f0-9]+)`` or check `.git/docs-sync-base`.
   - If found: use `<last-commit-hash>` as baseline.
   - If no marker found in doc: find when the doc was last committed via `git log -1 --format="%h" -- <target-doc>`.
   - If still no prior commit (new repo/file): use the initial commit `git rev-list --max-parents=0 HEAD` or `HEAD~1`.
3. **Capture Current Git Position**:
   - Current commit hash: `CURRENT_COMMIT=$(git rev-parse --short HEAD)`
   - Current branch: `CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)`
   - Current date: `CURRENT_DATE=$(date +%Y-%m-%d)`

### 2. Dispatch Explore Subagent (Codebase Evolution Analysis)
Call the `explore` subagent to scout what changed between `<baseline-commit>` and current `HEAD` (including working tree changes):

```
subagent(agent="explore", description="Explore: codebase updates since <baseline-commit>")
"Analyze code updates and architectural changes between <baseline-commit> and HEAD (plus working tree):
1. Files changed, added, or removed (git diff <baseline-commit>...HEAD --stat).
2. Key API route changes, new exported functions, or modified schemas.
3. Architecture shifts, new dependencies, or updated CLI commands.
Format your output with:
<analysis> Summary of what changed in the codebase since <baseline-commit> </analysis>
<results>
<files>
- list of most impactful modified source files
</files>
<answer>
Concrete delta summary: new modules, modified interfaces, removed exports.
</answer>
</results>"
```

### 3. Dispatch Doc-Updater Subagent (With Explore Insights + Commit Marker)
Pass the exploration delta report to `doc-updater` along with the exact commit metadata to stamp:

```
subagent(agent="doc-updater", description="Update docs at <CURRENT_COMMIT>")
"Update documentation to reflect recent codebase changes:

## Baseline & Commit Marker (MANDATORY)
- Target Docs: <list of doc files>
- Header Marker: **Last Updated:** <CURRENT_DATE> · Commit: `<CURRENT_COMMIT>` (ref: `<CURRENT_BRANCH>`)
- Baseline Compared: <baseline-commit> -> <CURRENT_COMMIT>

## Codebase Evolution Report (from explore)
<paste/summarize the results from the explore subagent pass>

## Documentation Directives
1. Stamp the exact visible header marker: `**Last Updated:** <CURRENT_DATE> · Commit: `<CURRENT_COMMIT>` (ref: `<CURRENT_BRANCH>`)` at the top of updated docs.
2. Update README.md, codemaps, or guides to match the code changes discovered by explore.
3. Prose Quality (humanizer + humanizer-lint): rewrite narrative prose with the `humanizer` skill, then gate it through the deterministic linter and resolve every violation:
   `echo "<draft_prose>" | node ~/.config/opencode/skills/humanizer-lint/scripts/analyze.mjs --stdin --lang auto --json`
   Exempt ASCII diagrams, module tables, schema definitions, and code blocks — structured data, not prose.
4. Technical text stays English: write canonical technical doc prose in English and never translate code identifiers, CLI commands, flags, file paths, API names, error strings, or config keys. `docs/<lang>/` translations are out of scope.
5. Keep technical codemaps structured, tabular, and concise."
```

### 4. Record Sync Marker & Report
1. After successful update, record the sync marker locally:
   ```bash
   echo "$CURRENT_COMMIT $(date +%s)" > .git/docs-sync-base
   ```
2. Report to user:
   - Updated documents list.
   - Stamped commit reference (`<CURRENT_COMMIT>` on `<CURRENT_BRANCH>`).
   - Summary of codebase changes documented.
