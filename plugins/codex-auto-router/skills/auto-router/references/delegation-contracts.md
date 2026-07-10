# Concrete delegation contracts

The root parent creates all top-level agent threads, supplies a self-contained concrete brief, verifies the exact agent/model identity, waits according to the dependency plan, and reviews every completed result before integration.

## Delegation Brief v1 — required base template

Replace every placeholder before spawning. A worker must not receive an incomplete template.

```text
CONTRACT_VERSION=1
WORKSTREAM_ID=<unique stable id>
AGENT_NAME=<terra_explorer | terra_reviewer | terra_worker | spark_scanner | luna_scanner | luna_verifier>
EXPECTED_MODEL=<gpt-5.6-terra | gpt-5.3-codex-spark | gpt-5.6-luna>
ROLE=<scan | explore | review | implement | verify>

OBJECTIVE:
<one observable outcome>

WHY_THIS_WORKSTREAM:
<why it is independently useful and why this agent owns it>

SOURCE_OF_TRUTH:
- User requirement: <exact requirement>
- Base ref/commit: <branch, tag, or SHA>
- Issue/spec/log/prior finding: <exact reference or none>
- Repository instructions: <applicable AGENTS.md, skill, conventions>

KNOWN_STATE:
- <confirmed fact>

ASSUMPTIONS_TO_VERIFY:
- <assumption or none>

DEPENDENCIES:
- Requires: <workstream/result or none>
- Enables: <workstream/result or none>
- Parent wait rule: <wait for all | wait for named dependency | sequential wave>

OWNED_SCOPE:
- Paths: <exact files/directories or bounded discovery area>
- Symbols/endpoints/tests/records: <exact names or selection rule>
- Discovery boundary: <where exploration may extend and where it must stop>

OUT_OF_SCOPE:
- <explicit exclusions>
- Parent-reserved decisions: <architecture/public behavior/security/integration decisions>

PERMISSIONS:
<read-only | verification-only | workspace-write within owned scope>

WORKTREE:
- Required: <true|false>
- Base commit: <SHA or not-applicable>
- Path: <path or not-applicable>
- Branch: <branch or not-applicable>

CHILD_POLICY:
- Scanner child: <spark_scanner preferred with luna_scanner fallback | none>
- Verifier child: <luna_verifier | none>
- Maximum child scope: <strict subset or not-applicable>

MANDATORY_STEPS:
1. <required first action>
2. <required core action>
3. <required validation and handoff>

DELIVERABLES:
- <specific result, diff, commit, table, map, or report>
- Output schema: <fields, ordering, grouping, limits>

ACCEPTANCE_CRITERIA:
- [ ] <objective pass/fail criterion>
- [ ] <objective pass/fail criterion>

VALIDATION:
- Commands: <exact commands or bounded command-discovery rule>
- Expected result: <status, behavior, count, or invariant>
- Excluded checks: <destructive/expensive/out-of-scope checks or none>

REQUIRED_EVIDENCE:
- <evidence mapped to each acceptance criterion>
- <file:symbol, file:line, command+exit status, diff, log, reproduction, commit SHA>

STOP_CONDITIONS:
- <missing dependency, unclear ownership, scope expansion, destructive action, model mismatch, invalid worktree, or blocker>
- On stop: return `contract-invalid`, `unsupported`, `partial`, or `blocked`; do not guess.

FALLBACK_POLICY:
<scanner fallback or none>

PARENT_REVIEW_HANDOFF:
- Actual agent/model identity
- Status and concise summary
- Acceptance-criteria evidence
- Commands and outcomes
- Changed files, final commit, and dirty state when applicable
- Limitations, unresolved risks, and requested parent decisions
```

## Parent contract quality gate

Run this before every spawn:

```text
Exact agent/model selected: yes | no
Objective is one observable outcome: yes | no
Source of truth and confirmed state included: yes | no
Scope and exclusions are explicit and non-overlapping: yes | no
Dependencies and wait rule are explicit: yes | no
Permissions and worktree policy are explicit: yes | no
Deliverables and output schema are explicit: yes | no
Acceptance criteria are objectively testable: yes | no
Validation commands or discovery rule are explicit: yes | no
Evidence maps to every acceptance criterion: yes | no
Stop conditions and failure status are explicit: yes | no
Child and fallback policies are explicit: yes | no
Decision: spawn | refine-contract
```

