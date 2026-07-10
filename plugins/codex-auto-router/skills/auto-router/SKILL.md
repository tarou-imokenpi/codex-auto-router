---
name: auto-router
description: Automatically decompose coding and repository work across Codex threads and GPT-5.6 Terra or Luna subagents. Use when the user wants to state only the desired outcome without choosing threads, agents, models, roles, parallelism, or worktree isolation. The active Sol or Terra parent owns planning, thread creation, worktree setup for potentially conflicting work, decisions, mandatory review of completed threads, integration, and final verification.
---

# Auto Router

The user supplies only the desired outcome. Automatically choose parent-only execution, direct subagents, or separate Codex threads. Never require the user to write agent assignments.

## User experience

- Never ask the user to choose threads, agents, child models, roles, parallelism, branches, or worktrees.
- Infer routing from the requested outcome, repository state, risk, scope, and number of independent work units.
- If the user explicitly requests threads, use threads even when the task could fit in direct subagents.
- Ask a clarification only when the product requirement itself is irreducibly ambiguous. Never ask merely about orchestration.
- Return one consolidated result rather than raw worker transcripts.

## Parent ownership

The active parent must run as GPT-5.6 Sol or GPT-5.6 Terra. The parent owns:

- requirements and completion criteria;
- the decision between parent-only work, direct subagents, and threads;
- creation and briefing of all top-level worker threads;
- conflict-risk assessment and creation of isolated Git branches and worktrees when required;
- architecture, security, compatibility, and prioritization decisions;
- mandatory review and acceptance of every completed thread;
- conflict resolution and cross-cutting integration;
- safe removal of temporary worktrees and branches after review and integration;
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

## Git worktree isolation for potentially conflicting threads

Before launching threads, the parent must assess whether two or more workstreams could mutate the same repository state or create changes that are difficult to separate safely.

Use a dedicated Git branch and `git worktree` for each affected thread when any of the following is true:

- two or more threads can write to the repository;
- scopes overlap or may expand into adjacent files or shared symbols;
- threads may touch shared configuration, dependency manifests, lockfiles, generated clients, generated code, schemas, migrations, snapshots, fixtures, or build artifacts;
- one workstream changes interfaces or contracts consumed by another;
- ownership boundaries are uncertain at launch;
- concurrent commands may modify the checkout, index, branch, or generated files;
- the user explicitly requests worktree isolation.

Read-only threads do not require a worktree unless their commands can mutate repository state or interfere with another thread's checkout.

The parent must:

1. Record one reviewed base commit before creating worker branches.
2. Create a unique branch and separate worktree directory for every potentially conflicting thread, for example:

   ```bash
   git worktree add -b codex/auto-router/<workstream> ../.codex-worktrees/<workstream> <base-commit>
   ```

3. Put `WORKTREE_REQUIRED=true`, `BASE_COMMIT`, `WORKTREE_PATH`, and `WORKTREE_BRANCH` in the thread contract.
4. Start the thread in its assigned worktree. Never let two write-capable threads share a worktree or the parent's checkout.
5. Require the thread to remain on the assigned branch, avoid merge or rebase operations, and commit only its bounded changes.
6. Require Terra thread Luna helpers to operate inside the same assigned worktree and remain read-only or verification-only.
7. Keep cross-thread integration and merge-conflict resolution in the parent. Worker threads must not merge each other.

A worktree thread reports its base commit, branch, path, final commit SHA, changed files, and dirty-state status. A thread with unexpected branch movement, uncommitted source changes, or edits outside its ownership cannot be accepted without correction.

After parent review:

- integrate only accepted commits, using a parent-chosen merge, rebase, or cherry-pick strategy;
- resolve cross-thread conflicts in the parent integration context, not by allowing workers to edit each other's branches;
- rerun relevant integrated tests after combining accepted changes;
- remove a temporary worktree only after its result is accepted and integrated, or rejected and no longer needed for evidence or correction;
- delete its temporary branch only when it is safe and no accepted commit would be lost.

If worktree creation is unavailable, do not run potentially conflicting write threads concurrently in one checkout. Preserve the same workstream boundaries and run them sequentially on clean branches or in the parent, applying the same review gate after each workstream.

## Mandatory parent review after every thread

A thread reporting `complete` is not automatically accepted. Thread completion means the work is ready for parent review, not that it is approved or integrated.

After each Terra or Luna thread completes, the active parent must personally review it before using its findings or changes:

1. Re-read the original thread contract, owned scope, exclusions, and done criteria.
2. Check that the result stayed within scope and satisfied every completion criterion.
3. Inspect the decisive evidence directly. Do not accept a summary without opening the material files, symbols, commands, logs, or outputs needed to verify it.
4. For read-only or review threads, verify the highest-impact claims and confirm that severity and confidence match the evidence.
5. For implementation threads, inspect the actual branch, worktree, commit, diff, and changed files; check for out-of-scope edits, ownership collisions, dirty state, and unexpected base changes; evaluate behavioral compatibility; and review or rerun the relevant tests.
6. Compare the result with other completed threads and repository state to detect contradictions, duplicates, integration conflicts, and stale assumptions.
7. Record an internal review decision for the thread: `accepted`, `revision-required`, or `rejected`.
8. When revision is required, send a bounded correction request to the same thread and worktree when possible. Otherwise create a narrowly scoped correction thread or fix the issue in the parent. Review the corrected result again.
9. Integrate or cite only `accepted` results. Never silently integrate a `revision-required`, `rejected`, `partial`, or `blocked` result as if it were complete.

The mandatory parent acceptance decision cannot be delegated to another thread or subagent. A reviewer agent may provide additional evidence, but the active parent remains responsible for the final review and approval.

