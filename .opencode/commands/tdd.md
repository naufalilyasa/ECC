---
description: Enforce strict test-driven development by delegating to the tdd-guide subagent with session context
argument-hint: "[feature, function, or bug to implement test-first]"
---

# TDD Orchestration Command

You are the Lead Orchestrator handling the `/tdd` command. Your job is to gather session context and dispatch the specialized `tdd-guide` subagent to enforce the strict Red-Green-Refactor cycle.

**User Arguments**: $ARGUMENTS

## Orchestration Workflow

### 1. Context Synthesis
Gather the target specification from the active session:
- **Target Feature/Function**: If `$ARGUMENTS` is provided, that is your target. If `$ARGUMENTS` is empty, extract the function, component, or bug just discussed in this session.
- **Interfaces & Types**: Include any schemas, types, or data models established in recent turns.
- **Test Runner Context**: Detect the project test runner (npm, Bun, pnpm, Vitest, Jest, pytest, cargo test) and note it.

### 2. Dispatch TDD-Guide Subagent
Invoke the `tdd-guide` subagent with the synthesized brief:

```
subagent(agent="tdd-guide", description="TDD: <feature-or-function>")
"Implement the following feature using strict Test-Driven Development (TDD):

## Target Specification
<feature or function description with inputs, outputs, and edge cases>

## Session Context
<recent context, interfaces, and constraints from this session>

## Mandatory TDD Rules
1. RED: Write the failing test FIRST and verify it fails for the right reason.
2. GREEN: Write the minimal implementation to pass the test.
3. REFACTOR: Improve code cleanliness while keeping all tests passing.
4. Target 80%+ test coverage across unit and integration tests.
5. Do not write production code without an existing failing test."
```

### 3. Report to User
Present the test results, created test files, implementation summary, and coverage stats in the main conversation.
