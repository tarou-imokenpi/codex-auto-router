# Parent orchestrator prompting guide

This guide defines how the root Sol/Terra parent should turn a user request into concrete custom-agent prompts.

## Design principles

1. **Manager retains control.** Specialists complete bounded subtasks; the parent owns requirements, shared decisions, acceptance, integration, and the final answer.
2. **Decompose by independent outcome.** Split by deliverable, ownership, or evidence boundary—not by arbitrary file counts.
3. **One owner per workstream.** Overlap is allowed only for deliberate independent verification.
4. **Make prompts self-contained.** A child should not need the parent conversation to infer scope, constraints, or completion.
5. **Specify outputs and proof.** State the output schema, acceptance criteria, validation, and evidence before spawning.
6. **Parallelize only independent work.** Use dependency-aware waves when one result determines another task.
7. **Keep prompts concrete but not solution-biased.** State required behavior and constraints; do not force an unverified implementation.
8. **Fail visibly.** Missing context, model mismatch, scope expansion, or unsafe actions return a structured blocker rather than a guess.
9. **Review before integration.** `complete` means ready for parent review, not accepted.

## Parent preparation checklist

Before writing a prompt:

- restate the user-visible outcome;
- define parent-level completion criteria;
- inspect applicable repository instructions;
- identify the base ref/commit;
- find likely entry points and source-of-truth artifacts;
- separate confirmed facts from assumptions;
- identify dependencies and shared integration points;
- determine read/write/verification permissions;
- determine whether a worktree is required;
- select the exact custom agent and expected model.

## Strong objective pattern

Use:

```text
<action> <specific object> so that <observable result>, within <scope>, while preserving <invariant>.
```

Examples:

- “Trace the request path from `POST /guides` through queue submission and persistence, identify the first code path that can drop the organization ID, and return an evidence-backed cause map without proposing architecture changes.”
- “Review `develop..HEAD` for authorization regressions affecting organization-scoped material access; report only findings with a concrete unauthorized path or missing regression test.”
- “Implement the accepted fix for issue #184 in `apps/backend/metis_backend/guides/**`, preserve the public OpenAPI contract, and make the named unit and contract tests pass.”

Avoid:

- “Investigate the backend.”
- “Check security.”
- “Fix the issue.”
- “Look through these files and tell me what you think.”

## Scope pattern

A strong scope contains:

- exact paths or a bounded discovery area;
- exact symbols, endpoints, records, or tests when known;
- a discovery boundary when locations are uncertain;
- explicit exclusions;
- parent-reserved decisions.

Example:

```text
OWNED_SCOPE:
- Paths: apps/backend/metis_backend/guides/**, apps/backend/tests/guides/**
- Symbols: create_guide, enqueue_generation, GuideRepository.create
- Discovery boundary: follow direct imports and callers only; stop at shared auth middleware
OUT_OF_SCOPE:
- OpenAPI schema changes
- queue provider replacement
- organization authorization policy changes
```

## Acceptance-criteria pattern

Each criterion must be independently reviewable.

Good:

```text
- [ ] The exact failing path is identified with file and symbol evidence.
- [ ] Every changed production branch has a directly related test.
- [ ] `uv run pytest tests/guides/test_create_guide.py -q` exits 0.
- [ ] No file outside the assigned worktree ownership is modified.
```

Weak:

```text
- [ ] Code looks good.
- [ ] Issue is fixed.
- [ ] Tests pass.
```

## Evidence pattern

Match evidence to the role:

- scanner: path, symbol/line, query or command, deduplicated row;
- explorer: entry point, control/data path, facts versus hypotheses, reproduction;
- reviewer: code path, counterexample, severity rationale, missing test;
- worker: diff, changed files, commit SHA, tests, dirty state;
- verifier: exact command, exit status, relevant output, generated state.

## Dependency and wait pattern

