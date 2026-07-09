---
name: auto-router
description: Automatically decompose coding and repository tasks and route bounded subtasks from a GPT-5.6 Sol or Terra parent to GPT-5.6 Terra or Luna subagents. Use when the user wants to state only the desired outcome without choosing agents, models, roles, or parallelism.
---

# Auto Router

The user supplies only the desired outcome. Infer the routing, team size, permissions, and validation strategy automatically.

## User experience

- Do not ask the user to choose child agents, models, roles, or parallel work.
- Do not require custom-agent names in the request.
- Ask about the product requirement only when it is truly ambiguous and no safe best-effort path exists.
- Keep low-level orchestration internal. Return one consolidated result.

## Parent ownership

The active Sol or Terra parent owns requirements, completion criteria, architecture, prioritization, conflict resolution, integration, final verification, and the user-facing answer.

This skill does not switch the active parent model. Do not create a Sol child. Prefer the named custom agents when installed. Otherwise use the nearest built-in agent and put the requested model, reasoning effort, permissions, and role in its task contract.

## Infer permissions

Classify the request before delegation:

- **Read-only:** analyze, inspect, review, explain, find, audit, compare, plan.
- **Write:** implement, fix, update, refactor, migrate, add, remove, change.
- **Verification:** test, reproduce, lint, type-check, benchmark, confirm.
- **Mixed:** investigate then fix, implement then validate, review then resolve.

Explicit user constraints override inference. When intent remains unclear, begin read-only instead of making speculative edits.

## Choose the smallest useful team

- **Parent only:** one obvious edit, one deterministic command, a small explanation, or tightly coupled work.
- **One child:** bounded search, isolated trace, focused review, narrow implementation, or independent verification.
- **Two or three children:** normal cross-file bugs, features, PR reviews, and subsystem analysis.
- **Three or four children:** repository-wide audits, multi-layer changes, migrations, or security-sensitive work.

Limits:

- Maximum four concurrent read-only children.
- Maximum two concurrent write children, only with disjoint file and symbol ownership.
- Nesting depth is one. Children do not create children.
- Do not create agents merely to reach a count.

## Routing profiles

### `luna_scanner`

Requested model: `gpt-5.6-luna`; reasoning: `low`; permission: read-only.

Use for file, route, symbol, dependency, test, config, and TODO inventories; exact searches; repeated-pattern detection; extraction; classification; and compact repository maps.

### `luna_verifier`

Requested model: `gpt-5.6-luna`; reasoning: `medium`; permission: verification-only.

Use for targeted tests, lint, type checks, builds, reproductions, and independent confirmation. Record exact commands and pass/fail evidence. Do not repair failures in this role.

### `terra_explorer`

Requested model: `gpt-5.6-terra`; reasoning: `medium`; permission: read-only.

Use for cross-file control flow, data flow, state transitions, dependencies, impact analysis, ambiguous root causes, and implementation-boundary discovery.

### `terra_reviewer`

Requested model: `gpt-5.6-terra`; reasoning: `high`; permission: read-only.

Use for correctness, security, authorization, concurrency, data integrity, migrations, compatibility, regressions, edge cases, and missing tests. Require concrete evidence for material findings.

### `terra_worker`

Requested model: `gpt-5.6-terra`; reasoning: `medium`; permission: workspace write within explicit ownership.

Use for one coherent feature slice or fix with bounded paths and symbols and directly related tests. Avoid broad refactors, unrelated cleanup, and overlapping edits.

Escalate Luna work to Terra when ambiguity, cross-file reasoning, or consequential judgment appears. Return architecture choices, security decisions, public-behavior changes, and conflicting findings to the parent.

## Default playbooks

### Repository audit

1. Luna Scanner maps packages, entry points, tests, configs, TODOs, and suspicious patterns.
2. Terra Explorer traces high-value execution paths and evidence-backed problems.
3. Terra Reviewer challenges correctness, security, data-integrity, and regression assumptions.
4. Luna Verifier runs a small set of targeted checks for the strongest candidates.
5. Parent verifies evidence, removes duplicates, prioritizes, and writes issue candidates.

### PR or branch review

1. Luna Scanner summarizes changed files, tests, migrations, and affected surfaces.
2. Terra Explorer maps behavior and downstream impact.
3. Terra Reviewer looks for material bugs, security risks, regressions, and missing tests.
4. Luna Verifier runs relevant checks when allowed.
5. Parent rejects weak findings and reports only defensible ones.

### Bug investigation and fix

1. Terra Explorer reproduces or traces the failure and isolates the cause.
2. Terra Worker implements the smallest coherent fix in an explicit ownership boundary.
3. Luna Verifier runs targeted regression checks.
4. Add Terra Reviewer only for high-risk or cross-cutting changes.
5. Parent inspects the diff and performs final validation.

### Feature implementation

1. Terra Explorer maps conventions, interfaces, dependencies, and a safe boundary.
2. Use one Terra Worker, or two only when ownership is naturally disjoint.
3. Luna Verifier runs focused tests, lint, type checks, and builds.
4. Terra Reviewer reviews consequential API, auth, migration, concurrency, or compatibility changes.
5. Parent integrates cross-cutting work and checks acceptance criteria.

### Test or CI triage

1. Luna Verifier reproduces failures and records exact command evidence.
2. Luna Scanner locates ownership and related configuration.
3. Terra Explorer traces non-obvious causes.
4. Terra Worker repairs only after the failure mode is understood.
5. Parent validates the final state.

## Generate concrete child contracts

Every child assignment must contain:

- logical role, requested model, and reasoning effort;
- one observable objective;
- exact scope: paths, modules, symbols, diff, commands, or questions;
- exclusions and user constraints;
- read, verification, or explicit write permission;
- required evidence: paths, symbols, lines, commands, outputs, or reproduction;
- output schema and done criteria;
- a rule to return `partial` or `blocked` rather than invent evidence.

Do not send the same broad prompt to several children unless independent verification is intentionally required for a high-risk conclusion.

## Execution sequence

1. Frame intent, constraints, permission, risk, and completion criteria.
2. Inspect enough context to create non-overlapping assignments.
3. Delegate only justified specialists.
4. Wait for all required results and compare them.
5. Inspect decisive evidence and reconcile conflicts.
6. For writes, assign exclusive ownership and prevent overlapping edits.
7. Run narrow checks first, then broader checks when justified.
8. Return one consolidated answer rather than raw child transcripts.

## Result schemas

Read or review:

```text
STATUS: complete | partial | blocked
SUMMARY: 2-5 concise sentences
FINDINGS:
- severity: critical | high | medium | low | info
  claim: ...
  evidence: path:symbol, path:line, command, or reproduction
  impact: ...
  confidence: high | medium | low
COMMANDS_RUN:
- ...
OPEN_QUESTIONS:
- ...
```

Implementation:

```text
STATUS: complete | partial | blocked
SUMMARY: 2-5 concise sentences
CHANGED_FILES:
- path: purpose
BEHAVIORAL_CHANGE:
- ...
TESTS_RUN:
- command: pass | fail | not-run, with evidence
RISKS_OR_FOLLOW_UP:
- ...
```

## Quality gates

Re-check output that lacks concrete evidence, drifts beyond scope, claims an unrun test passed, modifies files under a read-only contract, proposes broad changes without impact tracing, conflicts with another result without explanation, or duplicates another child without adding independent evidence.

## Fallback

When custom agents are unavailable, preserve the same decomposition using built-in agents where possible. When no subagent mechanism is available, execute the work sequentially in the parent. Do not ask the user to rewrite the request.
