# Named custom-agent contract templates

The root parent creates all top-level agent threads, verifies their exact custom-agent identity, and reviews every completed result before integration.

## Model-routing preflight

```text
Required agent name: [terra_explorer | terra_reviewer | terra_worker | luna_scanner | luna_verifier]
Expected model: [gpt-5.6-terra | gpt-5.6-luna]
Agent available in current session: yes | no
Agent TOML pins expected model: yes | no
Nested child required: yes | no
Configured agents.max_depth: [number]
Configured agents.max_threads: [number or unknown]
Decision: spawn exact named agent | parent-only | setup-required
```

Never use a generic agent as a model-routing fallback.

## Root parent to Terra agent

```text
AGENT_NAME=[terra_explorer | terra_reviewer | terra_worker]
EXPECTED_MODEL=gpt-5.6-terra
ALLOW_LUNA_CHILDREN=[true | false]

Objective: [one observable workstream outcome]
Owned scope: [exclusive paths, modules, symbols, issue range, or domain]
Exclusions: [areas owned elsewhere]
Inputs: [requirements, evidence, constraints]
Permissions: [read-only | explicit workspace-write ownership]

WORKTREE_REQUIRED=[true | false]
BASE_COMMIT=[commit SHA | not-applicable]
WORKTREE_PATH=[assigned path | not-applicable]
WORKTREE_BRANCH=[assigned branch | not-applicable]

Child policy: When ALLOW_LUNA_CHILDREN=true and agents.max_depth >= 2, spawn only exact `luna_scanner` or `luna_verifier` custom agents. Never spawn generic, Sol, or Terra children. Otherwise spawn no child.
Git policy: When a worktree is assigned, verify path, branch, and base before work. Do not merge or rebase. Commit only bounded changes.
Required evidence: [paths, symbols, commands, outputs, reproduction]
Parent review handoff: report actual agent name/model when surfaced, evidence map, worktree metadata, final commit, changed files, tests, dirty state, limitations, and risks.
Done criteria: [observable completion]
Failure rule: Return partial or blocked instead of using an unavailable or inherited-model fallback.
```

## Root parent to Luna agent

```text
AGENT_NAME=[luna_scanner | luna_verifier]
EXPECTED_MODEL=gpt-5.6-luna

Objective: [exact deterministic result]
Scope: [fixed paths, records, commands, or batch]
Exclusions: [areas to ignore]
Inputs: [known facts and constraints]
Permissions: [read-only | verification-only]
Child policy: No children.
Required evidence: [paths, lines, commands, exit status]
Parent review handoff: report actual agent name/model when surfaced, completed checks or outputs, limitations, and evidence for every done criterion.
Done criteria: [list, count, table, or completed checks]
Failure rule: Return partial or blocked; never spawn a generic replacement or infer missing facts.
```

## Terra agent to Luna child

```text
PARENT_AGENT=[terra_explorer | terra_reviewer | terra_worker]
PARENT_EXPECTED_MODEL=gpt-5.6-terra
AGENT_NAME=[luna_scanner | luna_verifier]
EXPECTED_MODEL=gpt-5.6-luna
MAX_DEPTH_REQUIREMENT=2

Objective: [bounded local search, extraction, or verification]
Scope: [subset of the Terra workstream]
Worktree: [same path as Terra parent | not-applicable]
Permissions: [read-only | verification-only]
Child policy: No children.
Required evidence: [paths, commands, outputs]
Done criteria: [observable result]
Failure rule: If the exact Luna role cannot be spawned, return control to the Terra parent; never spawn a generic or inherited-model agent.
```

## Parent worktree setup

```text
Common base commit: [40-character SHA]
Conflict risk: [overlap | shared config | lockfile | migration | generated files | interface dependency | uncertain ownership]
Workstream: [name]
WORKTREE_REQUIRED=true
WORKTREE_PATH=[isolated path]
WORKTREE_BRANCH=[unique branch]
Owned paths and symbols: [exclusive ownership]
Potential integration points: [files, schemas, APIs, generated outputs]
```

```bash
git worktree add -b codex/auto-router/<workstream> ../.codex-worktrees/<workstream> <base-commit>
```

## Parent review checklist

```text
Workstream: [name]
Expected custom agent: [name]
Expected model: [model]
Actual agent/model verified: yes | no
Original contract checked: yes | no
Scope and exclusions respected: yes | no
Done criteria independently verified: yes | no
Decisive evidence inspected directly: yes | no
Worktree/base/branch/final commit verified: yes | no | not-applicable
Diff and ownership reviewed: yes | no | not-applicable
Tests reviewed or rerun: yes | no | not-applicable
Contradictions and integration conflicts resolved: yes | no | not-applicable
Decision: accepted | revision-required | rejected
Reason: [evidence-backed reason]
Correction request: [bounded follow-up]
```

Only accepted results may be integrated or cited as established findings. The parent acceptance decision cannot be delegated.