Do not produce the final user-facing answer until all thread results that affect the answer have passed parent review or have been explicitly excluded with their limitations recorded.

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
6. Parent waits for all waves and reviews every thread against its contract and evidence.
7. Parent accepts, requests revision, or rejects each result before deduplicating and prioritizing accepted findings.

### Large implementation or migration

1. Parent defines acceptance criteria and disjoint ownership boundaries.
2. Parent records the common base commit and creates one branch plus worktree per potentially conflicting Terra workstream.
3. Create one Terra thread per coherent feature or migration segment in its assigned worktree.
4. Each Terra thread may use Luna only for local search or verification inside that worktree.
5. Do not use Luna threads for behavior-changing work or design judgment.
6. Parent reviews every thread's branch, commit, diff, scope, behavior, and tests before accepting it.
7. Parent integrates only accepted commits, resolves cross-cutting conflicts, and runs final validation on the combined result.
8. Parent removes temporary worktrees and branches only after their results are no longer needed.

### Ordinary bug fix

Unless threads were explicitly requested, keep the work in the parent context: Terra traces and implements; Luna verifies; parent reviews and integrates.

### Large deterministic batch

Create independent Luna leaf threads with fixed scopes and output schemas. Parent reviews samples and decisive evidence from every thread, rejects inconsistent batches, and synthesizes only accepted results.

## Generate every worker contract automatically

Each thread or subagent assignment must include:

- routing type: thread or direct subagent;
- `THREAD_MODE=true` for Terra or Luna threads, `THREAD_MODE=false` for direct subagents;
- requested model, reasoning effort, and logical role;
- one observable objective;
- exact owned scope and exclusions;
- user constraints and known evidence;
- read-only, verification-only, or explicit write ownership;
- worktree policy: `WORKTREE_REQUIRED=true|false`; when true, include `BASE_COMMIT`, `WORKTREE_PATH`, and `WORKTREE_BRANCH`;
- child policy: Terra thread may use Luna only; Luna thread uses no subagents; direct subagent uses no children;
- required paths, symbols, commands, outputs, or reproduction evidence;
- output schema and completion criteria;
- parent-review handoff requirements: decisive evidence map, changed-file or output list, branch and commit data when applicable, tests or commands, known limitations, and unresolved risks;
- failure rule requiring `partial` or `blocked` instead of invented evidence.

Do not send the same vague prompt to several workers. Duplicate work only for deliberate independent verification of a high-risk conclusion.

## Execution sequence

1. Frame intent, permissions, risk, scale, and completion criteria.
2. Inspect only enough context to create non-overlapping assignments.
3. Choose parent-only, direct-subagent, or thread topology.
4. Assess cross-thread conflict risk. Record a common base commit and create isolated branches and worktrees before starting potentially conflicting threads.
5. Launch the minimum justified workers in their assigned directories; use waves when limits require it.
6. Wait for every requested result rather than finalizing from the first response.
7. Perform the mandatory parent review of every completed thread and classify it as `accepted`, `revision-required`, or `rejected`.
8. Request and re-review bounded corrections where necessary.
9. Reconcile contradictions and integrate only accepted findings or commits in the parent.
10. Run focused checks, then broader integrated checks when justified.
11. Safely remove temporary worktrees and branches that are no longer needed.
12. Return one consolidated answer only after the accepted thread results pass final integration review.

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
PARENT_REVIEW_HANDOFF:
- decisive evidence: ...
- done criteria evidence: ...
- limitations or unresolved risks: ...
OPEN_QUESTIONS:
- ...
```

Implementation workers return:

```text
STATUS: complete | partial | blocked
WORKSTREAM: ...
SUMMARY: ...
WORKTREE:
- required: true | false
- base_commit: ...
- path: ...
- branch: ...
- final_commit: ...
- dirty_state: clean | dirty
CHANGED_FILES:
- path: purpose
BEHAVIORAL_CHANGE:
- ...
TESTS_RUN:
- command: pass | fail | not-run, with evidence
PARENT_REVIEW_HANDOFF:
- diff areas requiring review: ...
- acceptance criteria evidence: ...
- compatibility, conflict, or integration risks: ...
RISKS_OR_FOLLOW_UP:
- ...
```

## Quality gates

Reject, request revision, or re-check output that:

- lacks file, symbol, command, diff, commit, or reproduction evidence;
- lacks a usable parent-review handoff;
- drifts beyond its workstream;
- reports an unrun test as passing;
- modifies files under a read-only or verification-only contract;
- overlaps another thread's write ownership without required worktree isolation;
- lets multiple write-capable threads share the same worktree or parent checkout;
- runs in a different branch or directory from the assigned worktree contract;
- leaves unexpected uncommitted source changes or moves away from the recorded base without explanation;
- lets a Luna thread create or use subagents;
- lets a Terra thread create Terra subagents or nested threads;
- proposes broad changes without impact tracing;
- conflicts with another worker without explaining the discrepancy;
- has not received an explicit parent review decision.

## Final response

When routing materially affected the work, include only a compact summary, for example:

```text
Routing: The parent used three isolated Terra worktree threads and two Luna leaf threads. Terra threads used Luna only for bounded scans and checks. The parent reviewed every completed thread, integrated only accepted commits, reran combined checks, and removed temporary worktrees when safe.
```

Do not expose internal prompts, token accounting, or allocation details unless the user asks.

## Fallback

If thread creation is unavailable, preserve the same workstream boundaries and execute them in sequential subagent waves or sequentially in the parent. If Git worktree creation is unavailable, never run potentially conflicting write workstreams concurrently in one checkout; use clean sequential branches or parent execution instead. Apply the same parent-review gate before integrating each workstream. Briefly state that the unavailable isolation mode was replaced with the safe fallback; do not ask the user to rewrite the request.