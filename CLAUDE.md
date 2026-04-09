# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Do not make any changes until you have 95% confidence in what you need to build. Ask me follow-up questions until you reach that confidence.

## What This Project Is

RsyncUI is a SwiftUI-based macOS GUI for [rsync](https://github.com/WayneD/rsync). It organizes synchronization tasks, configures rsync parameters, and wraps the rsync CLI in a native macOS application. Requires macOS Sonoma or later. Bundle ID: `no.blogspot.RsyncUI`.

## Skills

Use these skills for the relevant work in this repo:

- `/swift-concurrency` — when writing or reviewing Swift concurrency code (actors, async/await, Sendable, task groups)
- `/swift-testing-expert` — when writing or reviewing Swift Testing framework tests
- `/swiftui-expert-skill` — when writing or reviewing SwiftUI views


## Build Commands

**Debug build** (no notarization/signing):
```bash
make debug
```

**Release build** (archive → notarize → sign → DMG):
```bash
make build
```

**ARM64 release:**
```bash
make -f Makefile-arm64 build
```

Build output lands in `./build/`. The release workflow requires a keychain profile named `"RsyncUI"` for notarization and team ID `93M47F4H9T` for signing.

## Tests

Tests use **Swift Testing** (Xcode 16+), not XCTest.

```bash
# Run all tests
swift test

# Run a specific suite
swift test --filter VerifyConfigurationTests

# Run a specific test
swift test --filter VerifyConfigurationTests/validLocalSynchronization
```

In Xcode: `Cmd+U`. Test files live in `RsyncUITests/`.

Tests that share mutable state use `@Suite(.serialized)`. Use `SharedReference.shared` directly in tests; reset it after with `SharedReference.shared.reset()`.

## Linting

SwiftLint is configured in `.swiftlint.yml`:
- Line length: 135
- Type body length: 320 lines
- Function body length: 80 lines
- Opt-in: `implicit_return`, `force_unwrapping`, `force_cast`, `sorted_imports`, `unused_declaration`, and others

SwiftFormat is configured in `.swiftformat` targeting Swift 6 with OTBS (not Allman) braces.

Dead code is tracked via Periphery (`.periphery.yml`), indexed against the `RsyncUI` scheme.

## Architecture

### Source Layout

```
RsyncUI/
├── Main/          # App entry point, root view, window setup
├── Views/         # All SwiftUI views, organized by feature
└── Model/         # Business logic, data, and execution
    ├── Global/    # Shared state (SharedReference singleton)
    ├── Storage/   # JSON persistence via actors
    ├── Execution/ # Rsync process orchestration
    ├── ProcessArguments/  # Rsync CLI argument construction
    ├── Output/    # Rsync output parsing
    ├── Schedules/ # Scheduled task logic
    ├── Snapshots/ # Snapshot support
    ├── Ssh/       # SSH key/config management
    └── Deeplink/  # URL-based deep linking
```

### State Management

`SharedReference` (in `Model/Global/`) is a `@Observable` singleton holding app-wide state: rsync version, active profile, and feature flags. Views receive it via the environment or direct reference. Local view state uses `@State`.

### Concurrency

Storage operations (JSON read/write) run on **actors**: `ActorReadSynchronizeConfigurationJSON`, `ActorLogToFile`, etc. All actor calls use `async/await`. Views initialize via `Task { }` blocks, never blocking the main thread.

### Rsync Execution Pipeline

1. **ProcessArguments** — builds the rsync argument array for a configuration
2. **EstimateExecute** — runs a dry-run first, then the real sync
3. **RsyncProcessStreaming** (SPM package) — streams live stdout/stderr to the UI
4. **ParseRsyncOutput / RsyncAnalyse** (SPM packages) — parse and interpret output
5. **ProgressDetails** — feeds parsed output into the progress view

### External SPM Packages

All packages are owned by `rsyncOSX` and track `main`:

| Package | Purpose |
|---|---|
| `RsyncArguments` | Rsync argument generation |
| `RsyncProcessStreaming` | Streaming process output |
| `ParseRsyncOutput` | Output line parsing |
| `RsyncAnalyse` | Output analysis/stats |
| `ProcessCommand` | Process execution utilities |
| `SSHCreateKey` | SSH key generation |
| `DecodeEncodeGeneric` | Generic Codable helpers |
| `RsyncUIDeepLinks` | Deep link URL definitions |

### Data Persistence

Configurations, logs, and user settings are stored as JSON in the user's Application Support directory. Each profile maps to a subdirectory. The `Storage/Actors/` layer wraps all file I/O in actors so reads and writes never race.

### Configuration Validation

`VerifyConfiguration` (in `Model/`) validates a task before saving: checks that local and remote catalogs are non-empty, SSH fields are consistent (server ↔ username), trailing slash policy, and that snapshots/syncremote require rsync v3.
