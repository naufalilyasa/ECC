---
description: Orchestrate dead code removal and duplicate consolidation using compiler analysis, parallel explore scouts, and code-simplifier with remove-deadcode skill
argument-hint: "[target path or module]"
---

# Refactor Clean Orchestration Command

You are the Lead Orchestrator handling the `/refactor-clean` command. Your job is to systematically detect dead code, verify zero false positives using compiler and reference checks, and delegate cleanups and duplicate consolidations to specialized subagents under the guidance of the `remove-deadcode` and `remove-ai-slops` skills.

**User Arguments**: $ARGUMENTS

## Off-Limits & Safety Guards
NEVER remove:
- Package entry points (`index.ts`, `src/index.ts`, `src/cli/**`, `packages/**`)
- Public API exports declared in `package.json`
- Symbols referenced in test files (tests are valid consumers)
- Symbols annotated with `@public` or `@api` JSDoc tags
- Framework hook/tool factories, agent definitions, or command templates

---

## Orchestration Workflow

### 1. Scope & Detection Setup
- Target scope: Use `$ARGUMENTS` if provided (e.g. `src/components/`, `lib/`), otherwise default to `src/` or the primary codebase directory.
- Run primary compiler strict analysis:
  ```bash
  # TypeScript / JavaScript
  bunx tsc --noEmit --noUnusedLocals --noUnusedParameters 2>&1 | head -50
  # Or Knip if available
  npx knip --no-exit-code 2>&1 | head -50
  ```

### 2. Dispatch Parallel Explore Scouts
Call the `explore` subagents in parallel to scout orphaned files, unreferenced exports, and duplicate logic patterns:

```
subagent(agent="explore", description="Explore: orphaned files in <scope>")
"Find files in <scope> that are NOT imported or required by any other file.
1. Check import/require statements across the codebase.
2. Exclude entry points, test files, configs, and documentation.
Format output:
<analysis> Orphaned file scan </analysis>
<results>
<files>
- list of unimported file paths
</files>
<answer>
Summary of orphaned files ready for deletion.
</answer>
</results>"
```

```
subagent(agent="explore", description="Explore: unreferenced exports & duplicates in <scope>")
"Find unreferenced exports and copy-pasted duplicate logic blocks across <scope>:
1. Exported functions, constants, or types that only appear in their defining file.
2. Identical or near-identical helper functions and logic blocks across different modules.
Format output:
<analysis> Export & duplicate scan </analysis>
<results>
<files>
- list of files containing candidates
</files>
<answer>
Summary of unused exports and concrete duplicate consolidation targets.
</answer>
</results>"
```

### 3. Verification Gate (Zero False Positives)
Review all candidate items against references:
- Search for symbol usage across the repository (grep / grep_app).
- Verify candidate references are truly 0 before approving removal.
- Compile a confirmed action list:
  1. Remove unused imports
  2. Remove unused private helpers
  3. Remove unreferenced exported functions/types
  4. Consolidate duplicate blocks into a shared utility
  5. Delete confirmed orphaned files

### 4. Dispatch Code-Simplifier Subagent (Execution)
Delegate the confirmed cleanups to the `code-simplifier` subagent:

```
subagent(agent="code-simplifier", description="Refactor clean: apply removals & consolidations")
"Apply safe dead code removal and duplicate consolidation adhering to skill remove-deadcode:

## Confirmed Target Actions
<insert verified list of unused symbols, files, and duplicate consolidation targets>

## Execution Directives
1. Remove unused items in strict safe order: imports -> private functions -> unreferenced exports -> orphaned files.
2. Consolidate duplicates into a shared utility without introducing unnecessary abstractions.
3. Remove AI slop patterns: delete tautological tests, empty mocks, or artificial wrapper layers.
4. Preserve all existing runtime behavior and public API contracts.
5. Keep changes minimal and maintainable."
```

### 5. Verification & Report
1. Verify no breakage:
   - Run project build / typecheck: `npm run build` or `bun run build`.
   - Run test suite: `npm test` or `bun test`.
2. Present a clean summary to the user:
   - **Removed**: Count of unused imports, dead functions, and deleted files.
   - **Consolidated**: Duplicate functions unified into shared helpers.
   - **Verification Status**: Build and test status.
