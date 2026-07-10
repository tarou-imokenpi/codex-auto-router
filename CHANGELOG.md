# Changelog

## 2.4.0

- Added the model-pinned `spark_scanner` custom agent using `gpt-5.3-codex-spark`.
- Made Spark the preferred scanner for bounded text-only search, inventory, extraction, classification, and compact repository maps.
- Added explicit runtime fallback to the model-pinned `luna_scanner` when Spark is unavailable, unsupported, unsuitable, fails to start, hits preview capacity or rate limits, or surfaces an unexpected model.
- Required the parent or Terra agent to record the fallback reason and actual agent/model identity.
- Prevented silent mixing of partial Spark output with Luna replacement output.
- Updated Terra agents to prefer `spark_scanner`, use `luna_scanner` only as scanner fallback, and keep `luna_verifier` for verification.
- Added Spark installation checks and CI invariants while treating account/session Spark access as a runtime capability rather than an installation failure.

## 2.3.0

- Corrected the orchestration model to match current Codex documentation: visible worker threads are spawned subagent threads, not a separate top-level thread type with prompt-only model selection.
- Required exact custom-agent names (`terra_explorer`, `terra_reviewer`, `terra_worker`, `luna_scanner`, `luna_verifier`) for deterministic model routing.
- Removed silent fallback to built-in or generic agents when Terra or Luna was requested, preventing accidental Sol inheritance.
- Added mandatory preflight and post-spawn verification of custom-agent identity and expected model.
- Set parent profiles and installers to `agents.max_depth = 2` so Terra agents can spawn named Luna children when explicitly allowed.
- Updated Terra agent instructions to spawn only exact Luna custom agents and updated Luna agents as strict leaves.
- Made Custom Agent installation mandatory rather than optional and added cross-platform verification scripts.
- Updated installers to preserve existing config, back it up, and safely add or raise `[agents] max_depth` while retaining higher existing values.
- Updated documentation, contracts, examples, and troubleshooting for parent-model inheritance and session reload requirements.

## 2.2.2

- Added mandatory Git worktree isolation when multiple threads may conflict or mutate shared repository state.
- Required the parent to create a common base commit, unique branch, and dedicated worktree for every affected thread.
- Added worktree metadata, final commit, and dirty-state reporting to thread contracts and parent review.
- Prevented write-capable threads from sharing the parent checkout or another worker's worktree.
- Required cross-thread integration and merge-conflict resolution to happen in the parent after thread acceptance.
- Added safe fallback behavior: potentially conflicting write workstreams run sequentially when worktrees are unavailable.
- Updated the Terra worker policy to verify its assigned worktree and branch before editing.

## 2.2.1

- Added a mandatory parent review gate after every Terra or Luna thread completes.
- Defined thread review decisions as `accepted`, `revision-required`, or `rejected`.
- Required the parent to inspect decisive evidence and, for implementation threads, review diffs, ownership, behavior, and tests before integration.
- Prevented unreviewed, partial, blocked, revision-required, or rejected thread results from being integrated as complete work.
- Added parent-review handoff fields and a reusable review checklist to the thread contract templates.

## 2.2.0

- Added automatic thread routing when the user explicitly requests threads or when a large task exceeds practical direct-subagent concurrency.
- Added strict thread hierarchy rules: Terra threads may use Luna subagents; Luna threads are leaf workers and cannot use subagents.
- Prevented worker threads from creating nested threads and prevented Terra threads from creating Terra subagents.
- Added wave-based execution guidance when simultaneous thread capacity is limited.
- Expanded README and examples for large task sets and thread-based orchestration.
- Restored the complete `SKILL.md` after the public copy was found to be truncated.

## 2.1.0

- Added a repository marketplace layout for `codex plugin marketplace add owner/repo`.
- Added self-contained fallback routing when the optional named custom agents are not installed.
- Added macOS/Linux and Windows custom-agent installers.
- Updated publisher metadata for public distribution.

## 2.0.0

- Added Codex App plugin packaging and `@Auto Router` invocation.
- Added automatic task decomposition and Terra/Luna role selection.
