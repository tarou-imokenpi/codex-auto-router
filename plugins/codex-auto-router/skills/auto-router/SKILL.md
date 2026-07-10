---
name: auto-router
description: Route Codex work from a Sol or Terra parent to explicitly named GPT-5.6 Terra and Luna custom agents. Use when the user wants to state only the desired outcome while the parent chooses decomposition, named agent roles, worktrees, nested Luna helpers, review, and integration without silently inheriting the parent model.
---

# Auto Router

The user supplies only the desired outcome. The active parent remains GPT-5.6 Sol or GPT-5.6 Terra and owns decomposition, agent selection, worktree setup, review, integration, and the final answer.

## Correct Codex execution model

A spawned subagent appears in the Codex app as an **agent thread**. It is not a separately configurable top-level task type.

Model routing is guaranteed only when Codex spawns an explicitly named custom agent whose TOML file pins `model` and `model_reasoning_effort`.

- Never create a generic thread and merely write “use Terra” or “use Luna” in its prompt.
- Never use built-in `default`, `worker`, or `explorer` as a silent fallback when a specific GPT-5.6 model was selected.
- If a custom agent omits `model`, Codex may inherit the parent model or choose a model automatically.
- Refer to custom agents by their exact `name` field. The filename and display nickname are not the routing identity.

## Required custom agents

Use only these model-pinned roles:

| Agent name | Pinned model | Effort | Purpose |
|---|---|---|---|
| `terra_explorer` | `gpt-5.6-terra` | medium | Cross-file tracing, dependencies, impact and root-cause analysis |
| `terra_reviewer` | `gpt-5.6-terra` | high | Correctness, security, compatibility and regression review |
| `terra_worker` | `gpt-5.6-terra` | medium | Bounded implementation with explicit ownership |
| `luna_scanner` | `gpt-5.6-luna` | low | Exact search, extraction, inventory and classification |
| `luna_verifier` | `gpt-5.6-luna` | medium | Tests, lint, type checks and deterministic validation |

## Mandatory preflight before delegation

Before spawning any child:

1. Confirm that the required exact custom agent name is available in the current Codex session.
2. Confirm the intended agent TOML pins the expected model.
3. For Terra-to-Luna nesting, confirm `agents.max_depth >= 2`.
4. Determine the current `agents.max_threads` limit and plan waves when necessary.
5. If an exact role is unavailable, **do not spawn a generic replacement**. Continue parent-only when reasonable, or report that Auto Router setup is incomplete and provide the installation command.
6. After spawning, verify the surfaced agent identity and model when the client exposes them. If the thread is Sol or otherwise unexpected, stop or disregard it and do not count its result as Terra/Luna work.

Do not claim a task used Terra or Luna unless the exact model-pinned custom agent was actually used.

## Agent hierarchy

The root parent starts at depth 0.

### Root parent

The parent may spawn any required exact Terra or Luna custom agent directly.

For ordinary work, direct root-to-agent delegation is preferred because it is simpler and predictable.

### Terra agent thread

A Terra agent at depth 1 may spawn only these exact Luna agents when its contract includes `ALLOW_LUNA_CHILDREN=true` and `agents.max_depth >= 2`:

- `luna_scanner`
- `luna_verifier`

A Terra agent must never spawn Sol, another Terra agent, a generic agent, or another Terra level. If the named Luna role is unavailable, it must continue without delegation or return `partial`/`blocked`; it must not create an inherited-model fallback.

### Luna agent thread

A Luna agent is always a leaf. It must not spawn any agent thread.

## Choosing the topology

Use the smallest topology that preserves quality.

- Parent only: trivial, tightly coupled, or one obvious edit.
- One named agent: one bounded scan, trace, review, implementation, or verification.
- Two to four named agents: ordinary cross-file work with complementary scopes.
- Large task: multiple named agent threads in waves, respecting `agents.max_threads`.
- User explicitly asks for threads: create named custom-agent threads, not generic threads.

When a Terra thread can efficiently handle local scanning or verification, set `ALLOW_LUNA_CHILDREN=true`. Otherwise set it to `false` and let the root parent launch Luna directly when needed.

## Permissions

Infer permissions from the request:

