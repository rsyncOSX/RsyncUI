# RsyncUI TODO — December 25, 2025

This document tracks proposed next steps after v2.8.4rc2 release. Tasks are grouped by priority and include file indices and acceptance criteria.

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

## [✓] 1) Extract ParseRsyncOutput Swift Package — COMPLETED (Dec 9)

- Goal: ✅ Isolated rsync output parsing/processing into reusable Swift Package.
- Status: **COMPLETE as of December 9, 2025**
- Implementation:
  - Package: [ParseRsyncOutput](https://github.com/rsyncOSX/ParseRsyncOutput)
  - Integrated into RsyncUI via XCRemoteSwiftPackageReference
  - Files using ParseRsyncOutput:
    - [RsyncUI/Model/Execution/EstimateExecute/Execute.swift](RsyncUI/Model/Execution/EstimateExecute/Execute.swift)
    - [RsyncUI/Model/Execution/EstimateExecute/Estimate.swift](RsyncUI/Model/Execution/EstimateExecute/Estimate.swift)
    - [RsyncUI/Model/Execution/EstimateExecute/RemoteDataNumbers.swift](RsyncUI/Model/Execution/EstimateExecute/RemoteDataNumbers.swift)
- Impact: Reduced code duplication, improved testability, and shared rsync parsing logic across projects

---

## [✓] 2) Add Unit Tests for Output Processing — COMPLETED (Dec 9)

- Scope (ParseRsyncOutputTests): ✅ Complete
  - Tail trimming (20-line limit)
  - Directory line filtering (trailing "/" exclusion)
  - Error detection via rsync error patterns
  - Output formatting and whitespace handling
  - Malformed/empty output edge cases
- Fixtures: ✅ Realistic rsync outputs in [ParseRsyncOutput/TestData/](ParseRsyncOutput/TestData/)
  - [ver2.txt](ParseRsyncOutput/TestData/ver2.txt)
  - [ver3.txt](ParseRsyncOutput/TestData/ver3.txt)
  - [openrsync.txt](ParseRsyncOutput/TestData/openrsync.txt)
  - [command.txt](ParseRsyncOutput/TestData/command.txt)
- Status: Tests passing; comprehensive edge case coverage

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

## [M] 5) Standardize Optional Handling Patterns — SIGNIFICANT PROGRESS (Dec 22-25)

- Applied patterns:
  - Guard-chain flattening
  - Single binding for counts
  - Single resolution for sentinel values
  - Early returns for nil optionals
- Files updated:
  - [RsyncUI/Model/Execution/EstimateExecute/Estimate.swift](RsyncUI/Model/Execution/EstimateExecute/Estimate.swift) — guard chain for hiddenID with early return (Dec 22)
  - [RsyncUI/Model/Execution/EstimateExecute/Execute.swift](RsyncUI/Model/Execution/EstimateExecute/Execute.swift) — replaced `resolvedHiddenID = hiddenID ?? -1` with guard statements (Dec 22)
  - [RsyncUI/Views/VerifyRemote/ExecutePushPullView.swift](RsyncUI/Views/VerifyRemote/ExecutePushPullView.swift) — `let lines = …` and shared threshold
- Progress: Reduced from ~30+ to ~20 instances (33% reduction)
- Remaining: ~20 sentinel usages, primarily in:
  - SSH port handling (SharedReference.shared.sshport)
  - Configuration decoding (SynchronizeConfiguration, UserConfiguration)
  - Log records initialization
- **Updated Note (Dec 18):** RsyncProcessStreaming handlers now use strong capture (no `[weak self]`) to maintain process lifetime.
- **Updated Note (Dec 22):** Major refactoring of hiddenID handling eliminates sentinel pattern in critical execution paths.

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

## [✓] 9) Docs Refresh After Extraction — COMPLETED (Dec 21)

- README: ✅ Architecture updated to reflect ParseRsyncOutput package
- Updated:
  - [CODE_QUALITY_ANALYSIS_COMPREHENSIVE.md](CODE_QUALITY_ANALYSIS_COMPREHENSIVE.md) (Key Achievements)
  - [TODO.md](TODO.md) (Status for tasks 1-2)
- Status: Documentation reflects package structure and integrated tests

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
- **Code Quality (Dec 25):** Score 9.5/10 (↑ from 9.4) with sentinel value reduction, simplified streaming lifecycle and expanded test coverage. ParseRsyncOutput extraction adds architectural robustness.
- **Latest Updates (Dec 25):** v2.8.4rc2 released. Sentinel values reduced by 33% through hiddenID refactoring. UI feedback enhanced with ProgressView indicators. Code cleanup completed. ParseRsyncOutput package (Task 1) and unit tests (Task 2) verified as complete and integrated. Ready for continued enhancement on remaining priorities.
