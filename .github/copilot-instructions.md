# Copilot Instructions for RsyncUI

RsyncUI is a SwiftUI macOS app for `rsync`. Target macOS Sonoma or later.

## Build, test, and lint

```bash
# Debug build (no notarization/signing)
make debug

# Release build (archive -> notarize -> staple -> DMG)
make build

# Apple Silicon release build
make -f Makefile-arm64 build

# Run all Swift Testing suites
swift test

# Run one test suite
swift test --filter VerifyConfigurationTests

# Run one test
swift test --filter VerifyConfigurationTests/validLocalSynchronization

# Lint / format
swiftlint
swiftformat .
```

## High-level architecture

- `RsyncUI/Main/` owns app startup. `RsyncUIApp` wires windows, commands, settings, and shutdown cleanup. `RsyncUIView` bootstraps user config, rsync version detection, profile discovery, and task loading for the selected profile.
- `Model/Global/SharedReference.swift` is the central shared state object for rsync capabilities, active process state, validation flags, SSH defaults, and shared error propagation.
- Task data is stored as JSON under `~/.rsyncosx/<mac-serial>/`, with one subdirectory per profile. `Homepath` computes paths, `Read...JSON` loads them, and write paths such as `WriteSynchronizeConfigurationJSON` encode on the main actor and write off-thread.
- The rsync flow is: build arguments in `Model/ParametersRsync/` and `Model/ProcessArguments/`, estimate with dry-run in `Model/Execution/EstimateExecute/Estimate.swift`, execute in `.../Execute.swift`, stream output with `RsyncProcessStreaming`, parse with `ParseRsyncOutput` / `RsyncAnalyse`, then feed UI state through `ProgressDetails`.
- Features are organized by domain: schedules, snapshots, SSH, deeplinks, and matching SwiftUI feature folders in `RsyncUI/Views/`.

## Key conventions

- The app uses SwiftUI Observation (`@Observable`) heavily, and many stateful types are also `@MainActor`. Prefer `.task {}` / `Task {}` for async startup and follow the existing main-actor boundaries.
- Tests use **Swift Testing**, not XCTest. Shared-state suites are usually `@Suite(.serialized)` and tagged by feature such as `.validation`, `.arguments`, and `.deeplink`.
- If a test mutates `SharedReference.shared`, restore or reset it before the test exits. Existing tests usually save the original value and `defer` restoration.
- Create and update task configs through `VerifyConfiguration`; it owns trailing-slash normalization, SSH field consistency, snapshot / syncremote rsync-v3 checks, and remote connectivity validation.
- Profile switching is disk-backed: selecting a profile reloads that profile's configuration JSON instead of relying on a long-lived in-memory store.
- Execution paths surface errors through `SharedReference.shared.errorobject?.alert(error:)` and validate generated rsync arguments when `SharedReference.shared.validatearguments` is enabled.
- The Xcode project depends on `rsyncOSX` packages including `RsyncArguments`, `RsyncProcessStreaming`, `ParseRsyncOutput`, `RsyncAnalyse`, `ProcessCommand`, `DecodeEncodeGeneric`, `SSHCreateKey`, and `RsyncUIDeepLinks`; check those boundaries before re-implementing logic locally.
- Build output goes to `./build/`. Release targets assume a notarization keychain profile named `RsyncUI` and signing team ID `93M47F4H9T`.
