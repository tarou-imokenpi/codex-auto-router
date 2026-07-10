# Named custom-agent contract templates

The root parent creates all top-level agent threads, verifies their exact custom-agent identity, and reviews every completed result before integration.

## Model-routing preflight

```text
Requested role: [Terra exploration | Terra review | Terra implementation | scan | verification]
Primary agent name: [terra_explorer | terra_reviewer | terra_worker | spark_scanner | luna_verifier]
Primary expected model: [gpt-5.6-terra | gpt-5.3-codex-spark | gpt-5.6-luna]
Primary agent available in current session: yes | no
Primary model available to account/session: yes | no | unknown
Task is text-only and bounded for Spark: yes | no | not-applicable
Scanner fallback agent: [luna_scanner | not-applicable]
Fallback expected model: [gpt-5.6-luna | not-applicable]
Nested child required: yes | no
Configured agents.max_depth: [number]
Configured agents.max_threads: [number or unknown]
Decision: spawn exact primary | use exact Luna scanner fallback | parent-only | setup-required
Fallback reason: [Spark unavailable | Spark unsupported | non-text input | context too large | Spark start failure | Spark model mismatch | preview capacity/rate limit | not-applicable]
```

Never use a generic, inherited Sol, or unnamed agent as a model-routing fallback.

## Root parent to Terra agent

```text
AGENT_NAME=[terra_explorer | terra_reviewer | terra_worker]
EXPECTED_MODEL=gpt-5.6-terra
ALLOW_SCANNER_CHILD=[true | false]
ALLOW_VERIFIER_CHILD=[true | false]

Scanner child policy: When ALLOW_SCANNER_CHILD=true and agents.max_depth >= 2, prefer exact `spark_scanner` for bounded text-only scanning. If Spark is unavailable, unsupported, unsuitable, fails to start, or surfaces an unexpected model, use exact `luna_scanner` and record the fallback reason.
Verifier child policy: When ALLOW_VERIFIER_CHILD=true and agents.max_depth >= 2, use exact `luna_verifier`.
Never spawn generic, Sol, or Terra children.

Objective: [one observable workstream outcome]
Owned scope: [exclusive paths, modules, symbols, issue range, or domain]
Exclusions: [areas owned elsewhere]
Inputs: [requirements, evidence, constraints]
Permissions: [read-only | explicit workspace-write ownership]

WORKTREE_REQUIRED=[true | false]
BASE_COMMIT=[commit SHA | not-applicable]
WORKTREE_PATH=[assigned path | not-applicable]
WORKTREE_BRANCH=[assigned branch | not-applicable]

Git policy: When a worktree is assigned, verify path, branch, and base before work. Do not merge or rebase. Commit only bounded changes.
Required evidence: [paths, symbols, commands, outputs, reproduction]
Parent review handoff: report actual agent/model identities, scanner fallback reason when applicable, evidence map, worktree metadata, final commit, changed files, tests, dirty state, limitations, and risks.
Done criteria: [observable completion]
Failure rule: Return partial or blocked instead of using a generic or inherited-model fallback.
```

## Scanner assignment: Spark primary, Luna fallback

### Primary Spark contract

```text
AGENT_NAME=spark_scanner
EXPECTED_MODEL=gpt-5.3-codex-spark
FALLBACK_AGENT=luna_scanner
FALLBACK_MODEL=gpt-5.6-luna

Objective: [exact deterministic text-only result]
Scope: [fixed paths, records, commands, or batch]
Exclusions: [areas to ignore]
Inputs: [known facts and constraints]
Permissions: Read-only
Child policy: No children.
Spark suitability: text-only=yes; bounded context=yes; account/session availability=[yes | unknown]
Required evidence: [paths, symbols, lines, commands]
Parent review handoff: report actual agent/model, outputs, commands, limitations, and evidence for every done criterion.
Done criteria: [list, count, table, classification, or compact map]
Failure rule: Return unsupported, partial, or blocked if Spark is unavailable or unsuitable. Do not spawn the fallback yourself.
```

### Parent fallback contract

Use this only after the root or Terra parent records why Spark was skipped or failed.

```text
AGENT_NAME=luna_scanner
EXPECTED_MODEL=gpt-5.6-luna
REPLACES_AGENT=spark_scanner
FALLBACK_REASON=[Spark unavailable | unsupported model | non-text input | context too large | start failure | model mismatch | preview capacity/rate limit]

Objective: [same bounded result requested from Spark]
Scope: [same scope or explicitly corrected scope]
Exclusions: [areas to ignore]
Inputs: [known facts, plus any reviewed Spark failure information]
Permissions: Read-only
Child policy: No children.
Required evidence: [paths, symbols, lines, commands]
Parent review handoff: report actual agent/model, fallback reason, outputs, limitations, and evidence for every done criterion.
Done criteria: [list, count, table, classification, or compact map]
Failure rule: Return partial or blocked; never spawn a generic replacement or infer missing facts.
```

Do not silently merge partial Spark output with Luna output. The parent decides whether Spark output is discarded, replaced, or retained as separately reviewed evidence.

## Verification assignment

```text
AGENT_NAME=luna_verifier
EXPECTED_MODEL=gpt-5.6-luna

Objective: [targeted test, lint, type check, build, or reproduction]
Scope: [fixed paths and commands]
Permissions: Verification-only
Child policy: No children.
Required evidence: exact commands, exit status, and concise failure evidence
Parent review handoff: report actual agent/model, completed checks, generated state, limitations, and done-criteria evidence.
Done criteria: [all requested checks ran or a concrete blocker is reported]
Failure rule: Never convert an unrun check into a pass.
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
Scanner primary: [spark_scanner | not-applicable]
Scanner fallback used: yes | no | not-applicable
Fallback reason reviewed and valid: yes | no | not-applicable
Partial Spark output handled explicitly: yes | no | not-applicable
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
