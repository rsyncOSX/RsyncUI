# Phase 3 - Concurrency cleanup

This file expands `cleanup.md` Phase 3 with current progress from the codebase and recent git history. The goal of Phase 3 is to remove accidental concurrency, keep only correctness-critical async boundaries, and reduce the log-data pipeline to a smaller set of actors and helpers that are easier to reason about.

## 1. Current-state summary

- **Done - 3A. Log-data actor reduction:** `cleanup.md` originally kept three log-data actors: `ActorLogToFile`, `ActorReadLogRecordsJSON`, and `ActorLogChartsData`. The current tree is down to two actor files: `ActorLogToFile.swift` and `ActorReadLogRecords.swift`. Chart preparation moved into `LogChartService` and `LogStoreService`, SwiftUI views now call `LogStoreService` instead of `ActorReadLogRecords`, and `ActorReadLogRecords` is reduced to JSON read responsibility.
- **Done - 3B. Thin actor removal:** `ActorCreateOutputforView` and `ActorGetversionofRsyncUI` were replaced by plain helper structs: `CreateOutputforView.swift` and `GetversionofRsyncUI.swift`.
- **Done - 3C. Detached persistence replacement:** `WriteSynchronizeConfigurationJSON.write(...)` and `WriteLogRecordsJSON.write(...)` now await `SharedJSONStorageWriter.shared.write(...)` instead of launching detached fire-and-forget writes.
- **Partial - 3D. Unstructured `Task` cleanup:** current search now finds 50 `Task {}` sites. The first downstream cleanup slice landed: pure `CreateOutputforView` mapping calls in quick task, verify/details, restore-after-execute, logfile reload, and estimate flows no longer need adapter-style helper tasks. Several valid callback bridges, debounce flows, and UI timing delays still remain, along with a smaller set of view-owned orchestration tasks.
- **Partial - 3E. Single log-data boundary review:** chart loading is centralized behind `LogStoreService.chartEntries(...)`, log filtering/delete/selection resolve through `LogStoreService`, and snapshot loading now funnels through one `loadSnapshotData(for:)` entry point in `SnapshotsView`. Snapshot assembly and some write-side log-domain work are still split between `LogStoreService`, `Logging`, `SnapshotsView`, and snapshot helpers.

## 2. Git-backed cleanup matrix

| Area | Current location / git evidence | Status | Notes |
|---|---|---|---|
| 3A. Log-data actor reduction | `3960220e` deleted `ActorLogChartsData.swift` and replaced `ActorReadLogRecordsJSON.swift` with `ActorReadLogRecords.swift`; `7ce54ce1` deleted `ObservableChartData.swift` and added `LogChartService.swift` | **Done** | The actor count is reduced, views now route log selection/filter/delete through `LogStoreService`, and `ActorReadLogRecords` is back to storage-only reads. |
| 3B. Thin actor removal | `a51d53cf` renamed `ActorCreateOutputforView.swift` to `CreateOutputforView.swift`; `2db9ac26` renamed `ActorGetversionofRsyncUI.swift` to `GetversionofRsyncUI.swift` | **Done** | The actor wrappers are gone. Remaining work is call-site cleanup, not actor removal. |
| 3C. Detached persistence replacement | `d35aac7f` started logfile concurrency cleanup; `e7830374` added `SharedJSONStorageWriter.swift` and updated both JSON writers | **Done** | Detached persistence is removed from configuration and log-store writes. |
| 3D. Unstructured `Task` cleanup | Current search now shows 50 `Task {}` sites, 1 `ActorReadLogRecords(...)` call site, 7 `CreateOutputforView()` call sites, and 2 `GetversionofRsyncUI()` call sites | **Partial** | The first adapter-cleanup slice is landed, but several orchestration and sync-entry wrapper tasks remain. |
| 3E. Single log-data boundary review | `LogStoreService.swift`, `LogChartService.swift`, `LogRecordsTabView.swift:140-204`, `SnapshotsView.swift:192-280` | **Partial** | Chart entry creation is centralized, delete/filter/select flows live behind `LogStoreService`, and snapshot reload now goes through `loadSnapshotData(for:)`, but snapshot assembly is still initiated from the view and write-side log-domain work is still split. |

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

- `SnapshotsView.getData()` still launches a view-owned `Task {}`, but it now funnels through `loadSnapshotData(for:)` instead of inlining both `LogStoreService.loadStore(...)` and `Snapshotlogsandcatalogs(...)` in the view body.
- `Logging` still owns store mutation for scheduled log insertion instead of sharing a fuller write-side service API.
- Snapshot-specific merge and "unused log" calculations still live outside `LogStoreService`.

### B. Thin actor removal - **Done**

The cleanup plan called for removing or replacing `ActorCreateOutputforView` and `ActorGetversionofRsyncUI`.

This item is **done**. Git shows the actor wrappers were replaced in place:

- `a51d53cf` renamed `ActorCreateOutputforView.swift` to `CreateOutputforView.swift`.
- `2db9ac26` renamed `ActorGetversionofRsyncUI.swift` to `GetversionofRsyncUI.swift`.

Current replacements:

- `CreateOutputforView.swift` is now a plain helper struct. The pure output-mapping helpers are synchronous, while the logfile and restore-list helpers stay async where they still cross storage or trimming boundaries.
- `GetversionofRsyncUI.swift` is now a plain helper struct that fetches version metadata and exposes `getversionsofrsyncui()` and `downloadlinkofrsyncui()`.

Current direct helper use shows the actor removal is landed:

- `Estimate.swift`, `ObservableRestore.swift`, `OneTaskDetailsView.swift`, `VerifyTaskTabView.swift`, `RestoreTableView.swift`, `extensionQuickTaskView.swift`, and `LogfileView.swift` all still call `CreateOutputforView()` directly, but the pure-mapping call sites no longer need `await`.
- `SidebarMainView.swift` and `AboutView.swift` both call `GetversionofRsyncUI()` directly.

The remaining work here is the smaller set of true async helper/service entry points, not bringing the actors back.

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

This item is **partially done**: the repo is no longer using actors and detached writes as generic wrappers, and the first helper-wrapper cleanup slice is landed, but the repo still contains many `Task {}` sites.

#### `Task` sites that still look justified

| File and lines | Why it still makes sense | Status |
|---|---|---|
| `CreateStreamingHandlers.swift:34-36`, `70-72` | Callback bridge back to main-actor alert state | **Keep** |
| `Estimate.swift:155-170`, `Execute.swift:50-57`, `238-323` | Rsync termination callbacks still need async follow-up work | **Keep for now** |
| `GlobalTimer.swift:155-158`, `211-213` | `Timer` and wake-notification callbacks must bridge back to main-actor state | **Keep** |
| `RestoreTableView.swift:49-59`, `LogRecordsTabView.swift:84-94`, `ListofTasksMainView.swift:61-75` | Debounce/cancellation behavior is intentional UI logic | **Keep** |
| `ObservableRestore.swift:51-60`, `OneTaskDetailsView.swift:66-70`, `VerifyTaskTabView.swift:125-130`, `extensionQuickTaskView.swift:86-92`, `LogfileView.swift:28-53`, `extensionSidebarMainView.swift:80-106` | Callback or button-entry bridges that now wrap the sync/async boundary directly instead of wrapping helper work | **Keep** |
| `SidebarStatusMessagesView.swift`, `QuicktaskFormView.swift`, `ButtonStyles.swift`, `CompletedView.swift`, `SummarizedDetailsContentView.swift` | Simple UI timing and auto-dismiss behavior | **Keep** |

#### `Task` sites that remain cleanup targets

| File and lines | What the task is still compensating for | Status |
|---|---|---|
| `ConfigurationsTableLoadDataView.swift:71-80` | Profile reload is still wrapped in an ad hoc task instead of one loader path | **Not done** |
| `SnapshotsView.swift:214-215` | Snapshot loading now goes through `loadSnapshotData(for:)`, but the view still owns the task that kicks off snapshot assembly | **Partial** |
| `InterruptProcess.swift:12-17` | Interrupt logging still depends on a task launched from a sync initializer | **Not done** |

The clearest sign of unfinished work is no longer the pure `CreateOutputforView` mapping path. Those call sites are now simplified. The remaining Phase 3 cleanup targets are the view-owned orchestration tasks and older sync-entry wrappers such as profile reload and interrupt logging.

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

- `SnapshotsView.getData()` still launches a `Task {}`, but the actual load path is now centralized in `loadSnapshotData(for:)`.
- `Logging` still mutates and persists log-store state directly for scheduled inserts instead of going through a fuller write-side service API.
- Snapshot-related merge and "unused log" calculations are still outside the service boundary.

Phase 3 therefore now has the filter/delete side of the boundary in much better shape, and snapshot reload is less ad hoc than before, while snapshot assembly and write-side log-domain work remain the next cleanup targets.

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
4. **Partial** - Continue collapsing the remaining async entry points around `CreateOutputforView` and related view callbacks. The pure-mapping helper wrappers are already cleaned up.
5. **Done** - Move `ActorReadLogRecords` filtering, selection, and delete calls behind `LogStoreService`.
6. **Partial** - Convert the remaining view-owned snapshot task flow into a clearer service boundary; `SnapshotsView` now has a single `loadSnapshotData(for:)` entry point but still owns the kickoff task.
7. **Not done** - Recheck the remaining `Task {}` inventory so only callback bridges, debounce tasks, and real UI timing tasks remain.

## 6. Phase 3 checkpoints

- **Done** - Thin actor wrappers stay removed.
- **Done** - No persistence path uses `Task.detached`.
- **Done** - Chart preparation no longer depends on `ActorLogChartsData` or `ObservableChartData`.
- **Partial** - `Task {}` sites are reduced to 50, and the first helper-wrapper cleanup slice is landed, but several adapter/orchestration tasks still remain.
- **Done** - `ActorReadLogRecords` is smaller in scope than the old read/chart split, and views no longer call it directly.
- **Done** - No SwiftUI view directly owns log delete/filter logic.
- **Not done** - The remaining `Task {}` sites are not yet fully reduced to callback bridges, debounce flows, or intentional timing delays.

If you use this file as the execution checklist, the next Phase 3 wins are `ConfigurationsTableLoadDataView` and `InterruptProcess` first, then collapsing the last snapshot-load kickoff task and remaining write-side log-domain work behind the same log-store boundary.