- Read-only: analyze, inspect, review, explain, find, audit, compare, plan.
- Write: implement, fix, update, refactor, migrate, add, remove, change.
- Verification: test, reproduce, lint, type-check, benchmark, confirm.
- Mixed: investigate then fix, implement then validate, review then resolve.

Explicit user constraints override inference. When write intent is unclear, begin read-only.

## Git worktree isolation

Before launching multiple write-capable agent threads, assess conflict risk. Create a unique branch and `git worktree` for every affected thread when any of the following is true:

- two or more threads may write;
- scopes overlap or may expand into adjacent files or shared symbols;
- shared config, dependency manifests, lockfiles, schemas, migrations, generated code, snapshots, fixtures, or build artifacts may change;
- one workstream changes a contract consumed by another;
- ownership is uncertain;
- commands can mutate checkout, index, generated files, or shared state;
- the user requests worktree isolation.

Record one reviewed base commit and create isolated worktrees, for example:

```bash
git worktree add -b codex/auto-router/<workstream> ../.codex-worktrees/<workstream> <base-commit>
```

Every worktree contract must include `BASE_COMMIT`, `WORKTREE_PATH`, and `WORKTREE_BRANCH`. Never let two write-capable agents share a worktree or the parent checkout. Workers do not merge or rebase. The parent integrates accepted commits and resolves conflicts.

Terra-spawned Luna helpers operate in the same assigned worktree and remain read-only or verification-only.

## Worker contracts

Generate every contract automatically. Include:

- exact custom agent name and expected model;
- objective, owned scope, exclusions, and done criteria;
- permission mode;
- `ALLOW_LUNA_CHILDREN=true|false` for Terra agents;
- worktree metadata when applicable;
- required evidence, commands, output schema, and failure rule;
- parent-review handoff requirements.

Never send the same vague prompt to multiple workers. Duplicate work only for deliberate independent verification of a high-risk conclusion.

## Mandatory parent review

A child reporting `complete` is ready for review, not automatically accepted.

The active parent must personally:

1. Re-read the contract, scope, exclusions, and done criteria.
2. Verify that the exact expected custom agent and model were used.
3. Inspect decisive files, symbols, logs, command output, and evidence directly.
4. For implementation, inspect branch, worktree, final commit, diff, changed files, dirty state, compatibility, and tests.
5. Compare all results for contradictions, duplication, stale assumptions, and integration conflicts.
6. Decide `accepted`, `revision-required`, or `rejected`.
7. Re-review every correction.
8. Integrate or cite only accepted results.
9. Run integrated tests after combining accepted changes.

The acceptance decision cannot be delegated. Do not produce the final answer until all material results have passed review or have been explicitly excluded.

## Execution sequence

1. Frame intent, risk, scale, permissions, and completion criteria.
2. Run model-routing preflight.
3. Inspect enough context to define non-overlapping assignments.
4. Create worktrees for potentially conflicting writes.
5. Spawn exact named custom agents; use waves when thread capacity requires it.
6. Wait for all requested results.
7. Review every completed agent thread and request bounded corrections as needed.
8. Integrate only accepted findings or commits in the parent.
9. Run focused and integrated checks.
10. Return one consolidated answer.

## Quality gates

Reject, revise, or re-check output that:

- came from an unexpected or unverified model;
- used a generic agent when a pinned role was required;
- lacks file, symbol, command, diff, or reproduction evidence;
- lacks a usable parent-review handoff;
- drifts outside scope or overlaps another worker’s ownership;
- reports an unrun test as passing;
- lets Luna spawn children;
- lets Terra spawn anything except the exact permitted Luna roles;
- used nested Luna while `agents.max_depth < 2`;
- modifies files under a read-only contract;
- has not received an explicit parent review decision.

## Setup failure behavior

The plugin skill alone does not register custom agents. If the custom agents are not loaded:

- do not silently spawn inherited Sol threads;
- do not claim model-aware routing succeeded;
- either complete a small task in the parent or stop delegation and direct the user to run the repository’s agent installer, then restart Codex or start a new task.

## Final response

When routing materially affected the work, provide only a compact summary such as:

```text
Routing: The Sol parent spawned two model-pinned Terra agents and one model-pinned Luna agent. One Terra agent used a named Luna verifier at depth 2. The parent reviewed every result and integrated only accepted work.
```

Do not expose hidden prompts or token accounting unless asked.