Do not spawn until the decision is `spawn`.

## Model-routing preflight

```text
Requested role: <explore | review | implement | scan | verify>
Primary agent name: <exact custom agent>
Primary expected model: <pinned model>
Agent loaded in current session: yes | no
Pinned model confirmed in TOML: yes | no
Surfaced model can be checked after spawn: yes | no
Spark suitability: <text-only and bounded | unsuitable | not-applicable>
Scanner fallback: <luna_scanner | not-applicable>
Nested child required: yes | no
Configured agents.max_depth: <number>
Configured agents.max_threads: <number or unknown>
Dependencies ready: yes | no
Ownership collision: yes | no
Decision: spawn exact primary | use exact Luna fallback | parent-only | setup-required
Fallback reason: <reason or not-applicable>
```

Never use a generic, inherited Sol, or unnamed agent as a model-routing fallback.

## Role-specific concrete templates

### `spark_scanner` primary

```text
CONTRACT_VERSION=1
WORKSTREAM_ID=<id>
AGENT_NAME=spark_scanner
EXPECTED_MODEL=gpt-5.3-codex-spark
ROLE=scan

OBJECTIVE:
Produce <exact list/table/classification/map> for <defined corpus>.

SOURCE_OF_TRUTH:
- Base ref/commit: <ref>
- Input corpus: <paths/files/records>
- Search terms/patterns/taxonomy: <exact rules>

DEPENDENCIES:
- Requires: <none or result>
- Parent wait rule: <wait for all/wave/dependency>

OWNED_SCOPE:
- Paths: <bounded text-only paths>
- Selection rule: <include rule>
- Discovery boundary: <stop boundary>

OUT_OF_SCOPE:
- Non-text inputs
- Architecture or remediation decisions
- Files outside <boundary>

PERMISSIONS:
read-only

CHILD_POLICY:
No children.

MANDATORY_STEPS:
1. Apply the exact selection/search rules.
2. Deduplicate and sort using <rule>.
3. Return the required schema with evidence for every row/group.

DELIVERABLES:
- Output schema: <columns>
- Ordering: <rule>
- Completeness/limit: <all matches or top N>

ACCEPTANCE_CRITERIA:
- [ ] Every returned item satisfies the inclusion rule.
- [ ] Every returned item includes the required evidence.
- [ ] Exclusions, deduplication, ordering, and limit rules are applied.

VALIDATION:
- Commands: <exact search commands or tool rules>
- Expected result: <count/check>

REQUIRED_EVIDENCE:
- file path plus symbol/line for every item
- exact commands run

STOP_CONDITIONS:
- Spark unavailable or unexpected model
- non-text input required
- context exceeds bounded scope
- evidence unavailable

FALLBACK_POLICY:
Return `unsupported` or `blocked`; do not launch fallback. Parent creates a new `luna_scanner` replacement brief.

PARENT_REVIEW_HANDOFF:
Actual model, output, commands, evidence, completeness notes, and limitations.
```

### `luna_scanner` fallback

Use the same concrete scanner brief, plus:

```text
AGENT_NAME=luna_scanner
EXPECTED_MODEL=gpt-5.6-luna
REPLACES_AGENT=spark_scanner
FALLBACK_REASON=<specific reviewed reason>
SPARK_PARTIAL_OUTPUT_POLICY=<discarded | replacement | separate evidence>
```

The parent must keep objective, scope, output schema, and acceptance criteria equivalent unless the corrected scope is explicitly documented.

### `terra_explorer`

The brief must name the symptom or question, starting evidence, likely entry points, layers to trace, hypotheses to verify, discovery boundary, parent-reserved decisions, and the exact trace/map/root-cause deliverable.

Example mandatory steps:

```text
1. Confirm the observed behavior from the supplied evidence.
2. Trace the real control/data path from <entry point> through <boundary>.
3. Test or disprove each listed hypothesis.
4. Return facts, inferences, unknowns, affected owners, and evidence.
```

Acceptance criteria must state what path, cause, impact, or unknowns must be mapped.

### `terra_reviewer`

