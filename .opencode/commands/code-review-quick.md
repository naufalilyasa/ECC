---
description: Fast single-pass code review using a static checklist (security, quality, best practices, style). Asks for review scope and delegates to the code-reviewer agent with session context.
argument-hint: "[optional scope or base ref: main, HEAD~3, etc.]"
---

# Code Review (Quick) Orchestration

You are the Lead Orchestrator handling the `/code-review-quick` command. Your job is to gather session context and negotiate scope before dispatching the specialized `code-reviewer` subagent.

**User Arguments**: $ARGUMENTS

> **Scope note:** this is the *quick* review lane. For deep two-axis reviews (repo standards + spec conformance), use `@code-review` instead.

## Step 0 — Scope Negotiation

Determine the review scope before dispatching the review:

1. **If `$ARGUMENTS` provides a scope** (e.g. a base ref like `main`, `HEAD~3`, a commit hash, or specific file paths):
   - Use that scope directly.

2. **If `$ARGUMENTS` is empty**:
   - Check environment:
     - Check if Git is available (`[ -d .git ]` or `git rev-parse --is-inside-work-tree` 2>/dev/null).
     - Check `.opencode/markers/code-review-quick.md` for a previous review marker.
   - **If Git is available**:
     - Ask the user using the `question` tool with 4 options computed from repo state:
       1. **Since last `/code-review-quick` run** (Check `.opencode/markers/code-review-quick.md`. If marker exists with commits, mark as Recommended).
       2. **HEAD to working tree (uncommitted changes)** — check `git diff --name-only HEAD`.
       3. **Last N commits** (default 3) — check `git diff --name-only HEAD~3...HEAD`.
       4. **Everything since branch point** — `git merge-base HEAD origin/main`.
     - If the `question` tool is unavailable in this turn, default to Option 2 (uncommitted changes).
   - **If non-Git repository or directory**:
     - Ask the user using the `question` tool with options:
       1. **Since last `/code-review-quick` run** (Files modified since timestamp in `.opencode/markers/code-review-quick.md`; if marker exists, mark as Recommended).
       2. **Recently modified files in this session** (From agent edit history / changed files store).
       3. **Specific directory or file paths** (Prompt user for target paths).
     - If the `question` tool is unavailable in this turn, default to Option 2 (recently modified files).

## Step 1 — Dispatch Code-Reviewer Subagent

Synthesize recent session context (files recently modified, features touched, bugs discussed) and dispatch `code-reviewer`:

```
subagent(agent="code-reviewer", description="Code review: <scope>")
"Review the code changes for quality, security, and maintainability.

## Review Scope
Base/Target: <chosen base ref or file list>
Files to review: <list of files from git diff or session changed files>

## Session Context
<summary of what was just implemented or modified in this session>

## Checklist Categories
1. Security (CRITICAL): Hardcoded secrets, SQLi, XSS, auth gaps, path traversal
2. Code Quality (HIGH): Large functions (>50 lines), deep nesting (>4 levels), missing error handling, console.logs
3. Best Practices (MEDIUM): Mutation patterns, missing tests, accessibility
4. Style (LOW): Naming, formatting, missing types

Report findings with exact file:line citations and severity levels."
```

## Step 2 — Report & Record Marker

Once the `code-reviewer` subagent returns:
1. Present the findings clearly to the user.
2. If the review was successful, record the marker in Markdown format so future runs know the boundary (works in both Git and non-Git repositories):
   - Ensure directory exists: `mkdir -p .opencode/markers`
   - Write `.opencode/markers/code-review-quick.md`:
     ```markdown
     # Code Review Quick Marker

     - **Last Review**: <ISO timestamp, e.g. 2026-11-06T15:30:00Z>
     - **Baseline**: <git commit hash or timestamp snapshot>
     - **Reviewed Files**:
       - <file1>
       - <file2>
     ```
3. If CRITICAL or HIGH issues were found, advise resolving them before merge.
