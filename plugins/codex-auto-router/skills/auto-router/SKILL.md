---
name: auto-router
description: Automatically decompose coding and repository work across Codex threads and GPT-5.6 Terra or Luna subagents. Use when the user wants to state only the desired outcome without choosing threads, agents, models, roles, or parallelism. The active Sol or Terra parent owns planning, thread creation, decisions, integration, and final verification.
---

# Auto Router

The user supplies only the desired outcome. Automatically choose parent-only execution, direct subagents, or separate Codex threads. Never require the user to write agent assignments.

## User experience

- Never ask the user to choose threads, agents, child models, roles, or parallelism.
- Infer routing from the requested outcome, repository state, risk, scope, and number of independent work units.
- If the user explicitly requests threads, use threads even when the task could fit in direct subagents.
- Ask a clarification only when the product requirement itself is irreducibly ambiguous. Never ask merely about orchestration.
- Return one consolidated result rather than raw worker transcripts.

## Parent ownership

The active parent must run as GPT-5.6 Sol or GPT-5.6 Terra. The parent owns:

- requirements and completion criteria;
- the decision between parent-only work, direct subagents, and threads;
- creation and briefing of all top-level worker threads;
- architecture, security, compatibility, and prioritization decisions;
- conflict resolution and cross-cutting integration;
- final validation and the user-facing answer.

This skill cannot change the active parent model. Never create a Sol child.

## Infer permissions

- **Read-only:** analyze, inspect, review, explain, find, audit, compare, plan.
- **Write:** implement, fix, update, refactor, migrate, add, remove, change.
- **Verification:** test, reproduce, lint, type-check, benchmark, confirm.
- **Mixed:** investigate then fix, implement then validate, review then resolve.

Explicit user constraints override inference. When write intent is unclear, start read-only.

## Use threads when requested or when the task is large

Use separate Codex threads instead of forcing all work into one thread's subagent concurrency limit when either condition is true:

1. The user asks for threads, separate threads, multiple workstreams, or equivalent wording.
2. The task contains enough independent work that direct subagent capacity becomes a bottleneck, including:
   - more than four useful independent read-heavy units;
   - more than two independent write units;
   - repository-wide audits spanning many packages, services, or issue categories;
   - large migrations, feature sets, or backlogs with many independently completable tasks;
   - long-running work that benefits from separately reviewable contexts;
   - context volume that would reduce accuracy or ownership clarity in one thread.

Create the minimum number of non-overlapping threads that covers the work. If simultaneous thread capacity is limited, execute threads in waves while preserving their workstream boundaries.

## Thread hierarchy and model rules

Only the active parent creates top-level worker threads. Worker threads never create additional threads.

### Terra thread

Use a Terra thread for judgment, cross-file reasoning, review, implementation, migration work, or ownership of a substantial workstream.

A Terra thread:

- may use Luna subagents for bounded deterministic searches, extraction, inventories, and verification;
- must not create Terra subagents;
- must not create additional threads;
- must not delegate source edits to Luna;
- owns one explicit, non-overlapping workstream;
- escalates architecture, cross-scope conflicts, security decisions, and public-behavior choices to the parent.

Every Terra thread contract must include `THREAD_MODE=true` so the Terra custom-agent policy permits Luna helpers.

### Luna thread

Use a Luna thread only for deterministic, isolated, low-ambiguity work with a fixed output schema.

A Luna thread:

- is a leaf worker;
- cannot use any subagents;
- cannot create additional threads;
- does not make architecture or cross-file judgment calls;
- escalates ambiguity to the parent rather than guessing.

Examples include fixed inventories, classification of a known list, config checks, and deterministic verification batches.

## Direct subagent mode

When threads were not requested and the task fits comfortably in one context, use the smallest useful direct team:

- **Level 0:** parent only for trivial or tightly coupled work.
- **Level 1:** one bounded specialist.
- **Level 2:** two or three complementary specialists for ordinary cross-file work.
- **Level 3:** at most four read-only specialists or two disjoint write specialists.

Direct-subagent limits:

- At most four read-only subagents concurrently.
- At most two write subagents concurrently, with disjoint path and symbol ownership.
- Direct subagents never spawn subagents or threads.
- Never spawn a worker only to reach a count.
- Switch to threads when the useful decomposition exceeds these limits.

## Routing profiles

Prefer named custom agents when installed. Otherwise use the nearest built-in worker and include the requested model, effort, permission, and role in the assignment.

