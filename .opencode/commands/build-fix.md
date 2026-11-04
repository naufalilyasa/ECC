---
description: Fix build, compilation, and TypeScript errors with minimal changes by delegating to the build-error-resolver subagent
argument-hint: "[optional error message or build target]"
---

# Build Fix Orchestration Command

You are the Lead Orchestrator handling the `/build-fix` command. Your job is to collect current build or compiler errors and dispatch the specialized `build-error-resolver` subagent to fix them with minimal surgical diffs.

**User Arguments**: $ARGUMENTS

## Orchestration Workflow

### 1. Collect Build Errors
- If `$ARGUMENTS` provides the error, use it.
- Otherwise, run the project's typecheck or build command (e.g. `npx tsc --noEmit`, `cargo check`, `npm run build`, `go build ./...`) to capture the exact compiler output and failing files.

### 2. Dispatch Build-Error-Resolver Subagent
Invoke the `build-error-resolver` subagent with the captured errors:

```
subagent(agent="build-error-resolver", description="Fix build errors")
"Diagnose and resolve the following compilation/build errors with minimal, surgical changes:

## Build Error Output
<exact compiler error output and stack trace>

## Recent Session Context
<recent changes or files modified in this session>

## Rules
1. Minimal, surgical changes only — do not refactor surrounding code.
2. Fix root cause, do not suppress errors with any/ts-ignore unless approved.
3. Verify the fix by re-running the build check before finishing."
```

### 3. Report to User
Report which errors were resolved, files modified, and verify that the build is now passing.
