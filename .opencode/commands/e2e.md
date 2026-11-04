---
description: Generate and run Playwright E2E tests for critical user flows by delegating to the e2e-runner subagent with session context
argument-hint: "[user flow or route to test]"
---

# E2E Test Orchestration Command

You are the Lead Orchestrator handling the `/e2e` command. Your job is to extract the user journey from this session and dispatch the specialized `e2e-runner` subagent to generate and run Playwright tests.

**User Arguments**: $ARGUMENTS

## Orchestration Workflow

### 1. Context Synthesis
- Identify the user flow or page component implemented/discussed in this session.
- Target URL/route (e.g. `/login`, `/dashboard`, `/checkout`).

### 2. Dispatch E2E-Runner Subagent
Invoke the `e2e-runner` subagent with the user journey brief:

```
subagent(agent="e2e-runner", description="E2E test: <flow>")
"Generate and execute Playwright E2E tests for the following user flow:

## User Journey & Target Flow
<flow description or route from arguments/session>

## Session Context
<components, test IDs, and state transitions discussed in this session>

## Testing Rules
1. Use Page Object Model (POM) and semantic selectors (data-testid, role, text).
2. Avoid arbitrary timeouts — use auto-wait locators and network response waits.
3. Capture screenshots on failure and verify the test passes cleanly."
```

### 3. Report to User
Report test results, generated test file path, and artifact summary in the main conversation.
