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
- Performed a deeper source review of the execution, streaming callback, restore, snapshot, scheduling, logging, profile-loading, SwiftUI state, and widget paths.
- Checked SwiftUI modernization patterns against the current API guidance for macOS 14+ / Swift 6.
- Ran:

```bash
xcodebuild test -project RsyncUI.xcodeproj -scheme RsyncUI -destination 'platform=macOS'
```

Result on 2026-07-06: **passed**. The run executed **56 tests in 9 suites** and ended with `** TEST SUCCEEDED **`.

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

## Open issues by severity

Severity means fix priority, not certainty of user-visible failure:

- **High**: can execute the wrong command, mutate UI state off the main actor, corrupt important state, or hide a failed safety check.
- **Medium**: can cause incorrect behavior in less common flows, make async/process ordering fragile, or materially slow future changes.
- **Low**: cleanup, modernization, maintainability, or defensive hardening.

### Issue 1: argument validation errors do not stop execution

Severity: **High**

Evidence:

- `RsyncUI/Model/Execution/EstimateExecute/Execute.swift`

Both `startexecution()` and `startexecution_noestimate()` call `ValidateArguments().validate(...)`, show an alert on failure, and then continue to `process.executeProcess()`. If validation is enabled, a detected missing `--archive`, unexpected `--delete`, missing `--dry-run`, or wrong compression mode should be treated as a hard stop, not a warning.

Suggested fix:

Return immediately after propagating the validation error, or move validation into a helper that returns `Bool` and guard before process creation. Add tests around execution argument validation if process startup can be injected or wrapped.

### Issue 2: streaming cleanup mutates SwiftUI state from callback context

Severity: **High**

Evidence:

- `RsyncUI/Model/Execution/CreateHandlers/CreateStreamingHandlers.swift`
- `RsyncUI/Views/Restore/RestoreTableView.swift`
- `RsyncUI/Views/Quicktask/extensionQuickTaskView.swift`
- `RsyncUI/Views/Detailsview/OneTaskDetailsView.swift`
- `RsyncUI/Views/InspectorViews/VerifyTask/VerifyTaskTabView.swift`

`CreateStreamingHandlers.createHandlersWithCleanup(...)` invokes `cleanup()` directly after the process-termination callback. The same file documents and debug-checks that streaming callbacks may execute off the main thread. The current cleanup closures mutate SwiftUI `@State` (`activeStreamingProcess = nil`, `streamingHandlers = nil`) directly. Under Swift 6 strict concurrency this is a real actor-isolation/data-race risk and can also produce runtime UI-state warnings.

Suggested fix:

Make cleanup main-actor isolated at the boundary. The helper can wrap cleanup in `Task { @MainActor in cleanup() }`, or require `@MainActor @escaping () -> Void` and invoke it via a main-actor hop. Avoid doing cleanup both in the helper and again in `processTermination` unless ordering is intentionally documented.

### Issue 3: failed log persistence is silently swallowed after execution

Severity: **Medium**

Evidence:

- `RsyncUI/Model/Execution/EstimateExecute/Execute.swift`
- `RsyncUI/Model/Loggdata/Logging.swift`

After all tasks complete, both execution paths call `update.addLogToPermanentStore(...)` and use `catch { return }`. `Logging.addLogToPermanentStore(...)` can throw `LogError.insertionFailed(ids:)`, but the caller does not surface the failure, log it, or keep a recovery marker. A sync can appear successful while the summary log was not recorded.

Suggested fix:

Log the failed IDs through `Logger.process` and show an alert only when summary logging was explicitly requested. Add a focused test for `Logging.addLogToPermanentStore(...)` failure propagation and one caller-level test if execution dependencies become injectable.

### Issue 4: `InterruptProcess` still performs work in `init`

Severity: **Medium**

Evidence:

- `RsyncUI/Model/Process/InterruptProcess.swift`
- Call sites include restore, snapshots, quick task, estimation, and task execution views.

