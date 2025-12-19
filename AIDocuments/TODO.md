# RsyncUI TODO — December 19, 2025

This document tracks proposed next steps after v2.8.2rc2 preparations. Tasks are grouped by priority and include file indices and acceptance criteria.

Legend: [H] High • [M] Medium • [L] Low • [Opt] Optional • [✓] Completed

---

## [✓] 0) RsyncProcessStreaming Migration — COMPLETED

- Goal: Unified process execution model using event-driven handlers.
- Status: **COMPLETE as of December 18, 2025**
- Implementation:
  - All process execution uses `RsyncProcessStreaming` package
  - Simplified handler creation via `ProcessHandlers` factory with built-in cleanup hooks
  - Event handlers: `processOutput`, `processTermination`; optional file handler toggle per use case
  - Strong reference patterns with explicit post-termination cleanup to avoid leaks
  - Streaming output enables real-time progress updates
- Files updated:
  - [RsyncUI/Model/Execution/EstimateExecute/Estimate.swift](RsyncUI/Model/Execution/EstimateExecute/Estimate.swift)
  - [RsyncUI/Model/Execution/EstimateExecute/Execute.swift](RsyncUI/Model/Execution/EstimateExecute/Execute.swift)
  - [RsyncUI/Views/Restore/RestoreTableView.swift](RsyncUI/Views/Restore/RestoreTableView.swift)
  - [RsyncUI/Views/Detailsview/OneTaskDetailsView.swift](RsyncUI/Views/Detailsview/OneTaskDetailsView.swift)
  - [RsyncUI/Views/VerifyRemote/ExecutePushPullView.swift](RsyncUI/Views/VerifyRemote/ExecutePushPullView.swift)
  - [RsyncUI/Views/VerifyTasks/VerifyTasks.swift](RsyncUI/Views/VerifyTasks/VerifyTasks.swift)
- Impact: Code quality score improved to 9.4/10, unified streaming process architecture with simpler lifecycle

---

## [H] 1) Extract RsyncOutputProcessing Swift Package

- Goal: Isolate rsync output parsing/processing into a reusable Swift Package.
- Move (sources):
  - [RsyncUI/Model/Utils/PrepareOutputFromRsync.swift](RsyncUI/Model/Utils/PrepareOutputFromRsync.swift)
  - [RsyncUI/Model/Output/TrimOutputFromRsync.swift](RsyncUI/Model/Output/TrimOutputFromRsync.swift)
  - [RsyncUI/Model/Output/TrimOutputForRestore.swift](RsyncUI/Model/Output/TrimOutputForRestore.swift)
- Update imports in callers:
  - [RsyncUI/Model/Execution/EstimateExecute/Execute.swift](RsyncUI/Model/Execution/EstimateExecute/Execute.swift)
  - [RsyncUI/Views/VerifyRemote/ExecutePushPullView.swift](RsyncUI/Views/VerifyRemote/ExecutePushPullView.swift)
  - [RsyncUI/Views/VerifyTasks/VerifyTasks.swift](RsyncUI/Views/VerifyTasks/VerifyTasks.swift)
- Public API (minimal):
  - `PrepareOutputFromRsync.prepareOutputFromRsync(_:) -> [String]` (filters + tail N)
  - `TrimOutputFromRsync.checkForRsyncError(_:) throws` (detects "rsync error:")
  - Restore trim type exposing `trimmeddata`
- Acceptance Criteria:
  - Package builds standalone + under app
  - All references update cleanly; no regressions in Verify/Execute/Estimate flows
  - No UI dependencies in the package

---

## [H] 2) Add Unit Tests for Output Processing

- Scope (RsyncOutputProcessingTests):
  - 20-line tail trimming
  - Directory line filter (exclude trailing "/")
  - Error detection via `checkForRsyncError` (throws on "rsync error:")
  - Restore trimming shape (prefixing, whitespace normalization)
  - Malformed/empty output handling
- Fixtures: Add realistic rsync outputs to test bundle.
- Acceptance Criteria:
  - Tests run/passing locally (and in CI when added)
  - Edge cases covered (<= N lines, all directories, mixed content)

---

## [M] 3) Introduce Error Telemetry Hooks

- Goal: Count default-stats fallbacks and rsync error occurrences without user alerts.
- Add counters (example): `statsFallbackCount`, `rsyncErrorCount` (location TBD — small struct or on SharedReference).
- Increment when:
  - Default stats are appended in [RsyncUI/Model/Execution/EstimateExecute/Execute.swift](RsyncUI/Model/Execution/EstimateExecute/Execute.swift)
  - Errors are swallowed due to `SharedReference.shared.silencemissingstats`
- Log via OSLog at `info` (no UI alert). Optionally surface in Log View.
- Acceptance Criteria:
  - Counters increment deterministically; do not regress performance
  - Toggle `silencemissingstats` influences alerts but still logs counts

---

## [M] 4) Extract Magic Constants

- Centralize thresholds and paths:
  - Replace hardcoded `20` checks with `SharedReference.shared.alerttagginglines` (verify in):
    - [RsyncUI/Views/VerifyRemote/ExecutePushPullView.swift](RsyncUI/Views/VerifyRemote/ExecutePushPullView.swift)
    - [RsyncUI/Views/VerifyTasks/VerifyTasks.swift](RsyncUI/Views/VerifyTasks/VerifyTasks.swift)
    - [RsyncUI/Model/Execution/EstimateExecute/Execute.swift](RsyncUI/Model/Execution/EstimateExecute/Execute.swift)
    - [RsyncUI/Model/Utils/PrepareOutputFromRsync.swift](RsyncUI/Model/Utils/PrepareOutputFromRsync.swift)
  - Widget sandbox path string in:
    - [RsyncUI/Model/Storage/Widgets/WriteWidgetsURLStringsJSON.swift](RsyncUI/Model/Storage/Widgets/WriteWidgetsURLStringsJSON.swift)
  - Log file size limit already in:
    - [RsyncUI/Model/Global/SharedConstants.swift](RsyncUI/Model/Global/SharedConstants.swift)
