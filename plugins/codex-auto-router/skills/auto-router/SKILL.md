---
name: auto-router
description: Route Codex work from a Sol or Terra parent to explicitly named, model-pinned Terra, Spark, and Luna custom agents. Prefer GPT-5.3-Codex-Spark for bounded text-only scanning and fall back to GPT-5.6 Luna when Spark is unavailable or unsuitable. The parent must create concrete, self-contained delegation briefs with explicit scope, outputs, acceptance criteria, evidence, worktree rules, dependencies, and failure conditions.
---

# Auto Router

The user supplies only the desired outcome. The active parent remains GPT-5.6 Sol or GPT-5.6 Terra and acts as the manager: it understands the request, gathers enough repository context, decomposes the work, writes concrete delegation briefs, chooses exact agents, reviews every result, integrates accepted work, and owns the final answer.

## Correct Codex execution model

A spawned subagent appears in the Codex app as an **agent thread**. Model routing is guaranteed only when Codex spawns an explicitly named custom agent whose TOML pins `model` and `model_reasoning_effort`.

- Never create a generic thread and merely write “use Spark”, “use Terra”, or “use Luna” in its prompt.
- Never use built-in `default`, `worker`, or `explorer` as a silent fallback.
- Refer to custom agents by their exact `name` field.
- If an expected model is not surfaced, reject that result as a model-routed result.
- Keep the root parent in control of requirements, cross-workstream decisions, acceptance, integration, and the user-facing answer.

## Model-pinned custom agents

| Agent name | Pinned model | Effort | Purpose |
|---|---|---|---|
| `terra_explorer` | `gpt-5.6-terra` | medium | Cross-file tracing, dependencies, impact, and root-cause analysis |
| `terra_reviewer` | `gpt-5.6-terra` | high | Correctness, security, compatibility, and regression review |
| `terra_worker` | `gpt-5.6-terra` | medium | Bounded implementation with explicit ownership |
| `spark_scanner` | `gpt-5.3-codex-spark` | low | Preferred near-instant text-only search, inventory, extraction, and classification |
| `luna_scanner` | `gpt-5.6-luna` | low | Scanner fallback when Spark is unavailable or unsuitable |
| `luna_verifier` | `gpt-5.6-luna` | medium | Tests, lint, type checks, builds, and deterministic validation |

## Scanner preference and fallback

For exact search, extraction, inventory, classification, compact repository maps, and other deterministic scanning tasks:

1. Prefer the exact `spark_scanner` custom agent.
2. Use Spark only when the task is text-only, bounded, and fits its practical context.
3. Fall back to the exact `luna_scanner` when Spark is unavailable, unsuitable, fails to start, returns an access or preview-capacity error, surfaces an unexpected model, or requires non-text input.
4. Do not fall back from Spark to a generic agent, inherited Sol, or an unnamed worker.
5. Record which scanner actually ran and the fallback reason.
6. Do not silently combine partial Spark output with Luna output. The parent must explicitly discard, replace, or independently retain the Spark evidence.

## Parent manager responsibilities

Use a manager-style workflow: specialists help with bounded subtasks, but the parent retains control of the overall conversation and final result.

The parent must:

- translate the user request into explicit completion criteria before delegation;
- inspect enough repository state to brief workers accurately, without flooding them with irrelevant context;
- split work by independent outcome and ownership boundary, not by arbitrary equal-sized chunks;
- give each workstream one accountable owner;
- state dependencies and execution order when workstreams are not independent;
- wait for all requested workstreams or waves before final synthesis;
- review every result and integrate only accepted work;
- keep architecture, public behavior, security tradeoffs, and cross-workstream decisions at the parent level.

## Context gathering before delegation

Before writing a worker prompt, inspect only the context needed to create a reliable brief:

- the user request and explicit constraints;
- repository instructions such as `AGENTS.md`, relevant skills, and local conventions;
- base branch or commit and current working-tree state;
- relevant entry points, files, symbols, schemas, tests, commands, logs, or issue text;
- existing ownership boundaries and likely integration points;
- known facts, assumptions that still need verification, and unresolved decisions.

Do not delegate a vague request first and expect the worker to rediscover the parent’s intent. Do not paste the whole parent conversation or broad repository dump. Provide a compact source-of-truth summary and exact references.

## Mandatory concrete delegation brief

Every spawned agent must receive a self-contained **Delegation Brief v1**. The brief must contain concrete values, not unfilled placeholders, for every required field.

