# Phase 4 - Log-data service unification

This file expands `cleanup.md` Phase 4 with concrete duplicate paths in the current code. The main issue is no longer direct view-to-actor coupling; after the latest Phase 3A work, log-data behavior is still split across `LogStoreService`, `Logging`, snapshot-specific code, and a few remaining view-owned orchestration paths.

## 1. Current duplication map

| Responsibility | Current duplicate locations | Notes |
|---|---|---|
| Load log store from JSON | `RsyncUI/Model/Loggdata/Logging.swift:27-30`, `RsyncUI/Views/InspectorViews/LogRecords/LogRecordsTabView.swift:156-159`, `RsyncUI/Views/InspectorViews/LogRecords/LogRecordsTabView.swift:186-189`, `RsyncUI/Views/Snapshots/SnapshotsView.swift:219-222`, `RsyncUI/Model/Loggdata/LogChartService.swift` | The read path is now shared through `LogStoreService.loadStore(...)`, but loading is still initiated from several layers. |
| Build `validhiddenIDs` | `LogStoreService.loadStore(...)`, `LogChartService.chartEntries(...)`, `Logging.create(...)` | The low-level loop is centralized, but multiple service/model entry points still trigger log-store loading separately. |
| Resolve selected task `hiddenID` | `LogStoreService.visibleLogs(...)`, `LogChartService.chartEntries(...)` | Selection resolution is now shared by helper APIs, but the log-domain still has separate read-side entry points for visible logs and chart data. |
| Merge/sort logs for one task or all tasks | `RsyncUI/Model/Loggdata/LogStoreService.swift`, `RsyncUI/Model/Snapshots/Snapshotlogsandcatalogs.swift:89-104` | General log presentation moved into `LogStoreService`, but snapshot-specific "unused log" calculation still flattens log data separately. |
| Delete logs and persist | `RsyncUI/Model/Loggdata/LogStoreService.swift`, callers in `LogRecordsTabView.swift` and `SnapshotsView.swift` | The mutation path is centralized now; remaining work is reducing caller-owned reset/orchestration and extending the same model to other write-side log flows. |
| Log result number parsing | `RsyncUI/Model/Loggdata/Logging.swift:103-116`, `RsyncUI/Model/Loggdata/LogChartService.swift:128-140` | The same regex-based number extraction still exists twice. |
| Chart preparation | `RsyncUI/Model/Loggdata/LogChartService.swift`, `RsyncUI/Views/Tasks/LogStatsChartView.swift:252-269` | The chart pipeline is much smaller now, but parsing/reduction still lives in a chart service while the view still owns refresh policy and selection state. |
| Snapshot/log merge | `RsyncUI/Views/Snapshots/SnapshotsView.swift:225-232`, `RsyncUI/Model/Snapshots/Snapshotlogsandcatalogs.swift:47-104` | Snapshot data assembly is driven from the view and the helper keeps its own copy of loaded log records. |

## 2. Detailed duplicate paths

### A. Shared loading boundary - **Done**

Before the refactor, these entry points all performed the same domain step: read persisted log records for a profile, restricted to valid task IDs.

- `Logging.create(...)` loads the store during scheduled log insertion (`Logging.swift:32-50`).
- `LogRecordsTabView.loadInitialLogs()` loads it for the log table (`LogRecordsTabView.swift:163-172`).
- `LogRecordsTabView.reloadLogsForProfile()` reloads the exact same store after a profile change (`LogRecordsTabView.swift:184-196`).
- `SnapshotsView.getData()` loads the same store before snapshot/catalog merging (`SnapshotsView.swift:225-232`).
- `LogStoreService.chartEntries(...)` now loads the same store before chart parsing (`LogChartService.swift:144-161`).

This item is **done**: `LogStoreService.loadStore(...)` is now the shared read entry point used by `Logging`, `LogRecordsTabView`, `SnapshotsView`, and chart loading.

Phase 4A lands as one shared loading boundary:

```swift
typealias LogStore = [LogRecords]

enum LogStoreService {
    static func loadStore(
        profile: String?,
        configurations: [SynchronizeConfiguration]?
    ) async -> LogStore
}
```

That keeps `Logging.create(...)`, `LogRecordsTabView`, `SnapshotsView`, and chart loading on the same entry point even before the broader log-domain service exists.

### B. Shared configuration helper - **Done**

All four implementations do this:

```swift
var temp = Set<Int>()
if let configurations = configurations {
    for config in configurations {
        temp.insert(config.hiddenID)
    }
}
return temp
```

Before the refactor, the repeated copies were:

- `Logging.validhiddenIDs`
- `LogRecordsTabView.validhiddenIDs`
- `SnapshotsView.validhiddenIDs`
- `LogStatsChartView.validhiddenIDs`

This item is **done**: `Collection<SynchronizeConfiguration>` now provides `hiddenIDs`, `hiddenID(for:)`, and `backupID(for:)`.

Phase 4B uses one shared configuration helper:

```swift
extension Collection where Element == SynchronizeConfiguration {
    var hiddenIDs: Set<Int> { ... }
    func hiddenID(for configurationID: SynchronizeConfiguration.ID?) -> Int? { ... }
    func backupID(for configurationID: SynchronizeConfiguration.ID?) -> String? { ... }
}
```

That removes the repeated `validhiddenIDs` loop and also centralizes selection-to-configuration lookups that already drifted into the same views.

### C. Selection-to-log resolution - **Done**

The UI repeatedly converts `selecteduuids.first` into a `hiddenID`:

- `LogRecordsTabView.loadInitialLogs()` now resolves through `LogStoreService.visibleLogs(...)`.
- `LogRecordsTabView.updateLogsForSelection()` now resolves through `LogStoreService.visibleLogs(...)`.
- `LogStatsChartView` already resolves chart data through `LogStoreService.chartEntries(...)`.

This item is **done for the current read-side boundary**: selection-to-log resolution is now owned by `LogStoreService` APIs instead of being reimplemented inside the log table view.

That mapping is not presentation logic; it is domain selection logic. A service API should accept either:

```swift
func logs(for configurationID: SynchronizeConfiguration.ID?) -> [Log]
```

or:

```swift
func hiddenID(for configurationID: SynchronizeConfiguration.ID?) -> Int?
```

That still leaves separate service entry points for visible logs and chart entries, but the configuration lookup itself is no longer duplicated in the view layer.

### D. Delete-and-persist service - **Done**

This item is **done for the current service boundary**: `LogRecordsTabView` and `SnapshotsView` now delete through `LogStoreService.deleteLogs(...)`.

#### `LogRecordsTabView.deleteLogs`

1. Calls `LogStoreService.deleteLogs(uuids, profile: rsyncUIdata.profile, in: logrecords)`
2. Refreshes visible logs with `LogStoreService.visibleLogs(...)`
3. Clears UI selection

#### `SnapshotsView.deleteLogs`

1. Calls `LogStoreService.deleteLogs(uuids, profile: rsyncUIdata.profile, in: records)`
2. Clears snapshot-specific local state

The data mutation part now lives behind one service call:

```swift
static func deleteLogs(
    _ ids: Set<Log.ID>,
    profile: String?,
    in store: LogStore
) async -> LogStore?
```

Each view still owns its presentation reset logic, which is fine for now; the remaining Phase 4 work is to reduce the amount of view-owned orchestration around the delete flow, not to move deletion back out of the service.

### E. Shared log-result parser - **Partial**

This item is **partially done**: the old actor-level chart parser is gone, but parsing is still duplicated between `Logging` and `LogChartService`.

Both files define:

- `extractnumbersasdoubles(from:)`
- `extractNumbersAsStrings(from:)`
- `numberRegex`

Current copies:

- `Logging.swift:103-116`
- `LogChartService.swift`

This is risky because scheduled log insertion validates log format in one place, while chart parsing interprets the same format elsewhere. If the log string format changes, both sites must change together.

Move this into one shared parser, for example:

```swift
enum ParsedLogResult {
    case sync(files: Int, transferredMB: Double, seconds: Double)
    case snapshot(snapshotNumber: Int, files: Int, transferredMB: Double, seconds: Double)
}

func parseLogResult(_ result: String) -> ParsedLogResult?
```

Then:

- `Logging` uses it for validation before insert.
- Chart preparation uses it for `LogEntry`.
- Snapshot-related code can inspect snapshot number explicitly instead of relying on raw string format.

### F. Unified chart preparation - **Done**

This item is **done**: `ObservableChartData` is gone, `LogStatsChartView` now asks `LogStoreService` for chart entries, and `LogChartReducer` has test coverage.

The current chart path is much cleaner, but it still mixes domain reduction and UI refresh policy:

1. `LogStoreService.chartEntries(...)` loads the store and resolves the selected configuration (`LogChartService.swift:144-161`).
2. `LogChartReducer` parses raw log results and applies the requested reduction (`LogChartService.swift:34-142`).
3. `LogStatsChartView.reloadChartData()` still owns refresh timing and selected-point cleanup (`LogStatsChartView.swift:252-269`).

That split is awkward for two reasons:

- the view decides domain policy (`files` vs `transferredMB`, max-per-day vs top-N)
- chart-specific parsing still duplicates log-result parsing already used by `Logging`

After the refactor, the chart pipeline should collapse into one service request that returns chart-ready data, with the view only choosing presentation state:

```swift
enum LogChartMetric {
    case files
    case transferredMB
}

enum LogChartLimit {
    case maxPerDay
    case topNPerDay(Int)
}

func chartEntries(
    for configurationID: SynchronizeConfiguration.ID?,
    metric: LogChartMetric,
    limit: LogChartLimit
) async throws -> [LogEntry]
```

That boundary should own the full sequence:

1. resolve `configurationID -> hiddenID`
2. load/select the relevant logs
3. parse `resultExecuted` into typed values
4. reduce the parsed records into the requested chart series

