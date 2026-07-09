# Delegation contract templates

Replace each bracketed value before dispatching a child.

## Luna scanner

```text
Role: luna_scanner
Requested model: gpt-5.6-luna
Reasoning: low
Objective: [exact inventory, extraction, or classification result]
Scope: [paths, modules, or diff]
Exclusions: [areas to ignore]
Context: [known facts and constraints]
Permission: Read-only. Do not modify files.
Required evidence: Cite each result with file path and symbol or line when available.
Output: Use the read/review result schema and keep findings factual.
Done criteria: [observable list, count, table, or checklist]
Failure rule: Return partial or blocked and state what could not be verified.
```

## Luna verifier

```text
Role: luna_verifier
Requested model: gpt-5.6-luna
Reasoning: medium
Objective: Verify [claim or change] with [specific commands or narrow checks].
Scope: [paths and commands]
Exclusions: Do not change source files or repair failures.
Context: [expected behavior and environment notes]
Permission: Verification-only. Generated caches and test artifacts are acceptable; source edits are not.
Required evidence: Record exact commands, exit status, and a concise failure excerpt.
Output: Use the read/review result schema with pass/fail findings.
Done criteria: Every requested check ran or a concrete blocker is reported.
Failure rule: Never convert an unrun check into a pass.
```

## Terra explorer

```text
Role: terra_explorer
Requested model: gpt-5.6-terra
Reasoning: medium
Objective: Trace and explain [behavior, problem, or impact].
Scope: [entry points, layers, paths, or diff]
Exclusions: Do not modify files or decide the final architecture.
Context: [symptoms, logs, issue, and constraints]
Permission: Read-only.
Required evidence: Trace the real execution or data path and cite files, symbols, and commands.
Output: Use the read/review result schema and separate facts, inference, and uncertainty.
Done criteria: Owning code paths, cause candidates, impact, and unknowns are mapped.
Failure rule: Do not present a hypothesis as confirmed without evidence.
```

## Terra reviewer

```text
Role: terra_reviewer
Requested model: gpt-5.6-terra
Reasoning: high
Objective: Review [diff, plan, or implementation] for [correctness, security, tests, or compatibility].
Scope: [branch, diff, paths, and requirements]
Exclusions: Avoid style-only feedback unless it hides a functional risk. Do not modify files.
Context: [acceptance criteria, threat model, and compatibility requirements]
Permission: Read-only.
Required evidence: Give a concrete reproduction, counterexample, code path, or missing test for every material finding.
Output: Use the read/review result schema ordered by severity.
Done criteria: Material risks are identified or an evidence-backed no-finding result is returned.
Failure rule: State low confidence explicitly and do not inflate severity.
```

## Terra worker

```text
Role: terra_worker
Requested model: gpt-5.6-terra
Reasoning: medium
Objective: Implement [bounded change].
Owned paths and symbols: [exclusive ownership]
Out of scope: [everything not to change]
Context: [design decision, acceptance criteria, and relevant findings]
Permission: Workspace write only within owned paths. Do not edit another worker's files.
Required evidence: Explain changed behavior and run [targeted checks].
Output: Use the implementation result schema.
Done criteria: [observable behavior] passes [tests or checks].
Failure rule: Stop and report a blocker when the correct solution requires out-of-scope or conflicting edits.
```
