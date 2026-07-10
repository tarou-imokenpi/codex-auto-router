# Changelog

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