- Acceptance Criteria:
  - No raw literals left for these concerns; single source of truth

---

## [M] 5) Standardize Optional Handling Patterns — MOSTLY DONE

- Applied patterns:
  - Guard-chain flattening
  - Single binding for counts
  - Single resolution for sentinel values
- Files updated:
  - [RsyncUI/Model/Execution/EstimateExecute/Estimate.swift](RsyncUI/Model/Execution/EstimateExecute/Estimate.swift) — guard chain for ID/config/arguments
  - [RsyncUI/Views/VerifyRemote/ExecutePushPullView.swift](RsyncUI/Views/VerifyRemote/ExecutePushPullView.swift) — `let lines = …` and shared threshold
  - [RsyncUI/Model/Execution/EstimateExecute/Execute.swift](RsyncUI/Model/Execution/EstimateExecute/Execute.swift) — `resolvedHiddenID` single binding
- Remaining: Continue replicating patterns in remaining `?? -1` sentinel usages (~30+ locations).
- **Updated Note (Dec 18):** RsyncProcessStreaming handlers now use strong capture (no `[weak self]`) to maintain process lifetime.

---

## [H] 6) CI: SwiftLint + Build Workflow

- Add `.github/workflows/ci.yml` to run:
  - SwiftLint
  - `xcodebuild -scheme RsyncUI build` on macOS-latest (cache DerivedData)
- Fail on lint violations; optional matrix for Xcode versions.
- Acceptance Criteria:
  - CI is green on clean main; blocks PRs with lint or build failures

---

## [M] 7) Enable Sanitizers in Debug Schemes

- Turn on Address/Thread Sanitizers for Debug (App + XPC).
- Run smoke paths for Estimate/Execute to catch hidden issues.
- Acceptance Criteria:
  - No sanitizer crashes in core paths under typical usage

---

## [M] 8) Deep Link & Widget Tests — PARTIAL (Dec 19)

- Add tests for:
  - [RsyncUI/Model/Deeplink/DeeplinkURL.swift](RsyncUI/Model/Deeplink/DeeplinkURL.swift): profile validation, no ongoing action, `externalURL` casing
  - Widget URL JSON roundtrip:
    - [RsyncUI/Model/Storage/Widgets/WriteWidgetsURLStringsJSON.swift](RsyncUI/Model/Storage/Widgets/WriteWidgetsURLStringsJSON.swift)
    - [WidgetEstimate/WidgetEstimate.swift](WidgetEstimate/WidgetEstimate.swift)
- Status update (Dec 19): Added RsyncUITests coverage for DeeplinkURL creation and configuration validation in [RsyncUITests/RsyncUITests.swift](RsyncUITests/RsyncUITests.swift); widget JSON roundtrip still pending.
- Acceptance Criteria:
  - Deterministic tests validating URL generation and parsing

---

## [M] 9) Docs Refresh After Extraction

- README: Add RsyncOutputProcessing box to architecture diagram
- Update:
  - [CODE_QUALITY_ANALYSIS.md](CODE_QUALITY_ANALYSIS.md) (Key Achievements)
  - [CHANGELOG_2.8.2rc2.md](CHANGELOG_2.8.2rc2.md) (package + tests)
- Acceptance Criteria:
  - Docs reflect package structure and new tests

---

## [Opt] 10) Extract RsyncConfiguration Package

- Candidates:
  - [RsyncUI/Model/Storage/Basic/SynchronizeConfiguration.swift](RsyncUI/Model/Storage/Basic/SynchronizeConfiguration.swift)
  - [RsyncUI/Model/Storage/Basic/UserConfiguration.swift](RsyncUI/Model/Storage/Basic/UserConfiguration.swift)
  - JSON decoders/encoders under `Model/Storage/Basic/JSON/`
- Benefits: Reuse and stronger testability for config layer.
- Acceptance Criteria:
  - Package builds + tests; app compiles with package imports

---

## [✓] 11) RsyncUITests Expansion — COMPLETED (Dec 19)

- Added suites in [RsyncUITests/RsyncUITests.swift](RsyncUITests/RsyncUITests.swift):
  - Arguments generation (`ArgumentsSynchronize` dry-run, keepdelete, syncremote)
  - Deeplink URL creation (`createURLestimateandsynchronize` default/custom profile)
  - Configuration validation (`VerifyConfiguration` for local/remote and syncremote tasks)
- Framework: Using `@Suite` and `@Test` from `Testing` with `@MainActor` isolation
- Acceptance: Tests pass locally and document intended behaviors for critical paths

---

## Notes

- Keep SwiftLint rules for `force_unwrapping` and `force_cast` enabled.
- Prefer `SharedReference.shared.alerttagginglines` over hardcoded thresholds.
- Document optional-handling patterns in `CODE_QUALITY_ANALYSIS.md` to guide contributions.
- **Process Execution Pattern (Dec 19):** Use strong capture in RsyncProcessStreaming closures with explicit post-termination cleanup to release handlers/process references.
- **Code Quality (Dec 19):** Score 9.4/10 with simplified streaming lifecycle and expanded test coverage.