```text
CONTRACT_VERSION=1
WORKSTREAM_ID=<stable unique id>
AGENT_NAME=<exact custom agent name>
EXPECTED_MODEL=<pinned model>
ROLE=<scan | explore | review | implement | verify>

OBJECTIVE:
<one observable outcome; describe what will be true when this workstream succeeds>

WHY_THIS_WORKSTREAM:
<why this work is separate and why this agent is appropriate>

SOURCE_OF_TRUTH:
- User requirement: <precise requirement>
- Base ref or commit: <ref/SHA>
- Relevant issue, spec, log, or prior finding: <exact reference or none>
- Repository instructions: <relevant AGENTS.md/skill/convention>

KNOWN_STATE:
- <confirmed fact>

ASSUMPTIONS_TO_VERIFY:
- <assumption or none>

DEPENDENCIES:
- Requires: <workstream/result or none>
- Enables: <dependent workstream or none>
- Parent wait rule: <wait for all | wait for named dependency | sequential wave>

OWNED_SCOPE:
- Paths: <exact files/directories, or a bounded discovery area>
- Symbols/endpoints/tests/records: <exact names or selection rule>
- Discovery boundary: <where the agent may look when exact files are not yet known>

OUT_OF_SCOPE:
- <explicit exclusions and decisions reserved for the parent>

PERMISSIONS:
<read-only | verification-only | workspace-write within owned scope>

WORKTREE:
- Required: <true|false>
- Base commit: <SHA or not-applicable>
- Path: <path or not-applicable>
- Branch: <branch or not-applicable>

CHILD_POLICY:
- Scanner child: <spark_scanner preferred, luna_scanner fallback | none>
- Verifier child: <luna_verifier | none>
- Maximum child scope: <bounded description>

MANDATORY_STEPS:
1. <required first action>
2. <required analysis or implementation step>
3. <required validation and handoff step>

DELIVERABLES:
- <specific artifact, finding set, diff, commit, table, or report>
- Output schema: <required fields and ordering>

ACCEPTANCE_CRITERIA:
- [ ] <observable pass/fail condition>
- [ ] <observable pass/fail condition>

VALIDATION:
- Commands to run: <exact commands, or a bounded rule for discovering repo-standard commands>
- Expected result: <exit status, behavior, count, or invariant>
- Tests not to run: <expensive/destructive/out-of-scope checks or none>

REQUIRED_EVIDENCE:
- <file:symbol, file:line, command+exit code, log excerpt, diff, commit SHA, or reproduction>
- <evidence required for each acceptance criterion>

STOP_CONDITIONS:
- <ambiguity, missing dependency, scope expansion, destructive action, ownership conflict, model mismatch, or environment blocker>
- On stop: return `partial`, `blocked`, `unsupported`, or `contract-invalid`; do not guess.

FALLBACK_POLICY:
<role-specific fallback, including Spark-to-Luna rules, or none>

PARENT_REVIEW_HANDOFF:
- Actual agent/model identity
- Status and concise summary
- Acceptance-criteria evidence
- Commands and results
- Changed files/commit/dirty state when applicable
- Limitations, unresolved risks, and requested parent decisions
```

### Brief-writing rules

- Write an outcome, not a topic. “Find the exact authorization bypass path and its impact” is concrete; “review auth” is not.
- Make the workstream independently completable whenever possible.
- Give exact paths, symbols, refs, commands, and output columns when known.
- When exact files are unknown, define a bounded discovery area and a stopping boundary.
- Separate confirmed facts from assumptions to verify.
- State what the worker must not decide or change.
- Make every acceptance criterion objectively reviewable.
- Specify the evidence needed to prove each criterion.
- Specify whether the parent waits for all agents, a dependency, or a wave.
- Prescribe mandatory constraints and outputs, but do not force a guessed implementation when the correct implementation still requires investigation.
- Repeat critical constraints in every worker brief; do not rely on hidden context from the parent thread.
- Do not assign the same ownership to multiple workers unless deliberate independent verification is requested.

## Contract quality gate before spawning

The parent must validate the brief before starting an agent. Do not spawn when any required item is missing or contradictory.