```text
DEPENDENCIES:
- Requires: auth-path-map
- Enables: auth-fix
- Parent wait rule: do not start auth-fix until auth-path-map is accepted
```

For independent agents:

```text
Parent wait rule: launch in parallel, wait for all three results, then review and synthesize
```

## Mandatory versus discretionary steps

Use mandatory steps for safety, evidence, and sequencing. Leave implementation details to the specialist when they are not yet known.

Good:

```text
MANDATORY_STEPS:
1. Reproduce or confirm the supplied failure.
2. Trace the responsible path within the owned boundary.
3. Make the smallest coherent change consistent with the accepted behavior.
4. Run the listed tests and report exact outcomes.
```

Avoid prescribing a speculative patch before investigation establishes the cause.

## Role-specific prompt examples

### Concrete scanner brief

```text
OBJECTIVE:
Produce a complete table of backend endpoints that perform organization-scoped writes without calling an authorization dependency.

OWNED_SCOPE:
- Paths: apps/backend/metis_backend/api/**
- Selection rule: route methods POST, PUT, PATCH, DELETE
- Exclude: tests, generated clients, admin-only routes

DELIVERABLES:
- Columns: method, route, handler symbol, authorization dependency, evidence
- Sort: route then method
- Completeness: all matching routes

ACCEPTANCE_CRITERIA:
- [ ] Every write route in scope is classified.
- [ ] Every row cites the route definition and handler.
- [ ] Duplicate aliases are grouped.
```

### Concrete explorer brief

```text
OBJECTIVE:
Trace why desktop OAuth callback completion can leave the renderer unauthenticated after the backend session succeeds.

SOURCE_OF_TRUTH:
- Symptom: callback returns 200 but renderer remains on login
- Entry points: desktop protocol handler and auth callback endpoint
- Base: develop at <SHA>

DELIVERABLES:
- Ordered event/control-flow trace
- First divergence from expected state
- Confirmed cause candidates and disproved hypotheses
- Affected files and missing observability

OUT_OF_SCOPE:
- Implementing a fix
- Replacing the auth framework
```

### Concrete reviewer brief

```text
OBJECTIVE:
Review `develop..HEAD` for data-loss or cross-tenant regressions in learning-guide deletion.

REVIEW TARGET:
- Diff: develop..HEAD
- Intended behavior: only owners may delete; dependent progress rows must remain consistent

PRIORITY LENSES:
authorization, transaction boundaries, cascading deletes, retries, regression tests

MATERIALITY:
Report only defects that can change behavior, data, security, or compatibility.
```

### Concrete worker brief

```text
OBJECTIVE:
Implement the parent-approved transaction fix for guide deletion while preserving the API response schema.

OWNED_SCOPE:
- apps/backend/metis_backend/guides/delete.py
- apps/backend/tests/guides/test_delete.py

OUT_OF_SCOPE:
- schema migrations
- endpoint renaming
- unrelated repository cleanup

ACCEPTANCE_CRITERIA:
- [ ] Delete and dependent update are atomic.
- [ ] Unauthorized deletion remains rejected.
- [ ] Named tests exit 0.
- [ ] One bounded commit is produced.
```

### Concrete verifier brief

```text
OBJECTIVE:
Verify the accepted deletion fix against the targeted regression suite and type checker without editing source.

COMMANDS:
- uv run pytest apps/backend/tests/guides/test_delete.py -q
- uv run mypy apps/backend/metis_backend/guides/delete.py

EXPECTED:
Both commands exit 0. Report exact failures otherwise.
```

## Parent review questions

- Did the exact intended agent/model run?
- Did the worker answer the stated objective rather than a nearby topic?
- Did it remain inside scope and respect exclusions?
- Is every acceptance criterion backed by evidence?
- Are claims separated from inference?
- Are tests actually run?
- Are worktree, branch, commit, and dirty state valid?
- Does another workstream contradict this result?
- Is a correction brief needed?
- Is the result accepted, revision-required, or rejected?