The brief must specify:

```text
Review target: <base..head, commit, diff, paths, plan, or code path>
Intended behavior: <requirements>
Priority lenses: <correctness/security/data integrity/concurrency/compatibility/regression/tests>
Severity rubric:
- critical: <project-specific threshold>
- high: <threshold>
- medium: <threshold>
Materiality threshold: <what to omit>
Style-only findings: excluded unless they conceal functional risk
```

Every material finding requires a concrete code path, counterexample, reproduction, or missing test.

### `terra_worker`

The brief must specify:

```text
Approved behavior/design: <exact requirement>
Owned paths/symbols: <exclusive ownership>
Public behavior that must not change: <invariants>
Integration boundaries: <APIs/types/schemas/consumers>
Worktree/base/branch: <exact values when required>
Required tests: <exact tests/commands>
Commit expectation: <one bounded commit or explicit rule>
```

The worker stops when a correct solution requires parent-level design changes, shared-file ownership, or out-of-scope edits.

### `luna_verifier`

The brief must specify:

```text
Claim/change to verify: <exact claim>
Environment assumptions: <runtime/dependencies/config>
Commands: <exact commands, or bounded rule for discovering repository-standard commands>
Expected exit status/behavior: <exact expectation>
Generated artifacts allowed: <list>
Source repair: prohibited
```

The verifier reports exact commands, exit status, concise failure evidence, and generated dirty state.

## Terra-to-child brief

A Terra agent may spawn a child only with a complete Delegation Brief v1 whose scope is a strict subset of the Terra workstream.

```text
PARENT_WORKSTREAM_ID=<id>
PARENT_AGENT=<terra_explorer | terra_reviewer | terra_worker>
PARENT_EXPECTED_MODEL=gpt-5.6-terra
CHILD_WORKSTREAM_ID=<id>
AGENT_NAME=<spark_scanner | luna_scanner | luna_verifier>
EXPECTED_MODEL=<pinned model>
MAX_DEPTH_REQUIREMENT=2
```

The child brief must repeat objective, source of truth, scope, exclusions, deliverables, acceptance criteria, validation, evidence, stop conditions, and handoff. It must not rely on hidden context from the Terra thread.

## Parent worktree setup

```text
Common base commit: <40-character SHA>
Conflict risk: <overlap | shared config | lockfile | migration | generated files | interface dependency | uncertain ownership>
Workstream: <id>
WORKTREE_REQUIRED=true
WORKTREE_PATH=<isolated path>
WORKTREE_BRANCH=<unique branch>
Owned paths and symbols: <exclusive ownership>
Potential integration points: <files, schemas, APIs, generated outputs>
```

```bash
git worktree add -b codex/auto-router/<workstream> ../.codex-worktrees/<workstream> <base-commit>
```

## Child contract-invalid response

```text
STATUS: contract-invalid
WORKSTREAM_ID: <id or unknown>
MISSING_OR_CONTRADICTORY_FIELDS:
- <field>: <problem>
SAFE_WORK_COMPLETED:
- none | <read-only preflight only>
REQUEST_TO_PARENT:
- <specific information or corrected boundary required>
```

The child must not invent missing scope, permissions, acceptance criteria, dependencies, or parent decisions.

## Parent review checklist

```text
Workstream: <id>
Expected custom agent/model: <name/model>
Actual agent/model verified: yes | no
Original concrete brief checked: yes | no
Dependencies were ready: yes | no
Scope/exclusions/ownership respected: yes | no
Deliverables match required schema: yes | no
Every acceptance criterion verified: yes | no
Decisive evidence inspected directly: yes | no
Spark fallback reason reviewed: yes | no | not-applicable
Partial Spark output handled explicitly: yes | no | not-applicable
Worktree/base/branch/final commit verified: yes | no | not-applicable
Diff and ownership reviewed: yes | no | not-applicable
Tests reviewed or rerun: yes | no | not-applicable
Contradictions and integration conflicts resolved: yes | no | not-applicable
Decision: accepted | revision-required | rejected
Reason: <evidence-backed reason>
Correction brief: <bounded follow-up or none>
```

Only accepted results may be integrated or cited as established findings. The parent acceptance decision cannot be delegated.
