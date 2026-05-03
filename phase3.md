# Phase 3 - Concurrency cleanup

This file expands `cleanup.md` Phase 3 with current progress from the codebase and recent git history. The goal of Phase 3 is to remove accidental concurrency, keep only correctness-critical async boundaries, and reduce the log-data pipeline to a smaller set of actors and helpers that are easier to reason about.

## 1. Current-state summary

- **Done - 3A. Log-data actor reduction:** `cleanup.md` originally kept three log-data actors: `ActorLogToFile`, `ActorReadLogRecordsJSON`, and `ActorLogChartsData`. The current tree is down to two actor files: `ActorLogToFile.swift` and `ActorReadLogRecords.swift`. Chart preparation moved into `LogChartService` and `LogStoreService`, SwiftUI views now call `LogStoreService` instead of `ActorReadLogRecords`, and `ActorReadLogRecords` is reduced to JSON read responsibility.
- **Done - 3B. Thin actor removal:** `ActorCreateOutputforView` and `ActorGetversionofRsyncUI` were replaced by plain async helper structs: `CreateOutputforView.swift` and `GetversionofRsyncUI.swift`.
- **Done - 3C. Detached persistence replacement:** `WriteSynchronizeConfigurationJSON.write(...)` and `WriteLogRecordsJSON.write(...)` now await `SharedJSONStorageWriter.shared.write(...)` instead of launching detached fire-and-forget writes.
- **Partial - 3D. Unstructured `Task` cleanup:** current search still finds 51 `Task {}` sites. Several are valid callback bridges, debounce flows, or UI timing delays; several others are still adapter-style wrappers around helper calls or view-owned async orchestration.
- **Partial - 3E. Single log-data boundary review:** chart loading is centralized behind `LogStoreService.chartEntries(...)`, and log filtering/delete/selection now resolve through `LogStoreService`, but snapshot loading and some log-domain work are still split between `LogStoreService`, `Logging`, `SnapshotsView`, and snapshot helpers.

## 2. Git-backed cleanup matrix

| Area | Current location / git evidence | Status | Notes |
|---|---|---|---|
| 3A. Log-data actor reduction | `3960220e` deleted `ActorLogChartsData.swift` and replaced `ActorReadLogRecordsJSON.swift` with `ActorReadLogRecords.swift`; `7ce54ce1` deleted `ObservableChartData.swift` and added `LogChartService.swift` | **Done** | The actor count is reduced, views now route log selection/filter/delete through `LogStoreService`, and `ActorReadLogRecords` is back to storage-only reads. |
| 3B. Thin actor removal | `a51d53cf` renamed `ActorCreateOutputforView.swift` to `CreateOutputforView.swift`; `2db9ac26` renamed `ActorGetversionofRsyncUI.swift` to `GetversionofRsyncUI.swift` | **Done** | The actor wrappers are gone. Remaining work is call-site cleanup, not actor removal. |
| 3C. Detached persistence replacement | `d35aac7f` started logfile concurrency cleanup; `e7830374` added `SharedJSONStorageWriter.swift` and updated both JSON writers | **Done** | Detached persistence is removed from configuration and log-store writes. |
| 3D. Unstructured `Task` cleanup | Current search still shows 51 `Task {}` sites, 1 `ActorReadLogRecords(...)` call site, 8 `CreateOutputforView()` call sites, and 2 `GetversionofRsyncUI()` call sites | **Partial** | The easiest accidental async boundaries are removed, but many adapter-style tasks remain. |
| 3E. Single log-data boundary review | `LogStoreService.swift`, `LogChartService.swift`, `LogRecordsTabView.swift:140-204`, `SnapshotsView.swift:215-291` | **Partial** | Chart entry creation is centralized, and delete/filter/select flows now live behind `LogStoreService`, but snapshot load orchestration is still view-owned. |

## 3. Detailed cleanup areas

### A. Log-data actor reduction - **Done**

The original Phase 3 plan kept three log-data actors. Current git updates already removed one actor layer and collapsed another:

- `3960220e` deleted `ActorLogChartsData.swift`.
- `3960220e` also replaced `ActorReadLogRecordsJSON.swift` with `ActorReadLogRecords.swift`.
- `7ce54ce1` deleted `ObservableChartData.swift` and introduced `LogChartService.swift`, moving chart preparation into pure reducers behind `LogStoreService.chartEntries(...)`.

This item is **done for Phase 3A**: the actor surface is smaller, chart preparation is no longer actor-owned, and the remaining actor is no longer called directly from SwiftUI views for selection/filter/delete work.

What is already cleaner:

- `ActorLogToFile` remains the serialized logfile boundary for execution logging, schedule logging, SSH key logging, and logfile reset/read.
- `LogStoreService.loadStore(...)` is now the shared read entry point for persisted log records.
- `LogStoreService.visibleLogs(...)` now owns selection, merge, sort, and filter work for log presentation.
- `LogStoreService.deleteLogs(...)` now owns delete-and-persist orchestration for log-store mutations.
- `LogStoreService.chartEntries(...)` resolves chart data through `LogChartReducer` without reintroducing a chart actor.
- `ActorReadLogRecords` is reduced to `readjsonfilelogrecords(...)`, which keeps the actor focused on serialized log-store reads.

What still remains after 3A:

- `SnapshotsView.getData()` still launches a view-owned `Task {}` around `LogStoreService.loadStore(...)` and `Snapshotlogsandcatalogs(...)`.
- `Logging` still owns store mutation for scheduled log insertion instead of sharing a fuller write-side service API.
- Snapshot-specific merge and "unused log" calculations still live outside `LogStoreService`.

### B. Thin actor removal - **Done**

The cleanup plan called for removing or replacing `ActorCreateOutputforView` and `ActorGetversionofRsyncUI`.

This item is **done**. Git shows the actor wrappers were replaced in place:

- `a51d53cf` renamed `ActorCreateOutputforView.swift` to `CreateOutputforView.swift`.
- `2db9ac26` renamed `ActorGetversionofRsyncUI.swift` to `GetversionofRsyncUI.swift`.

Current replacements:

- `CreateOutputforView.swift` is now a plain helper struct with async methods for output mapping and logfile presentation.
- `GetversionofRsyncUI.swift` is now a plain helper struct that fetches version metadata and exposes `getversionsofrsyncui()` and `downloadlinkofrsyncui()`.

Current direct helper use shows the actor removal is landed:

- `Estimate.swift`, `ObservableRestore.swift`, `OneTaskDetailsView.swift`, `VerifyTaskTabView.swift`, `RestoreTableView.swift`, `extensionQuickTaskView.swift`, and `LogfileView.swift` all call `CreateOutputforView()` directly.
- `SidebarMainView.swift` and `AboutView.swift` both call `GetversionofRsyncUI()` directly.

The remaining work here is downstream cleanup of `Task {}` wrappers around these helpers, not bringing the actors back.

### C. Detached persistence replacement - **Done**

This item is **done**: the detached-write part of the old concurrency model is already removed.

Recent history and current code line up:

- `d35aac7f` started the logfile/concurrency write cleanup.
- `e7830374` introduced `SharedJSONStorageWriter.swift`.
- `WriteSynchronizeConfigurationJSON.swift:12-38` now encodes data and awaits `SharedJSONStorageWriter.shared.write(...)`.
- `WriteLogRecordsJSON.swift:12-38` now does the same for log-store writes.

The only remaining executable `Task.detached` site is the debug-only threading assertion in `CreateStreamingHandlers.swift:89-95`. `git grep` finds two `Task.detached` text matches, but one is the explanatory comment directly above the single executable call.

That means the Phase 3 persistence outcome is already in place:

- configuration writes are no longer fire-and-forget detached work
- log-store writes are no longer fire-and-forget detached work
- ordering and error propagation now pass through one explicit async write boundary

### D. Unstructured `Task` cleanup - **Partial**

This item is **partially done**: the repo is no longer using actors and detached writes as generic wrappers, but it still contains many `Task {}` sites.

#### `Task` sites that still look justified

| File and lines | Why it still makes sense | Status |
|---|---|---|
| `CreateStreamingHandlers.swift:34-36`, `70-72` | Callback bridge back to main-actor alert state | **Keep** |
| `Estimate.swift:155-170`, `Execute.swift:50-57`, `238-323` | Rsync termination callbacks still need async follow-up work | **Keep for now** |
| `GlobalTimer.swift:155-158`, `211-213` | `Timer` and wake-notification callbacks must bridge back to main-actor state | **Keep** |
| `RestoreTableView.swift:49-59`, `LogRecordsTabView.swift:84-94`, `ListofTasksMainView.swift:61-75` | Debounce/cancellation behavior is intentional UI logic | **Keep** |
| `SidebarStatusMessagesView.swift`, `QuicktaskFormView.swift`, `ButtonStyles.swift`, `CompletedView.swift`, `SummarizedDetailsContentView.swift` | Simple UI timing and auto-dismiss behavior | **Keep** |

#### `Task` sites that remain cleanup targets