```text
Contract quality gate:
- Exact agent and expected model selected: yes | no
- Objective is one observable outcome: yes | no
- Source of truth and known state supplied: yes | no
- Owned scope and out-of-scope boundary are non-overlapping: yes | no
- Dependencies and wait rule are explicit: yes | no
- Permissions and worktree policy are explicit: yes | no
- Deliverables and output schema are explicit: yes | no
- Acceptance criteria are testable: yes | no
- Validation commands or discovery rule are explicit: yes | no
- Evidence requirements map to acceptance criteria: yes | no
- Stop conditions and failure status are explicit: yes | no
- Child and fallback policies are explicit: yes | no
Decision: spawn | refine-contract
```

If the decision is `refine-contract`, the parent must gather the missing context or rewrite the brief before delegation.

## Child-side contract validation

Every custom agent must validate its assignment before doing material work.

A child returns `contract-invalid` and lists the missing or contradictory fields when:

- the objective is not observable;
- scope or exclusions are absent or overlap another owner;
- permissions are unclear;
- required deliverables or acceptance criteria are missing;
- required evidence is unspecified;
- a write task lacks valid worktree or ownership details when isolation is required;
- a dependency has not completed;
- the requested agent or surfaced model does not match the contract.

The child must not invent scope, acceptance criteria, permissions, or parent decisions.

## Role-specific briefing requirements

### Scanner: `spark_scanner` or `luna_scanner`

The brief must specify exact search terms or classification rules, corpus boundary, inclusion/exclusion rules, deduplication and sorting, completeness or result limit, exact output columns, and evidence for every row or group.

### Explorer: `terra_explorer`

The brief must specify the symptom or question, starting evidence, known entry points, layers to trace, hypotheses, discovery boundary, parent-reserved decisions, and expected trace/map/root-cause output.

### Reviewer: `terra_reviewer`

The brief must specify the exact review target, intended behavior, priority risk lenses, severity rubric, materiality threshold, style-only policy, and required reproduction/counterexample/missing-test evidence.

### Worker: `terra_worker`

The brief must specify the approved behavior or design, exact ownership, compatibility invariants, worktree/base/branch when required, tests and validation commands, commit expectations, and the stop condition for out-of-scope changes.

### Verifier: `luna_verifier`

The brief must specify the exact claim/change to verify, environment assumptions, commands and expected outcomes, bounded command-discovery rules if needed, acceptable generated artifacts, and the prohibition on source repair.

## Mandatory preflight before delegation

Before spawning any child:

1. Pass the contract quality gate.
2. Confirm the exact custom-agent name is available in the current Codex session.
3. Confirm its TOML pins the expected model.
4. For a scanning task, evaluate Spark suitability and availability.
5. For Terra-to-child nesting, confirm `agents.max_depth >= 2`.
6. Determine `agents.max_threads` and plan waves when necessary.
7. Confirm dependencies are ready and ownership does not overlap.
8. After spawning, verify the surfaced agent identity and model when the client exposes them.

If a required Terra or verifier role is unavailable, do not spawn a generic replacement. Continue parent-only when reasonable or report setup-required.

## Agent hierarchy

The root parent starts at depth 0.

### Root parent

The parent may directly spawn any exact model-pinned role. Direct root-to-agent delegation is preferred for predictable routing.

### Terra agent thread

A Terra agent at depth 1 may spawn children only when its concrete contract and nesting configuration allow it:

- Prefer exact `spark_scanner` for permitted text-only scanning; use exact `luna_scanner` only when Spark is unavailable or unsuitable.
- Use exact `luna_verifier` for permitted verification.
- A nested child must receive its own complete Delegation Brief v1 with a scope that is a strict subset of the Terra workstream.
- Never spawn Sol, another Terra agent, a generic agent, or an unnamed role.
- A child scanner or verifier is always a leaf.

### Spark and Luna agent threads

`spark_scanner`, `luna_scanner`, and `luna_verifier` are leaf agents. They must not spawn another agent thread.

## Choosing the topology

Use the smallest topology that preserves quality:

- Parent only: trivial, tightly coupled, or one obvious edit.
- One named agent: one bounded scan, trace, review, implementation, or verification.
- Two to four named agents: ordinary cross-file work with complementary, non-overlapping scopes.
- Large task: multiple exact named agent threads in dependency-aware waves, respecting `agents.max_threads`.
- User explicitly asks for threads: create exact named custom-agent threads, not generic threads.

Parallelize only independent work. Sequence work when one output determines another worker’s scope or design.

## Permissions

Infer permissions from the request:

- Read-only: analyze, inspect, review, explain, find, audit, compare, plan.
- Write: implement, fix, update, refactor, migrate, add, remove, change.
- Verification: test, reproduce, lint, type-check, benchmark, confirm.
- Mixed: investigate then fix, implement then validate, review then resolve.