`InterruptProcess` is still a `@MainActor` type whose initializer launches a `Task`, writes an interrupt log, interrupts the active process, and clears `SharedReference.shared.process`. Construction with side effects makes ordering hard to reason about, especially from toolbar/menu focus actions where users expect "abort now" semantics.

Suggested fix:

Replace it with a named async API, for example `ProcessInterruptService.interruptCurrentProcess() async`. Synchronous UI actions can call it with `Task { await ... }`. Keep the process clearing and log write in one explicit function.

### Issue 5: profile and configuration loading is still duplicated

Severity: **Medium**

Evidence:

- `RsyncUI/Main/RsyncUIView.swift`
- `RsyncUI/Views/Sidebar/extensionSidebarMainView.swift`
- `RsyncUI/Views/Configurations/ConfigurationsTableLoadDataView.swift`
- `RsyncUI/Model/Utils/ReadAllTasks.swift`

JSON mechanics are centralized, but app-level loading is still spread across the app. Each caller decides how to resolve profile IDs, default profile names, nil versus empty arrays, rsync v3 filtering, and all-profile ordering.

Suggested fix:

Create a small `ProfileConfigurationService` or `ConfigurationRepository` that owns default-profile loading, named-profile loading, all-profile loading, profile ID/name resolution, rsync v3 filtering, and empty-result behavior.

### Issue 6: log-result parsing remains duplicated

Severity: **Medium**

Evidence:

- `RsyncUI/Model/Loggdata/Logging.swift`
- `RsyncUI/Model/Loggdata/LogChartService.swift`

Both files parse numbers from log result strings. `Logging` validates whether a result can be persisted; `LogChartService` interprets the same shape for chart data. Any future change to log text, snapshot prefixes, units, or decimal handling has to be updated in both places.

Suggested fix:

Extract shared log-result parsing into one helper used by both permanent log insertion and chart generation. Add tests for regular sync log results, snapshot-prefixed log results, invalid strings, and decimal transferred-size values.

### Issue 7: schedule responsibilities are still mixed

Severity: **Medium**

Evidence:

- `RsyncUI/Model/Global/ObservableSchedules.swift`
- `RsyncUI/Model/Global/GlobalTimer.swift`
- `RsyncUI/Model/Storage/ReadSchedule.swift`
- `RsyncUI/Model/Storage/WriteSchedule.swift`

Scheduling is better tested now, but `ObservableSchedules` still performs date generation, validation, persistence shaping, global timer mutation, and callback setup. `GlobalTimer` still owns timer setup, wake recovery, missed schedule handling, and execution callbacks. This makes wake/recompute changes risky.

Suggested fix:

Split into `SchedulePlanner` for pure future-date generation and validation, `ScheduleStore` for JSON persistence through shared storage, `ScheduleRunner` for timers/wake recovery/execution callbacks, and keep `ObservableSchedules` as the SwiftUI adapter. Keep the existing tests and add focused tests for wake recovery ordering and duplicate prevention by task identity plus scheduled date.

### Issue 8: snapshot log assembly still lives partly in the view flow

Severity: **Medium**

Evidence:

- `RsyncUI/Views/Snapshots/SnapshotsView.swift`
- `RsyncUI/Model/Snapshots/Snapshotlogsandcatalogs.swift`

`SnapshotsView.loadSnapshotData(for:)` loads log records and directly creates `Snapshotlogsandcatalogs`, while `Snapshotlogsandcatalogs` merges remote snapshot catalogs with log records and calculates unused log IDs. This leaves domain policy split between a view and a model helper.

Suggested fix:

Move snapshot log assembly, unused-log calculation, and remote catalog merge policy behind a snapshot-domain service. Keep `SnapshotsView` focused on selection, commands, and presentation state.

### Issue 9: some command builders silently discard argument-construction errors

Severity: **Low**

Evidence:

- `RsyncUI/Model/ParametersRsync/ArgumentsRemoteFileList.swift`
- `RsyncUI/Model/ParametersRsync/ArgumentsSynchronize.swift`
- `RsyncUI/Model/ParametersRsync/ArgumentsVerify.swift`
- `RsyncUI/Model/ParametersRsync/ArgumentsSnapshotRemoteCatalogs.swift`

Several parameter builders use empty `catch {}` blocks and return nil/partial results. This keeps the UI flowing, but it makes command-generation failures harder to diagnose and can collapse distinct errors into "nothing happened".

Suggested fix:

Return typed errors from argument builders, or log the underlying error before returning nil. Prefer a single user-facing alert at the action boundary rather than multiple alerts from low-level builders.

### Issue 10: SwiftUI local state visibility is inconsistent

Severity: **Low**

Evidence:

- Many views still declare local state as `@State var` or `@FocusState var` instead of `private`, including `TasksView`, `QuicktaskView`, `AddTaskView`, `SidebarMainView`, `RestoreTableView`, and `ExportView`.

SwiftUI-owned local state should generally be private. This is not a release blocker, but it weakens view encapsulation and makes accidental external mutation easier during future refactors.

Suggested fix:

Run a focused SwiftUI cleanup pass converting local `@State` and `@FocusState` to `private` where the property is not intentionally used by same-file extensions. For properties used from extensions, either keep the current access or move related code into the main type before privatizing.

## Enhancement candidates

### Enhancement 1: SwiftUI modernization pass

Priority: **Low**

The current code still contains older SwiftUI patterns such as positional `Section(header:)` initializers and tappable labels implemented with `onTapGesture` in `TimerView` and calendar day views. These are not release blockers because the app builds and tests pass, but a focused pass would reduce soft-deprecation noise and improve accessibility by using `Button` where the element is an action.

### Enhancement 2: standardize debounced search/filter handling

Priority: **Low**

Multiple views implement similar debounce patterns with `Task.sleep`, manual cancellation, or `.task(id:)`, including restore file search, log-record search, quick-task catalog search, sidebar status messages, and list filtering. A tiny reusable debounce helper or consistent `.task(id:)` pattern would reduce duplicated timing code.

### Enhancement 3: add boundary tests around process-start decisions

Priority: **Medium**

The existing Swift Testing suite is solid around pure validation, storage, logs, schedules, and argument construction, but the riskiest findings are in process-start decision logic. A small process runner protocol or wrapper would allow tests for "validation failed, process not started", "norsync prevents start", "halted task prevents start", and "completion persists logs or reports failure".

### Enhancement 4: document streaming callback actor boundaries

Priority: **Medium**

The app relies on `RsyncProcessStreaming` callbacks that can arrive off the main actor. Documenting the callback contract in one place and making `CreateStreamingHandlers` the only bridge into main-actor UI state would make future strict-concurrency fixes smaller and safer.

### Enhancement 5: split remaining large mixed-responsibility files

Priority: **Low**

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

1. Fix the two high-severity execution/concurrency issues.
2. Extract shared log-result parsing.
3. Add the profile/configuration loading service.
4. Replace `InterruptProcess` initializer side effects with a named async service.
5. Split schedule planner/store/runner responsibilities while keeping existing schedule tests green.
6. Move snapshot log assembly into a snapshot service.
7. Split `Execute.swift` after completion/logging service boundaries are stable.

## Suggested execution order

1. Fix `Execute` so validation failure prevents `executeProcess()`.
2. Fix `CreateStreamingHandlers.createHandlersWithCleanup(...)` so cleanup happens on the main actor.
3. Surface/log summary-log persistence failures after execution.
4. Add process-start decision tests via a small process runner abstraction.
5. Extract shared log-result parsing and add tests.
6. Add `ProfileConfigurationService` / `ConfigurationRepository`.
7. Replace `InterruptProcess` initializer side effects with a named async service.
8. Split schedule planner/store/runner responsibilities while keeping existing schedule tests green.
9. Move snapshot log assembly into a snapshot service.
10. Run the Xcode test command and record the result in release notes.