With that split:

- `LogStatsChartView` keeps only UI state such as metric toggles, chart style, and selected point
- `LogStatsChartView` can stay focused on refresh policy and presentation state instead of carrying more chart-domain decisions
- the remaining parser duplication between `Logging` and `LogChartService` becomes easier to remove

### G. Snapshot/log merge service - **Not done**

This item is **not done**: `Snapshotlogsandcatalogs` still owns merge logic and still stores raw `readlogrecordsfromfile` for later delete.

`Snapshotlogsandcatalogs` merges all logs again to compute `notmappedloguuids`:

- `Snapshotlogsandcatalogs.swift:89-104`

That repeats the "flatten all task logs into `[Log]`" behavior now owned by:

- `LogStoreService.visibleLogs(from:hiddenID:filterString:)` with `hiddenID == -1`

The snapshot flow also keeps its own raw `logrecords` copy and stores it into `ObservableSnapshotData.readlogrecordsfromfile` for later cleanup (`Snapshotlogsandcatalogs.swift:82-85`), which is another sign that the snapshot UI is compensating for missing service-level store ownership even after delete-and-persist moved into `LogStoreService`.

A unified service should expose snapshot-specific helpers on top of the same loaded store:

```swift
func snapshotRecords(
    for config: SynchronizeConfiguration,
    remoteCatalogs: [SnapshotFolder]
) -> SnapshotLogData
```

where `SnapshotLogData` contains:

- merged `[LogRecordSnapshot]`
- `unusedLogIDs`
- original store identity if later delete/persist is needed

## 3. Types that currently mix UI and domain work

### `LogRecordsTabView`

Should keep:

- filter text state
- selection state
- confirmation dialog state
- rendering

Should stop doing directly:

- loading persisted logs
- mapping configuration IDs to `hiddenID`
- filtering logs through storage actor calls
- deleting and persisting logs

### `SnapshotsView`

Should keep:

- selected configuration
- tagging options (`snaplast`, `snapdayofweek`)
- dialog and toolbar state

Should stop doing directly:

- loading persisted logs
- launching domain merge of snapshot logs + remote catalogs
- deleting log records from permanent storage

### `LogStatsChartView`

Should keep:

- metric toggle
- chart type toggle
- selected data point
- rendering

Should stop doing directly:

- loading/parsing logs
- deciding which actor aggregation methods to call
- rebuilding `validhiddenIDs`
- resolving `hiddenID`

### `Logging`

Should likely shrink to one write-focused use case, or disappear into the unified service. Right now it owns:

- loading persisted log records
- validating log format
- updating existing entries
- creating new entries
- formatting snapshot log strings
- persisting logs
- mutating configuration `dateRun` / `snapshotnum`

That is already broader than "logging".

## 4. Suggested target structure

One reasonable split is:

### `LogDataService` actor

Owns:

- reading/writing log JSON
- caching/holding loaded `[LogRecords]`
- selecting task/all-task logs
- filtering/sorting
- delete operations
- chart entry preparation
- snapshot/log merge helpers if you want all log-domain logic in one place

### Small pure helpers

- `LogResultParser`
- `LogChartReducer`
- `LogRecordSelectors`
- `SnapshotLogMerger` if snapshot merging feels too specific for the service actor itself

That keeps actor isolation around persistence and shared store access, while moving transformation logic into testable pure functions.

## 5. Practical cleanup order

1. **Partial** - Extract the shared log-result parser from `Logging` and `ActorReadLogRecords`.
2. **Done** - Extract configuration helpers for `hiddenIDs` and `selected hiddenID`.
3. **Partial** - Create a store-oriented service that wraps `readjsonfilelogrecords` and `WriteLogRecordsJSON`.
4. **Partial** - Move `LogRecordsTabView` to the service first; it has the simplest read/filter/delete path.
5. **Done** - Move chart preparation next by replacing `ObservableChartData` + `LogStatsChartView.readAndSortLogData()` with one service call.
6. **Not done** - Move snapshot merge/delete flow last, because it combines local logs with remote catalog discovery.
7. **Partial** - Reduce `Logging` into either:
   - a thin facade over `LogDataService`, or
   - a write use case nested inside the new log-data domain.

## 6. Refactor checkpoints to verify while cleaning up

- **Done** - There is only one place that reads log JSON from disk.
- **Not done** - There is only one place that writes log JSON to disk.
- **Not done** - There is only one parser for `resultExecuted`.
- **Not done** - No SwiftUI view directly calls `ActorReadLogRecords`.
- **Done** - `ObservableChartData` is either removed or reduced to plain UI state.
- **Not done** - `SnapshotsView` no longer stores raw `readlogrecordsfromfile` just to support delete.
- **Done** - `validhiddenIDs` is not reimplemented in view files.

If you use this file as the execution checklist, the highest-value deletions are the duplicate loading paths and the duplicated regex parser first; those are the easiest wins and reduce the risk of divergence immediately.
