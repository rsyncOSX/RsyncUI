# RsyncUI issues and cleanup tracker

Prepared: 2026-07-06

## Scope

This document merges and replaces:

- `documents/ver293_ver297.md`
- `documents/version300.md`

It removes duplicate background material, marks verified completed work explicitly, and records the remaining issues found by checking the current codebase. The current project version in `RsyncUI.xcodeproj/project.pbxproj` is `3.0.2` with build number `196`.

## Verification performed

- Reviewed the two source documents and current repository files.
- Checked Xcode project settings for Swift version, concurrency, deployment target, marketing version, and build number.
- Checked current implementations of storage, logging, scheduling, profile loading, snapshot loading, process interruption, execution, and tests.
- Ran:

```bash
xcodebuild test -project RsyncUI.xcodeproj -scheme RsyncUI -destination 'platform=macOS'
```

Result: **passed**. The run executed **56 tests in 9 suites** and ended with `** TEST SUCCEEDED **`.

## Completed items

### Completed: Xcode-based validation works

The correct validation command is the Xcode project test command above. It builds the app, widget extension, SPM dependencies, and `RsyncUITests`, then runs the Swift Testing test bundle successfully.

Current coverage includes:

- `ArgumentsSynchronizeTests`
- `DeeplinkURLTests`
- `ItemizedOutputTests`
- `LogChartReducerTests`
- `LogStoreServiceTests`
- `ObservableSchedulesTests`
- `SharedJSONStorageTests`
- `VerifyConfigurationAdvancedTests`
- `VerifyConfigurationTests`

### Completed: JSON persistence mechanics are centralized

Shared JSON persistence now routes through:

- `RsyncUI/Model/Storage/SharedJSONStorageReader.swift`
- `RsyncUI/Model/Storage/SharedJSONStorageWriter.swift`

The remaining `Task.detached` uses in these files are intentional infrastructure-level work. They are awaited and used to move file I/O and JSON decoding off the caller actor.

Correct rule going forward:

> Avoid ad hoc fire-and-forget detached persistence. Detached work is acceptable inside shared infrastructure when its result is awaited and errors propagate.

### Completed: log table, chart, and delete reads are service based

Log loading, visible-log filtering, date/result search, delete-and-persist behavior, and chart entry creation now route through:

- `RsyncUI/Model/Loggdata/LogStoreService.swift`
- `RsyncUI/Model/Loggdata/LogChartService.swift`

The old chart/log helper actors and observable chart data layer were removed. Dedicated tests cover log filtering, delete behavior, chart reduction, and shared storage.

### Completed: app-wide log-file actor is centralized

Execution and output paths now use `ActorLogToFile.shared`, avoiding separate actor instances for reads and writes. This keeps app log-file access serialized through one shared actor.

### Completed: estimate and execute startup is more explicit

The estimate/execute cleanup from the v2.9.x reports has landed:

- `Estimate.start(...)` and `Execute.start(...)` provide named startup entry points.
- Execution completion and reference cleanup were pulled into helper methods.
- Completion logging uses the async `Logging.create(...)` path.
- `SharedReference.shared.process` is explicitly cleared on completion paths.

### Completed: schedule reliability has test coverage and wake-move fix

`RsyncUITests/ObservableSchedulesTests.swift` now covers schedule deletion, duplicate prevention on recompute/reload, date horizon behavior across December/January, invalid date rejection, and validation against edited planned run values.

`GlobalTimer.moveToSchedules(itemIDs:)` now updates moved missed schedules in place so changed dates are not lost through value-copy mutation.

### Completed: itemized rsync output has tests

`RsyncUITests/ItemizedOutputTests.swift` covers rsync itemized-output classification, openrsync output shape, and insertion of `--itemize-changes`.

### Completed: release Makefiles derive the app version

`Makefile` and `Makefile-arm64` derive `VERSION` from `MARKETING_VERSION` in the Xcode project instead of hardcoding a duplicate version string.

## Open issues

### Issue 1: profile and configuration loading is still duplicated

JSON mechanics are centralized, but application-level loading is still spread across:

- `RsyncUI/Main/RsyncUIView.swift`
- `RsyncUI/Views/Sidebar/extensionSidebarMainView.swift`
- `RsyncUI/Views/Configurations/ConfigurationsTableLoadDataView.swift`
- `RsyncUI/Model/Utils/ReadAllTasks.swift`

Suggested fix:

Create a small `ProfileConfigurationService` or `ConfigurationRepository` that owns:

- resolving profile name from `ProfilesnamesRecord.ID`
- loading the default profile
- loading a named profile
- loading all profiles while preserving profile order
- applying rsync v3 filtering consistently
- returning empty arrays consistently instead of requiring each caller to choose nil/empty behavior