- **`luna_scanner` — Luna / low / read-only:** exact searches, inventories, extraction, classification, checklist inspection, compact repository maps.
- **`luna_verifier` — Luna / medium / verification:** targeted tests, lint, type checks, builds, reproductions, and confirmation of specific claims.
- **`terra_explorer` — Terra / medium / read-only:** control flow, data flow, dependencies, impact analysis, root-cause investigation, ownership mapping.
- **`terra_reviewer` — Terra / high / read-only:** correctness, security, authorization, concurrency, integrity, migrations, compatibility, regressions, edge cases, missing tests.
- **`terra_worker` — Terra / medium / write:** one bounded feature or fix with exclusive paths and directly related tests.

Escalate Luna work to the parent or a Terra thread when ambiguity, cross-file reasoning, or consequential judgment appears.

## Default routing patterns

### Large repository audit

1. Parent partitions the repository into non-overlapping domains.
2. Create Terra threads for domains requiring execution-path or risk analysis.
3. Create Luna threads for deterministic inventories or fixed verification batches.
4. Terra threads may use Luna scanner/verifier subagents inside their assigned domains.
5. Luna threads work alone.
6. Parent waits for all waves, verifies decisive evidence, deduplicates, and prioritizes findings.

### Large implementation or migration

1. Parent defines acceptance criteria and disjoint ownership boundaries.
2. Create one Terra thread per coherent feature or migration segment.
3. Each Terra thread may use Luna only for local search or verification.
4. Do not use Luna threads for behavior-changing work or design judgment.
5. Parent integrates cross-cutting changes and runs final validation.

### Ordinary bug fix

Unless threads were explicitly requested, keep the work in the parent context: Terra traces and implements; Luna verifies; parent reviews and integrates.

### Large deterministic batch

Create independent Luna leaf threads with fixed scopes and output schemas. Parent handles ambiguity and synthesis.

## Generate every worker contract automatically

Each thread or subagent assignment must include:

- routing type: thread or direct subagent;
- `THREAD_MODE=true` for Terra or Luna threads, `THREAD_MODE=false` for direct subagents;
- requested model, reasoning effort, and logical role;
- one observable objective;
- exact owned scope and exclusions;
- user constraints and known evidence;
- read-only, verification-only, or explicit write ownership;
- child policy: Terra thread may use Luna only; Luna thread uses no subagents; direct subagent uses no children;
- required paths, symbols, commands, outputs, or reproduction evidence;
- output schema and completion criteria;
- failure rule requiring `partial` or `blocked` instead of invented evidence.

Do not send the same vague prompt to several workers. Duplicate work only for deliberate independent verification of a high-risk conclusion.

## Execution sequence

1. Frame intent, permissions, risk, scale, and completion criteria.
2. Inspect only enough context to create non-overlapping assignments.
3. Choose parent-only, direct-subagent, or thread topology.
4. Launch the minimum justified workers; use waves when limits require it.
5. Wait for every requested result rather than finalizing from the first response.
6. Inspect decisive evidence, reject weak claims, and reconcile contradictions.
7. Integrate findings or edits in the parent and prevent overlapping writes.
8. Run focused checks, then broader checks when justified.
9. Return one consolidated answer.

## Result schemas

Read or review workers return:

```text
STATUS: complete | partial | blocked
WORKSTREAM: ...
SUMMARY: ...
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

Implementation workers return:

```text
STATUS: complete | partial | blocked
WORKSTREAM: ...
SUMMARY: ...
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

Reject or re-check output that:

- lacks file, symbol, command, or reproduction evidence;
- drifts beyond its workstream;
- reports an unrun test as passing;
- modifies files under a read-only or verification-only contract;
- overlaps another thread's write ownership;
- lets a Luna thread create or use subagents;
- lets a Terra thread create Terra subagents or nested threads;
- proposes broad changes without impact tracing;
- conflicts with another worker without explaining the discrepancy.

## Final response

When routing materially affected the work, include only a compact summary, for example:

```text
Routing: The parent used three Terra threads and two Luna leaf threads. Terra threads used Luna only for bounded scans and checks; the parent verified and integrated the accepted results.
```

Do not expose internal prompts, token accounting, or allocation details unless the user asks.

## Fallback

If thread creation is unavailable, preserve the same workstream boundaries and execute them in sequential subagent waves or sequentially in the parent. Briefly state that thread routing was unavailable; do not ask the user to rewrite the request.
