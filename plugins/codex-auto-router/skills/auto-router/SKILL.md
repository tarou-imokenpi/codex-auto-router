---
name: auto-router
description: Route Codex work from a Sol or Terra parent to explicitly named, model-pinned Terra, Spark, and Luna custom agents. Prefer GPT-5.3-Codex-Spark for bounded text-only scanning and fall back to GPT-5.6 Luna when Spark is unavailable or unsuitable, while preserving worktree isolation, nested helpers, parent review, and integration safety.
---

# Auto Router

The user supplies only the desired outcome. The active parent remains GPT-5.6 Sol or GPT-5.6 Terra and owns decomposition, exact agent selection, worktree setup, review, integration, and the final answer.

## Correct Codex execution model

A spawned subagent appears in the Codex app as an **agent thread**. Model routing is guaranteed only when Codex spawns an explicitly named custom agent whose TOML pins `model` and `model_reasoning_effort`.

- Never create a generic thread and merely write “use Spark”, “use Terra”, or “use Luna” in its prompt.
- Never use built-in `default`, `worker`, or `explorer` as a silent fallback.
- Refer to custom agents by their exact `name` field.
- If an expected model is not surfaced, reject that result as a model-routed result.

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
3. Fall back to the exact `luna_scanner` when any of the following is true:
   - `gpt-5.3-codex-spark` is not available to the current account, plan, client, or session;
   - the `spark_scanner` custom agent is not loaded;
   - the task requires image or other non-text input;
   - the expected input or repository context is too large for a safe Spark run;
   - Spark fails to start, returns an unsupported-model or access error, is unavailable because of preview capacity or rate limits, or surfaces an unexpected model;
   - Spark returns `unsupported` before doing material work.
4. Do not fall back from Spark to a generic agent, inherited Sol, or an unnamed worker.
5. Record which scanner actually ran. Do not claim Spark was used when Luna handled the task.
6. If Spark produced partial material output before failing, do not combine it silently with Luna. The parent must review the partial output and either discard it or mark the Luna run as an explicit replacement or independent verification.

Spark is a preference, not a requirement. A successful Luna fallback is a valid result when the parent verifies the fallback reason and actual model.

## Mandatory preflight before delegation

Before spawning any child:

1. Confirm the exact custom-agent name is available in the current Codex session.
2. Confirm its TOML pins the expected model.
3. For a scanning task, evaluate Spark suitability and availability before selecting `spark_scanner` or `luna_scanner`.
4. For Terra-to-child nesting, confirm `agents.max_depth >= 2`.
5. Determine `agents.max_threads` and plan waves when necessary.
6. If a required Terra or verifier role is unavailable, do not spawn a generic replacement. Continue parent-only when reasonable or report setup-required.
7. After spawning, verify the surfaced agent identity and model when the client exposes them.

## Agent hierarchy

The root parent starts at depth 0.

### Root parent

The parent may directly spawn any exact model-pinned role. Direct root-to-agent delegation is preferred for predictable routing.

### Terra agent thread

A Terra agent at depth 1 may spawn children only when its contract and nesting configuration allow it:

- When `ALLOW_SCANNER_CHILD=true`, prefer exact `spark_scanner`; if Spark is unavailable or unsuitable, use exact `luna_scanner`.
- When `ALLOW_VERIFIER_CHILD=true`, use exact `luna_verifier`.
- Never spawn Sol, another Terra agent, a generic agent, or an unnamed role.
- A child scanner or verifier is always a leaf.

### Spark and Luna agent threads

`spark_scanner`, `luna_scanner`, and `luna_verifier` are leaf agents. They must not spawn another agent thread.

## Choosing the topology

Use the smallest topology that preserves quality:

- Parent only: trivial, tightly coupled, or one obvious edit.
- One named agent: one bounded scan, trace, review, implementation, or verification.
- Two to four named agents: ordinary cross-file work with complementary scopes.
- Large task: multiple exact named agent threads in waves, respecting `agents.max_threads`.
- User explicitly asks for threads: create exact named custom-agent threads, not generic threads.

For high-volume text scanning, prefer `spark_scanner` workers first and route unsupported workers to `luna_scanner` individually. Do not assume Spark availability is identical across sessions or over time.

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

## Worker contracts

Generate every contract automatically. Include:

- exact custom-agent name and expected model;
- scanner preference and fallback reason when applicable;
- objective, owned scope, exclusions, and done criteria;
- permission mode;
- `ALLOW_SCANNER_CHILD=true|false` and `ALLOW_VERIFIER_CHILD=true|false` for Terra agents;
- worktree metadata when applicable;
- required evidence, commands, output schema, and failure rule;
- parent-review handoff requirements.

Never send the same vague prompt to multiple workers. Duplicate work only for deliberate independent verification.

## Mandatory parent review

A child reporting `complete` is ready for review, not automatically accepted. The active parent must personally:

1. Re-read the contract, scope, exclusions, and done criteria.
2. Verify the exact expected custom agent and model actually ran.
3. For scanner fallback, verify why Spark was skipped or replaced and confirm Luna actually ran.
4. Inspect decisive files, symbols, logs, command output, and evidence directly.
5. For implementation, inspect branch, worktree, final commit, diff, changed files, dirty state, compatibility, and tests.
6. Compare all results for contradictions, duplication, stale assumptions, and integration conflicts.
7. Decide `accepted`, `revision-required`, or `rejected`.
8. Re-review every correction.
9. Integrate or cite only accepted results.
10. Run integrated tests after combining accepted changes.

The acceptance decision cannot be delegated. Do not produce the final answer until all material results have passed review or have been explicitly excluded.

## Execution sequence

1. Frame intent, risk, scale, permissions, and completion criteria.
2. Run exact-agent and scanner-fallback preflight.
3. Inspect enough context to define non-overlapping assignments.
4. Create worktrees for potentially conflicting writes.
5. Spawn exact named custom agents; use waves when thread capacity requires it.
6. If a Spark scanner cannot run, replace that workstream with exact `luna_scanner` and record the reason.
7. Wait for all requested results.
8. Review every completed agent thread and request bounded corrections as needed.
9. Integrate only accepted findings or commits in the parent.
10. Run focused and integrated checks.
11. Return one consolidated answer.

## Quality gates

Reject, revise, or re-check output that:

- came from an unexpected or unverified model;
- used a generic agent when a pinned role was required;
- claimed Spark use when Luna or another model actually ran;
- fell back to Luna without recording a valid Spark-unavailable or Spark-unsuitable reason;
- used Spark for a non-text task;
- lacks file, symbol, command, diff, or reproduction evidence;
- lacks a usable parent-review handoff;
- drifts outside scope or overlaps another worker’s ownership;
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
Routing: The Sol parent preferred Spark for four scanning workstreams. Three ran on model-pinned GPT-5.3-Codex-Spark; one lacked Spark access and was rerun on model-pinned GPT-5.6 Luna. Terra handled cross-file reasoning, and the parent reviewed every result before integration.
```

Do not expose hidden prompts or token accounting unless asked.