| File and lines | What the task is still compensating for | Status |
|---|---|---|
| `ObservableRestore.swift:36-39`, `OneTaskDetailsView.swift:134-173`, `VerifyTaskTabView.swift:170-173`, `extensionQuickTaskView.swift:120-138`, `LogfileView.swift:44-47` | Wrapper tasks around `CreateOutputforView` helper calls | **Partial** |
| `ConfigurationsTableLoadDataView.swift:71-80` | Profile reload is still wrapped in an ad hoc task instead of one loader path | **Not done** |
| `extensionSidebarMainView.swift:63-112` | Deeplink and workspace reload flows still create inline tasks around profile-loading work | **Partial** |
| `SnapshotsView.swift:216-224`, `271-275` | Snapshot load and timing flows still launch view-owned tasks around log-store work | **Partial** |
| `InterruptProcess.swift:12-17` | Interrupt logging still depends on a task launched from a sync initializer | **Not done** |

The clearest sign of unfinished work is that `CreateOutputforView()` now exists as a plain helper, but it still has eight call sites and several of them are only async because the old actor wrapper disappeared before the surrounding task adapters were simplified.

### E. Single log-data boundary review - **Partial**

This item is **partially done**. Chart entry creation now resolves through one shared service call, and the log table plus snapshot delete path now use the same log-store boundary:

```swift
let entries = await LogStoreService.chartEntries(
    profile: rsyncUIdata.profile,
    configurations: rsyncUIdata.configurations,
    configurationID: selecteduuids.first,
    metric: metric,
    limit: limit
)
```

That is real progress, and the shared configuration helpers in `LogStoreService.swift` already centralize:

- `hiddenIDs`
- `hiddenID(for:)`
- `backupID(for:)`

What is still incomplete:

- `SnapshotsView.getData()` still launches a `Task {}` that combines `LogStoreService.loadStore(...)` with `Snapshotlogsandcatalogs(...)`.
- `Logging` still mutates and persists log-store state directly for scheduled inserts instead of going through a fuller write-side service API.
- Snapshot-related merge and "unused log" calculations are still outside the service boundary.

Phase 3 therefore now has the filter/delete side of the boundary in much better shape, while snapshot assembly and write-side log-domain work remain the next cleanup targets.

## 4. Suggested target structure after current Phase 3 work

One reasonable end state is now visible in the code:

### Keep

- `ActorLogToFile` as the serialized logfile boundary
- one log-store actor or repository boundary for persisted log JSON
- callback-owned `Task {}` bridges in execution, timer, and notification code
- debounce/cancellation tasks in SwiftUI views where they model UI behavior

### Avoid reintroducing

- actor wrappers for simple mapping helpers
- actor wrappers for simple fetch/filter helpers
- detached persistence writes
- chart-specific actors now that `LogChartService` and `LogChartReducer` exist

### Finish collapsing

- move `ActorReadLogRecords` call sites behind `LogStoreService`
- keep `LogChartService` pure and reusable
- simplify `CreateOutputforView` call sites so the helper can stay plain without extra adapter tasks

## 5. Practical cleanup order

1. **Done** - Remove thin actors by keeping `CreateOutputforView` and `GetversionofRsyncUI` as plain helpers.
2. **Done** - Keep JSON persistence on one awaited writer instead of detached tasks.
3. **Partial** - Keep chart preparation behind `LogStoreService.chartEntries(...)` and `LogChartReducer`.
4. **Partial** - Finish the downstream adapter cleanup around `CreateOutputforView` call sites.
5. **Done** - Move `ActorReadLogRecords` filtering, selection, and delete calls behind `LogStoreService`.
6. **Partial** - Convert view-owned snapshot and log-delete task flows into clearer async entry points or service calls.
7. **Not done** - Recheck the remaining `Task {}` inventory so only callback bridges, debounce tasks, and real UI timing tasks remain.

## 6. Phase 3 checkpoints

- **Done** - Thin actor wrappers stay removed.
- **Done** - No persistence path uses `Task.detached`.
- **Done** - Chart preparation no longer depends on `ActorLogChartsData` or `ObservableChartData`.
- **Partial** - `Task {}` sites are reduced, but many adapter-style tasks still remain.
- **Done** - `ActorReadLogRecords` is smaller in scope than the old read/chart split, and views no longer call it directly.
- **Done** - No SwiftUI view directly owns log delete/filter logic.
- **Not done** - The remaining `Task {}` sites are all documented as either callback bridges, UI debounce flows, or intentional timing delays.

If you use this file as the execution checklist, the next Phase 3 wins are the `CreateOutputforView` adapter cleanups first, then collapsing snapshot-load orchestration and remaining write-side log-domain work behind the same log-store boundary.