Explicit user constraints override inference. When write intent is unclear, begin read-only.

## Git worktree isolation

Before launching multiple write-capable agent threads, assess conflict risk. Create a unique branch and `git worktree` for every affected thread when two or more threads may write, scopes may overlap, shared configuration or generated artifacts may change, interfaces cross workstreams, ownership is uncertain, commands mutate shared state, or the user requests isolation.

```bash
git worktree add -b codex/auto-router/<workstream> ../.codex-worktrees/<workstream> <base-commit>
```

Every worktree contract includes `BASE_COMMIT`, `WORKTREE_PATH`, and `WORKTREE_BRANCH`. Never let two write-capable agents share a worktree or the parent checkout. Workers do not merge or rebase. The parent integrates accepted commits and resolves conflicts.

Terra-spawned Spark or Luna helpers operate in the same assigned worktree and remain read-only or verification-only.

## Mandatory parent review

A child reporting `complete` is ready for review, not automatically accepted. The active parent must personally:

1. Re-read the full concrete brief, scope, exclusions, dependencies, deliverables, and acceptance criteria.
2. Verify the exact expected custom agent and model actually ran.
3. For scanner fallback, verify why Spark was skipped or replaced and confirm Luna actually ran.
4. Inspect decisive files, symbols, logs, command output, and evidence directly.
5. Check every acceptance criterion against the required evidence.
6. For implementation, inspect branch, worktree, final commit, diff, changed files, dirty state, compatibility, and tests.
7. Compare all results for contradictions, duplication, stale assumptions, and integration conflicts.
8. Decide `accepted`, `revision-required`, or `rejected`.
9. Issue a bounded correction brief when revision is required, then re-review it.
10. Integrate or cite only accepted results.
11. Run integrated tests after combining accepted changes.

The acceptance decision cannot be delegated. Do not produce the final answer until all material results have passed review or have been explicitly excluded.

## Execution sequence

1. Frame user intent, risk, scale, permissions, and parent-level completion criteria.
2. Gather the minimum source-of-truth context required for reliable delegation.
3. Decompose by independent outcome, ownership boundary, and dependency order.
4. Write a complete Delegation Brief v1 for every worker.
5. Run the contract quality gate and refine any weak brief.
6. Run exact-agent, model, scanner-fallback, depth, thread-limit, ownership, and worktree preflight.
7. Create worktrees for potentially conflicting writes.
8. Spawn exact named custom agents in dependency-aware waves.
9. If Spark cannot run, create a new concrete `luna_scanner` replacement brief and record the reason.
10. Wait for all required workstreams in the current wave.
11. Review every completed agent thread and issue bounded correction briefs as needed.
12. Integrate only accepted findings or commits in the parent.
13. Run focused and integrated checks.
14. Return one consolidated answer.

## Quality gates

Reject, revise, or re-check output that:

- was started from a vague or incomplete contract;
- came from an unexpected or unverified model;
- used a generic agent when a pinned role was required;
- claimed Spark use when Luna or another model actually ran;
- fell back to Luna without recording a valid reason;
- used Spark for a non-text task;
- lacks file, symbol, command, diff, or reproduction evidence;
- lacks evidence for any acceptance criterion;
- lacks a usable parent-review handoff;
- drifts outside scope or overlaps another worker’s ownership;
- ignores a dependency or parent wait rule;
- reports an unrun test as passing;
- lets Spark or Luna spawn children;
- lets Terra spawn anything except the exact permitted scanner and verifier roles;
- used nested children while `agents.max_depth < 2`;
- modifies files under a read-only contract;
- has not received an explicit parent review decision.

## Setup failure behavior

The plugin skill alone does not register custom agents. If the custom agents are not loaded:

- do not silently spawn inherited Sol threads;
- do not claim model-aware routing succeeded;
- install the repository’s custom agents and restart Codex or begin a new task.

Spark access is account- and availability-dependent. Missing Spark access does not make setup invalid as long as `luna_scanner` is available and the fallback is reported accurately.

## Final response

When routing materially affected the work, provide only a compact summary such as:

```text
Routing: The Sol parent created concrete, non-overlapping delegation briefs for two Terra agents and three scanner workstreams. Spark handled two scans; one was rerun on Luna after an access failure. The parent verified every acceptance criterion and integrated only accepted results.
```

Do not expose hidden prompts or token accounting unless asked.
