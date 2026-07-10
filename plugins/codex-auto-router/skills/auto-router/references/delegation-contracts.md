# Thread and subagent contract templates

Replace every bracketed value. The parent creates all top-level threads and reviews every completed thread before accepting or integrating its result.

## Terra thread

```text
THREAD_MODE=true
Worker type: Terra thread
Requested model: gpt-5.6-terra
Reasoning: [medium | high]
Role: [exploration | review | implementation]

Objective: [one observable workstream outcome]
Owned scope: [exclusive paths, modules, symbols, issue range, or domain]
Exclusions: [areas owned by other threads]
Inputs: [requirements, evidence, constraints]
Permissions: [read-only | explicit workspace-write ownership]
Child policy: Luna subagents are allowed only for bounded deterministic scanning, extraction, or verification in this workstream. Do not create Terra subagents or additional threads. Do not delegate source edits to Luna.
Required evidence: [paths, symbols, commands, outputs, reproduction]
Output: Use the requested result schema and include WORKSTREAM.
Parent review handoff: Provide the decisive evidence map, changed files or outputs, tests and commands, limitations, unresolved risks, and the exact evidence for every done criterion. Completion means ready for parent review, not approved.
Done criteria: [observable completion]
Failure rule: Return partial or blocked; escalate architecture, conflicts, and cross-scope requirements to the parent.
```

## Luna thread

```text
THREAD_MODE=true
Worker type: Luna leaf thread
Requested model: gpt-5.6-luna
Reasoning: [low | medium]

Objective: [exact deterministic inventory, classification, or verification result]
Scope: [fixed paths, records, commands, or batch]
Exclusions: [areas to ignore]
Inputs: [known facts and constraints]
Permissions: [read-only | verification-only]
Child policy: No subagents and no additional threads. Escalate ambiguity to the parent.
Required evidence: [paths, lines, commands, exit status]
Output: Use the requested result schema and include WORKSTREAM.
Parent review handoff: Provide the decisive evidence, completed checks, counts or outputs, sampling notes where relevant, limitations, and exact evidence for every done criterion. Completion means ready for parent review, not approved.
Done criteria: [observable list, count, table, or completed checks]
Failure rule: Return partial or blocked; never infer missing facts.
```

## Parent review checklist for completed threads

The parent must perform this review personally before integrating a thread result:

```text
Thread: [workstream]
Original contract checked: yes | no
Scope and exclusions respected: yes | no
Done criteria independently verified: yes | no
Decisive evidence inspected directly: yes | no
Diff and ownership reviewed, if applicable: yes | no | not-applicable
Tests or commands reviewed/rerun: yes | no | not-applicable
Contradictions or integration conflicts resolved: yes | no | not-applicable
Decision: accepted | revision-required | rejected
Reason: [concise evidence-backed reason]
Correction request, if any: [bounded follow-up]
```

Only `accepted` results may be integrated or cited as established findings. Review a corrected result again before acceptance. The parent acceptance decision cannot be delegated.

## Direct Luna scanner subagent

```text
THREAD_MODE=false
Prefer luna_scanner; otherwise use a built-in read-only agent. Requested model: gpt-5.6-luna, reasoning: low.

Objective: [exact inventory, extraction, or classification result]
Scope: [paths/modules/diff]
Exclusions: [areas to ignore]
Permissions: Read-only. Do not modify files or spawn subagents.
Required evidence: Cite each result with file path and symbol or line when available.
Done criteria: [observable list, count, table, or completed checklist]
Failure rule: Mark partial or blocked. Do not infer missing facts.
```

## Direct Luna verifier subagent

```text
THREAD_MODE=false
Prefer luna_verifier; otherwise use a built-in verification agent. Requested model: gpt-5.6-luna, reasoning: medium.

Objective: Verify [claim/change] using [specific commands].
Scope: [owned paths and commands]
Permissions: Verification-only. Do not edit source or spawn subagents.
Required evidence: Exact commands, exit status, and concise failure evidence.
Done criteria: Every requested check is run or a concrete blocker is reported.
Failure rule: Never convert an unrun check into a pass.
```

## Direct Terra subagent

```text
THREAD_MODE=false
Prefer [terra_explorer | terra_reviewer | terra_worker]. Requested model: gpt-5.6-terra, reasoning: [medium | high].

Objective: [bounded outcome]
Owned scope: [paths, symbols, diff]
Exclusions: [out-of-scope work]
Permissions: [read-only | explicit workspace-write ownership]
Child policy: Do not spawn subagents or threads.
Required evidence: [paths, symbols, commands, tests]
Done criteria: [observable completion]
Failure rule: Stop and report partial or blocked when correct work requires conflicting or out-of-scope changes.
```
