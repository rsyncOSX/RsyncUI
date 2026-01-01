# RsyncUI TODO — December 29, 2025

This document tracks proposed next steps after v2.8.4. Tasks are grouped by priority and include acceptance criteria.

Legend: [H] High • [M] Medium • [L] Low • [Opt] Optional • [✓] Completed

---

## [✓] 0) RsyncProcessStreaming Migration — COMPLETED

- Goal: Unified process execution model using event-driven handlers.
- Status: COMPLETE (Dec 18, 2025)
- Notes: Strong references held during execution and released post-termination to avoid leaks. Real-time streaming output across Estimate/Execute and detail views.

---

## [✓] 1) Extract ParseRsyncOutput Swift Package — COMPLETED (Dec 9)

- Goal: Isolate rsync output parsing/processing into reusable Swift package.
- Status: COMPLETE
- Notes: Integrated via XCRemoteSwiftPackageReference; shared across projects.

---

## [✓] 2) Add Unit Tests for Output Processing — COMPLETED (Dec 9)

- Scope: Tail trimming (20-line limit), directory filtering, error detection, formatting, malformed/empty output.
- Fixtures: Realistic rsync outputs in ParseRsyncOutput/TestData/.

---

## [H] 3) Remove Sentinel Defaults (SSH & User Config)

- Goal: Eliminate `?? -1` sentinels for SSH ports and tri-state booleans; switch to optionals/enums with validation.
- Locations: ObservableParametersRsync (SSH fields), SSHParams, UserConfiguration decode/encode, any `sshport ?? -1` patterns.
- Acceptance: No sentinel magic numbers in SSH/config paths; validation errors surfaced via AlertError; tests cover nil/invalid ports and booleans.

---

## [M] 4) Introduce Error Telemetry Hooks

- Goal: Count default-stats fallbacks and rsync error detections without user alerts.
- Locations: Execute stats fallback paths; `silencemissingstats` branches; error detection callbacks.
- Acceptance: Counters increment deterministically; OSLog info-level breadcrumbs; no user-facing alerts added.

---

## [M] 5) Extract Magic Constants

- Goal: Centralize thresholds/paths (e.g., alerttagginglines, widget sandbox path).
- Acceptance: No raw literals for these concerns; single source of truth via SharedReference/SharedConstants.

---

## [H] 6) CI: SwiftLint + Build Workflow

- Goal: Add `.github/workflows/ci.yml` to run SwiftLint and `xcodebuild -scheme RsyncUI build` on macOS.
- Acceptance: CI must fail on lint/build errors; optional Xcode matrix; DerivedData cached.

---

## [H] 7) Streaming Execution & Tagging Tests

- Goal: Add automated coverage for Estimate/Execute streaming paths, tagging validation, interruption, and log persistence.
- Acceptance: Tests simulate >alerttagginglines outputs, interrupted processes, and log store success/failure; asserts handler cleanup (no retained processes).

---

## [M] 8) Enable Sanitizers in Debug Schemes

- Goal: Turn on Address/Thread Sanitizers for Debug (App + XPC) and run smoke paths for Estimate/Execute.
- Acceptance: No sanitizer crashes on common flows; document any suppressions.

---

## [M] 9) Deep Link & Widget Tests — PARTIAL

- Goal: Extend tests for DeeplinkURL validation and widget URL JSON roundtrip.
- Status: Deeplink creation tests exist; widget JSON roundtrip pending.
- Acceptance: Deterministic tests for URL generation/parsing and widget data persistence.

---

## [Opt] 10) Extract RsyncConfiguration Package

- Goal: Move configuration models/JSON coders to a reusable package.
- Acceptance: Package builds + tests; app compiles with package imports.

---

## [✓] 11) Docs Refresh — COMPLETED (Dec 21)

- Updated README and CODE_QUALITY_ANALYSIS_COMPREHENSIVE.md to reflect package structure and tests.

---

## Notes

- Keep SwiftLint force unwrap/cast bans; consider tightening cyclomatic/function length after sentinel cleanup lands.
- Prefer `SharedReference.shared.alerttagginglines` over hardcoded thresholds.
- Use strong-capture streaming handlers with explicit post-termination cleanup to avoid leaks.
