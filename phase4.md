# Phase 4 - Log-data service unification

This file expands `cleanup.md` Phase 4 with concrete duplicate paths in the current code. The main issue is that log-data behavior is split across UI views, `Logging`, snapshot-specific code, and `ActorReadLogRecords`, so the same load/filter/sort/delete/persist work is repeated in several places.

## 1. Current duplication map

| Responsibility | Current duplicate locations | Notes |
|---|---|---|
| Load log store from JSON | `RsyncUI/Model/Loggdata/Logging.swift:32-50`, `RsyncUI/Views/InspectorViews/LogRecords/LogRecordsTabView.swift:163-172`, `RsyncUI/Views/InspectorViews/LogRecords/LogRecordsTabView.swift:184-196`, `RsyncUI/Views/Snapshots/SnapshotsView.swift:225-232`, `RsyncUI/Model/Global/ObservableChartData.swift:17-24` | Same `ActorReadLogRecords().readjsonfilelogrecords(profile, validhiddenIDs)` entry point is triggered from multiple UI/model layers. |
| Build `validhiddenIDs` | `RsyncUI/Model/Loggdata/Logging.swift:22-30`, `RsyncUI/Views/InspectorViews/LogRecords/LogRecordsTabView.swift:132-140`, `RsyncUI/Views/Snapshots/SnapshotsView.swift:185-193`, `RsyncUI/Views/Tasks/LogStatsChartView.swift:212-220` | Same loop over configurations repeated four times. |
| Resolve selected task `hiddenID` | `RsyncUI/Views/InspectorViews/LogRecords/LogRecordsTabView.swift:163-168`, `RsyncUI/Views/InspectorViews/LogRecords/LogRecordsTabView.swift:198-203`, `RsyncUI/Views/Tasks/LogStatsChartView.swift:222-231` | The same `selecteduuids.first -> configuration -> hiddenID` mapping is duplicated. |
| Merge/sort logs for one task or all tasks | `RsyncUI/Model/Storage/Actors/ActorReadLogRecords.swift:55-77`, `RsyncUI/Model/Storage/Actors/ActorReadLogRecords.swift:79-111`, `RsyncUI/Model/Snapshots/Snapshotlogsandcatalogs.swift:89-104` | "Merge all logs", "sort by date desc", and "find used vs unused UUIDs" are domain operations, but are split across the actor and snapshot helper. |
| Delete logs and persist | `RsyncUI/Views/InspectorViews/LogRecords/LogRecordsTabView.swift:150-160`, `RsyncUI/Views/Snapshots/SnapshotsView.swift:282-297` | Both views call `ActorReadLogRecords().deleteLogs(...)`, then `WriteLogRecordsJSON(...)`, then manually fix local UI state. |
| Log result number parsing | `RsyncUI/Model/Loggdata/Logging.swift:121-134`, `RsyncUI/Model/Storage/Actors/ActorReadLogRecords.swift:165-178` | The same regex-based number extraction exists twice. |
| Chart preparation | `RsyncUI/Model/Global/ObservableChartData.swift:17-24`, `RsyncUI/Views/Tasks/LogStatsChartView.swift:265-287`, `RsyncUI/Model/Storage/Actors/ActorReadLogRecords.swift:134-243` | The chart pipeline is fragmented: load + parse in one type, aggregation decisions in another, helpers in the actor. |
| Snapshot/log merge | `RsyncUI/Views/Snapshots/SnapshotsView.swift:225-232`, `RsyncUI/Model/Snapshots/Snapshotlogsandcatalogs.swift:47-104` | Snapshot data assembly is driven from the view and the helper keeps its own copy of loaded log records. |

## 2. Detailed duplicate paths

### A. Loading the same log store from multiple entry points

Before the refactor, these entry points all performed the same domain step: read persisted log records for a profile, restricted to valid task IDs.

- `Logging.create(...)` loads the store during scheduled log insertion (`Logging.swift:32-50`).
- `LogRecordsTabView.loadInitialLogs()` loads it for the log table (`LogRecordsTabView.swift:163-172`).
- `LogRecordsTabView.reloadLogsForProfile()` reloads the exact same store after a profile change (`LogRecordsTabView.swift:184-196`).
- `SnapshotsView.getData()` loads the same store before snapshot/catalog merging (`SnapshotsView.swift:225-232`).
- `ObservableChartData.readandparselogs(...)` loads the same store before chart parsing (`ObservableChartData.swift:17-24`).

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

That keeps `Logging.create(...)`, `LogRecordsTabView`, `SnapshotsView`, and `ObservableChartData` on the same entry point even before the broader log-domain service exists.

### B. `validhiddenIDs` is repeated in four places

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

Phase 4B uses one shared configuration helper:

```swift
extension Collection where Element == SynchronizeConfiguration {
    var hiddenIDs: Set<Int> { ... }
    func hiddenID(for configurationID: SynchronizeConfiguration.ID?) -> Int? { ... }
    func backupID(for configurationID: SynchronizeConfiguration.ID?) -> String? { ... }
}
```

That removes the repeated `validhiddenIDs` loop and also centralizes selection-to-configuration lookups that already drifted into the same views.

### C. Selection-to-log resolution is UI-owned in multiple places