### Issue 2: `InterruptProcess` still performs work in `init`

`RsyncUI/Model/Process/InterruptProcess.swift` is still a `@MainActor` struct whose initializer launches a `Task`, writes an interrupt log, interrupts the active process, and clears `SharedReference.shared.process`.

That hides side effects behind construction and makes ordering harder to reason about at call sites.

Suggested fix:

Replace it with a named async API, for example `ProcessInterruptService.interruptCurrentProcess() async`, and use `Task { await ... }` only from synchronous UI actions.

### Issue 3: log-result parsing remains duplicated

Number parsing and log-result validation are still duplicated in:

- `RsyncUI/Model/Loggdata/Logging.swift`
- `RsyncUI/Model/Loggdata/LogChartService.swift`

Suggested fix:

Extract shared log-result parsing into one helper used by both permanent log insertion and chart generation. Add tests for regular sync log results, snapshot-prefixed log results, invalid strings, and decimal transferred-size values.

### Issue 4: schedule responsibilities are still mixed

Scheduling is better tested now, but responsibilities are still concentrated in:

- `RsyncUI/Model/Global/ObservableSchedules.swift`
- `RsyncUI/Model/Global/GlobalTimer.swift`
- `RsyncUI/Model/Storage/ReadSchedule.swift`
- `RsyncUI/Model/Storage/WriteSchedule.swift`

`ObservableSchedules` still performs date generation, validation, schedule persistence shaping, global timer mutation, and callback setup. `GlobalTimer` still owns timer setup, wake recovery, missed schedule handling, and execution callbacks.

Suggested fix:

Split into:

- `SchedulePlanner`: pure future-date generation and validation.
- `ScheduleStore`: read/write schedule JSON through shared storage.
- `ScheduleRunner`: timer setup, callback execution, wake recovery, and missed schedule movement.
- `ObservableSchedules`: a thin SwiftUI adapter.

Keep the existing tests and add focused tests for wake recovery ordering and duplicate prevention by task identity plus scheduled date.

### Issue 5: snapshot log assembly still lives partly in the view flow

`SnapshotsView.loadSnapshotData(for:)` loads log records and directly creates `Snapshotlogsandcatalogs`, while `Snapshotlogsandcatalogs` merges remote snapshot catalogs with log records and calculates unused log IDs.

Suggested fix:

Move snapshot log assembly, unused-log calculation, and remote catalog merge policy behind a snapshot-domain service. Keep `SnapshotsView` focused on selection, commands, and presentation state.

### Issue 8: large mixed-responsibility files remain

The remaining hotspots are:

- `RsyncUI/Model/Execution/EstimateExecute/Execute.swift`
- `RsyncUI/Views/Sidebar/SidebarMainView.swift`
- `RsyncUI/Views/Tasks/LogStatsChartView.swift`
- `RsyncUI/Views/Snapshots/SnapshotsView.swift`
- `RsyncUI/Views/Restore/RestoreTableView.swift`
- `RsyncUI/Views/Configurations/ConfigurationsTableDataMainView.swift`
- `RsyncUI/Model/Global/ObservableSchedules.swift`
- `RsyncUI/Model/Global/GlobalTimer.swift`

Suggested order:

1. Extract shared log-result parsing.
2. Add the profile/configuration loading service.
3. Extract schedule planner/store/runner boundaries.
4. Move snapshot log assembly into a service.
5. Split `Execute.swift` after completion/logging service boundaries are stable.

## Lower-priority cleanup candidates

### SwiftUI modernization pass

The current code still contains several older SwiftUI patterns, including positional `Section(header:)` initializers and some `onTapGesture` interactions that could become `Button`s. These are not release blockers because the app builds and tests pass, but a focused SwiftUI cleanup pass would reduce future soft-deprecation noise.

### Task entry isolation review

There are many unstructured `Task { @MainActor in ... }` and `Task { ... }` call sites. They are not all wrong, but a targeted pass should verify whether each task's synchronous prefix really needs main-actor inheritance. Keep the shared JSON detached tasks as-is unless a concrete issue is found.

## Suggested execution order

1. Fix `AGENTS.md` validation documentation.
2. Extract shared log-result parsing and add tests.
3. Add `ProfileConfigurationService` / `ConfigurationRepository`.
4. Replace `InterruptProcess` initializer side effects with a named async service.
5. Split schedule planner/store/runner responsibilities while keeping existing schedule tests green.
6. Move snapshot log assembly into a snapshot service.
7. Review Swift target settings for app, tests, and widget.
8. Update `versionRsyncUI/versionRsyncUI.json` if it is still the source for in-app update checks.
9. Re-run the Xcode test command and record the result in release notes.
