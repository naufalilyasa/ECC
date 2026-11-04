---
description: Run comprehensive security review with session context by delegating to the security-reviewer subagent
argument-hint: "[optional target file or endpoint]"
---

# Security Review Orchestration

You are the Lead Orchestrator handling the `/security` command. Your job is to gather session context (recently modified endpoints, auth logic, or sensitive data) and dispatch the specialized `security-reviewer` subagent.

**User Arguments**: $ARGUMENTS

## Orchestration Workflow

### 1. Context Synthesis
Gather the security audit target from the active session:
- **Target Files**: If `$ARGUMENTS` names files/endpoints, use them. Otherwise, inspect `git diff --name-only HEAD` or recent changes in this session to identify modified routes, controllers, or database queries.
- **Sensitive Surfaces**: Note any authentication flows, API handlers, environment variables, or database interactions touched in this session.

### 2. Dispatch Security-Reviewer Subagent
Invoke the `security-reviewer` subagent with the synthesized brief:

```
subagent(agent="security-reviewer", description="Security audit: <target>")
"Conduct a thorough security review of the following changes and endpoints:

## Target Files & Scope
<list of files or git diff summary>

## Session Context
<summary of what was built or modified in this session>

## Review Directives
1. Enforce the PoC Gate: No severity without a concrete attack path (attacker capability -> precondition -> impact).
2. Attempt local reproduction before assigning CRITICAL/HIGH severity; downgrade speculative issues.
3. Check dependencies against known CVEs via docs-lookup where relevant.
4. Deliver report with Verdict (PASS | PASS WITH FINDINGS | BLOCK), Attack Paths, PoC, and Downgraded Candidates."
```

### 3. Report to User
Present the security findings and verdict cleanly in the main conversation.