The UI repeatedly converts `selecteduuids.first` into a `hiddenID`:

- `LogRecordsTabView.loadInitialLogs()` (`LogRecordsTabView.swift:163-168`)
- `LogRecordsTabView.updateLogsForSelection()` (`LogRecordsTabView.swift:198-203`)
- `LogStatsChartView.hiddenID` (`LogStatsChartView.swift:222-231`)

That mapping is not presentation logic; it is domain selection logic. A service API should accept either:

```swift
func logs(for configurationID: SynchronizeConfiguration.ID?) -> [Log]
```

or:

```swift
func hiddenID(for configurationID: SynchronizeConfiguration.ID?) -> Int?
```

so the resolution is implemented once.

### D. Delete-and-persist is duplicated in two views

#### `LogRecordsTabView.deleteLogs`

1. Calls `ActorReadLogRecords().deleteLogs(uuids, logrecords: logrecords)`
2. Recomputes visible logs with `updatelogsbyhiddenID`
3. Persists with `WriteLogRecordsJSON(rsyncUIdata.profile, records)`
4. Clears UI selection

#### `SnapshotsView.deleteLogs`

1. Calls `ActorReadLogRecords().deleteLogs(uuids, logrecords: records)`
2. Persists with `WriteLogRecordsJSON(rsyncUIdata.profile, records)`
3. Clears snapshot-specific local state

The data mutation part should move behind one service call:

```swift
func deleteLogs(
    _ ids: Set<Log.ID>,
    profile: String?,
    in store: LogStore
) async throws -> LogStore
```

Then each view only refreshes its own presentation state.

### E. Number parsing is duplicated in `Logging` and `ActorReadLogRecords`

Both files define:

- `extractnumbersasdoubles(from:)`
- `extractNumbersAsStrings(from:)`
- `numberRegex`

Current copies:

- `Logging.swift:121-134`
- `ActorReadLogRecords.swift:165-178`

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

### F. Chart preparation is split across three layers

Current flow:

1. `ObservableChartData.readandparselogs(...)` loads logs and converts them to parsed entries (`ObservableChartData.swift:17-24`).
2. `LogStatsChartView.readAndSortLogData()` decides which aggregation to use and calls actor helpers (`LogStatsChartView.swift:265-287`).
3. `ActorReadLogRecords` implements:
   - `parselogrecords` (`ActorReadLogRecords.swift:134-163`)
   - `parsemaxfilesbydate` (`182-197`)
   - `parsemaxNNfilesbydate` (`200-203`)
   - `parsemaxfilesbytransferredsize` (`227-243`)
   - `parsemaxNNfilesbytransferredsize` (`213-216`)

This means the chart view owns data-policy decisions. It should instead ask for chart-ready data:

```swift
enum LogChartMetric { case files, transferredMB }
enum LogChartLimit { case maxPerDay, topNPerDay(Int) }

func chartEntries(
    for hiddenID: Int?,
    metric: LogChartMetric,
    limit: LogChartLimit
) async throws -> [LogEntry]
```

Then `LogStatsChartView` only owns chart presentation toggles.

### G. Snapshot-specific merge logic repeats log-merging work

`Snapshotlogsandcatalogs` merges all logs again to compute `notmappedloguuids`:

- `Snapshotlogsandcatalogs.swift:89-104`

That repeats the "flatten all task logs into `[Log]`" behavior already present in:

- `ActorReadLogRecords.updatelogsbyhiddenID(..., -1)` (`ActorReadLogRecords.swift:57-69`)
- `ActorReadLogRecords.updatelogsbyfilter(..., -1)` (`ActorReadLogRecords.swift:82-97`)

The snapshot flow also keeps its own raw `logrecords` copy and stores it into `ObservableSnapshotData.readlogrecordsfromfile` for later cleanup (`Snapshotlogsandcatalogs.swift:82-85`), which is another sign that the snapshot UI is compensating for missing service-level store ownership.

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

1. Extract the shared log-result parser from `Logging` and `ActorReadLogRecords`.
2. Extract configuration helpers for `hiddenIDs` and `selected hiddenID`.
3. Create a store-oriented service that wraps `readjsonfilelogrecords` and `WriteLogRecordsJSON`.
4. Move `LogRecordsTabView` to the service first; it has the simplest read/filter/delete path.
5. Move chart preparation next by replacing `ObservableChartData` + `LogStatsChartView.readAndSortLogData()` with one service call.
6. Move snapshot merge/delete flow last, because it combines local logs with remote catalog discovery.
7. Reduce `Logging` into either:
   - a thin facade over `LogDataService`, or
   - a write use case nested inside the new log-data domain.

## 6. Refactor checkpoints to verify while cleaning up

- There is only one place that reads log JSON from disk.
- There is only one place that writes log JSON to disk.
- There is only one parser for `resultExecuted`.
- No SwiftUI view directly calls `ActorReadLogRecords`.
- `ObservableChartData` is either removed or reduced to plain UI state.
- `SnapshotsView` no longer stores raw `readlogrecordsfromfile` just to support delete.
- `validhiddenIDs` is not reimplemented in view files.

If you use this file as the execution checklist, the highest-value deletions are the duplicate loading paths and the duplicated regex parser first; those are the easiest wins and reduce the risk of divergence immediately.
