# Phase 1 - Inventory and safety rails

This file expands `cleanup.md` Phase 1 with a concrete inventory of the current concurrency and persistence boundaries. The goal of Phase 1 is not to change behavior yet, but to map exactly **what must stay async**, **what should stop being actor-isolated**, and **where later refactors should land**.

## 1. Current-state summary

- App-owned actors currently live in four files:
  - `RsyncUI/Model/Storage/Actors/ActorLogToFile.swift:23`
  - `RsyncUI/Model/Storage/Actors/ActorReadLogRecords.swift:12`
  - `RsyncUI/Model/Output/ActorCreateOutputforView.swift:10`
  - `RsyncUI/Model/Newversion/ActorGetversionofRsyncUI.swift:11`
- The only executable `Task.detached` sites are:
  - `RsyncUI/Model/Storage/WriteSynchronizeConfigurationJSON.swift:40-50`
  - `RsyncUI/Model/Storage/WriteLogRecordsJSON.swift:40-50`
  - `RsyncUI/Model/Execution/CreateHandlers/CreateStreamingHandlers.swift:92-95`
- The storage layer is still split across three patterns:
  - `@MainActor` synchronous read/write helpers
  - actor-based log persistence
  - detached fire-and-forget writes for configurations and log records
- Profile/configuration loading is duplicated across:
  - `RsyncUI/Main/RsyncUIView.swift:52-74`
  - `RsyncUI/Views/Sidebar/extensionSidebarMainView.swift:157-179`
  - `RsyncUI/Views/Configurations/ConfigurationsTableLoadDataView.swift:61-81`
  - `RsyncUI/Model/Utils/ReadAllTasks.swift:13-96`
- Phase 4 groundwork already exists:
  - `RsyncUI/Model/Loggdata/LogStoreService.swift:10-32`
  - `hiddenIDs`, `hiddenID(for:)`, and `backupID(for:)` are already centralized there.

## 2. Actor matrix

| Type | Location | What it actually owns today | Classification | Where to refactor |
|---|---|---|---|---|
| `ActorLogToFile` | `RsyncUI/Model/Storage/Actors/ActorLogToFile.swift:23-149` | Cached `Homepath`, serialized logfile append/read/reset, file-size checks, error propagation | **Keep** | Keep actor isolation for serialized logfile I/O, but make this the only logfile boundary. Callers in `Execute`, `CreateCommandHandlers`, `InterruptProcess`, `ObservableSchedules`, `SshKeys`, and `LogfileView` should not grow parallel write logic around it. |
| `ActorReadLogRecords` | `RsyncUI/Model/Storage/Actors/ActorReadLogRecords.swift:12-127` | Reads persisted log JSON, filters by valid IDs, merges logs, filters logs, deletes logs | **Keep temporarily, then centralize** | This is the natural seed for the Phase 4 log-data service. Reading/writing can stay isolated, but `updatelogsbyhiddenID`, `updatelogsbyfilter`, and `deleteLogs` should move behind one log-domain API instead of being called from views. |
| `ActorCreateOutputforView` | `RsyncUI/Model/Output/ActorCreateOutputforView.swift:10-57` | Mostly array-to-view-model mapping; one logfile read delegated to `ActorLogToFile` | **Convert to non-actor helper** | The actor adds `await` and forces `Task` wrappers, but owns no meaningful mutable state. Replace with pure mapping helpers plus one explicit async logfile loader. |
| `ActorGetversionofRsyncUI` | `RsyncUI/Model/Newversion/ActorGetversionofRsyncUI.swift:11-37` | Fetches version JSON and filters it against the running app version | **Convert to async service** | This should become a plain async fetch service used by `SidebarMainView` and `AboutView`, without a separate actor boundary. |

## 3. `Task.detached` matrix

| Location | Current use | Classification | Where to refactor |
|---|---|---|---|
| `RsyncUI/Model/Storage/WriteSynchronizeConfigurationJSON.swift:40-50` | Writes encoded configuration JSON off the main actor | **Remove** | Replace with one shared storage writer that exposes an async API the caller can await. Detached write ordering is currently implicit and error delivery is indirect. |
| `RsyncUI/Model/Storage/WriteLogRecordsJSON.swift:40-50` | Writes encoded log JSON off the main actor | **Remove** | Same fix as configuration writes: move to a shared async persistence layer with explicit completion and error propagation. |
| `RsyncUI/Model/Execution/CreateHandlers/CreateStreamingHandlers.swift:92-95` | Debug-only assertion that streaming callbacks can run off the main actor | **Keep as an explicit exception** | This is one of the few valid uses of `Task.detached`: it intentionally sheds main-actor isolation to verify threading behavior. Leave it isolated to debug-only validation. |

## 4. `@MainActor` storage and helper types

These are the main-actor boundaries that most directly shape later cleanup work.

| Type | Location | Why it matters in Phase 1 | Classification | Where to refactor |
|---|---|---|---|---|
| `Homepath` | `RsyncUI/Model/FilesAndCatalogs/Homepath.swift:18-120` | Path creation, root directory creation, and error propagation are central to every persistence helper | **Centralize first** | Shared storage work should start here, because almost every read/write helper rebuilds paths from `Homepath`. |
| `ReadSynchronizeConfigurationJSON` | `RsyncUI/Model/Storage/ReadSynchronizeConfigurationJSON.swift:12-51` | Main configuration read path, reused in several loaders | **Centralize behind storage infrastructure** | Refactor into a shared JSON reader plus task-specific decode/filter logic. |
| `WriteSynchronizeConfigurationJSON` | `RsyncUI/Model/Storage/WriteSynchronizeConfigurationJSON.swift:12-57` | Main configuration write path, currently detached | **Centralize behind storage infrastructure** | Convert from initializer side effect into an awaited write operation. |
| `ReadUserConfigurationJSON` | `RsyncUI/Model/Storage/Userconfiguration/ReadUserConfigurationJSON.swift:12-35` | Reads user config and mutates `UserConfiguration` side effects | **Centralize** | Split decode from side effects so load/apply are separate steps. |
| `WriteUserConfigurationJSON` | `RsyncUI/Model/Storage/Userconfiguration/WriteUserConfigurationJSON.swift:12-50` | Direct sync write on main actor | **Centralize** | Move path building, encoding, and write into shared storage helpers. |
| `ReadSchedule` | `RsyncUI/Model/Storage/ReadSchedule.swift:12-48` | Reads schedule JSON and filters invalid/expired rows | **Centralize** | Keep schedule-specific filtering, but move decode/path logic into shared storage. |
| `WriteSchedule` | `RsyncUI/Model/Storage/WriteSchedule.swift:8-44` | Direct sync write on main actor | **Centralize** | Same shared write layer as other JSON persistence. |
| `ReadImportConfigurationsJSON` | `RsyncUI/Model/Storage/ExportImport/ReadImportConfigurationsJSON.swift:12-45` | Decodes import file and rewrites IDs in one object | **Convert to helper over shared storage** | Keep ID-rewrite logic, remove dedicated storage wrapper. |
| `WriteExportConfigurationsJSON` | `RsyncUI/Model/Storage/ExportImport/WriteExportConfigurationsJSON.swift:12-62` | Encodes and writes export bundle directly on main actor | **Convert to helper over shared storage** | Shared JSON export writer should own encode/write; export service should own only export-specific decisions. |
| `WriteWidgetsURLStringsJSON` | `RsyncUI/Model/Storage/Widgets/WriteWidgetsURLStringsJSON.swift:13-61` | Writes widget URL strings to the widget container and validates deeplinks | **Split responsibilities** | Keep deeplink validation, but move encode/write path logic into shared storage infrastructure. |
| `ReadAllTasks` | `RsyncUI/Model/Utils/ReadAllTasks.swift:11-97` | Repeats configuration loading across every profile | **Centralize** | It should call one shared profile/config loader instead of recreating per-profile read loops. |
| `UpdateConfigurations` | `RsyncUI/Model/Storage/Basic/UpdateConfigurations.swift:10-172` | Mutates configurations in memory and persists them immediately | **Keep temporarily, then shrink** | Once writes are centralized, this should become an in-memory mutation helper or a service method, not a persistence owner. |
| `Logging` | `RsyncUI/Model/Loggdata/Logging.swift:16-170` | Mixes config date stamping, log formatting, log insertion, snapshot numbering, and persistence | **Centralize behind log-data service** | This is a major later refactor target because it still owns both domain logic and persistence side effects. |

### Supporting model annotations that currently force main-actor storage paths

- `RsyncUI/Model/Storage/Basic/UserConfiguration.swift:10-11`
- `RsyncUI/Model/Storage/Basic/WidgetURLstrings.swift:10-11`

Both models are `@MainActor Codable`, which means Phase 2 must review whether the model isolation is intentional or whether the storage layer is carrying unnecessary main-actor constraints upward into encoding and decoding.

## 5. Persistence entry points and duplicate call paths

| Responsibility | Entry point | Current callers that reveal duplication | Refactor target |
|---|---|---|---|
| Read task configurations | `ReadSynchronizeConfigurationJSON.readjsonfilesynchronizeconfigurations` | `RsyncUIView.swift:71-73`, `extensionSidebarMainView.swift:170-172`, `ConfigurationsTableLoadDataView.swift:66-79`, `ReadAllTasks.swift:21-24` and `80-82` | One shared profile/config loader used by startup, profile switching, and cross-profile scans |
| Write task configurations | `WriteSynchronizeConfigurationJSON.init` | `Logging.swift:99`, `UpdateConfigurations.swift:33`, `ConfigurationsTableDataMainView.swift:231` | Shared async storage writer with explicit await |
| Read user configuration | `ReadUserConfigurationJSON.readuserconfiguration` | `RsyncUIView.swift:40-51` | Split into load + apply so startup does not hide side effects in a read helper |
| Write user configuration | `WriteUserConfigurationJSON.init` | `Environmentsettings.swift:16`, `Logsettings.swift:20`, `RsyncandPathsettings.swift:16`, `Sshsettings.swift:18` | Shared settings persistence helper |
| Read schedules | `ReadSchedule.readjsonfilecalendar` | `SidebarMainView.swift:117-120` | Shared schedule repository / loader |
| Write schedules | `WriteSchedule.init` | `AddSchedule.swift:88`, `CalendarMonthView.swift:77` | Shared schedule repository / writer |
| Read log store | `ActorReadLogRecords.readjsonfilelogrecords` via `LogStoreService.loadStore` | `Logging.swift:27-30`, `LogRecordsTabView.swift:156-160` and `183-187`, `SnapshotsView.swift:217-223` | One log-data service actor / repository |
| Write log store | `WriteLogRecordsJSON.init` | `Logging.swift:162`, `LogRecordsTabView.swift:149`, `SnapshotsView.swift:282` | Same log-data service actor / repository |
| Import configurations | `ReadImportConfigurationsJSON.init` | `ImportView.swift:125` | Import service over shared JSON storage |
| Export configurations | `WriteExportConfigurationsJSON.init` | `ExportView.swift:72` | Export service over shared JSON storage |
| Widget deeplink persistence | `WriteWidgetsURLStringsJSON.init` | `extensionAddTaskView.swift:49` | Widget settings writer over shared JSON storage |

## 6. Task inventory: what must stay async vs what should be simplified

### A. Task sites that are justified by correctness

| File and lines | Why it exists | Classification | Refactor note |
|---|---|---|---|
| `RsyncUI/Model/Execution/CreateHandlers/CreateStreamingHandlers.swift:34-36`, `70-72` | Hops streaming callback errors back to main-actor alert state | **Keep** | Could disappear only if the callback type itself becomes main-actor isolated. |
| `RsyncUI/Model/Execution/EstimateExecute/Estimate.swift:162-204` | Continues estimation flow after async output mapping from a termination callback | **Keep for now** | Later convert the termination pipeline itself into an async function so the callback does not need to spawn a task. |
| `RsyncUI/Model/Execution/EstimateExecute/Execute.swift:65-68`, `250-269`, `307-323` | Bridges rsync termination callbacks into async logging and persistence completion work | **Keep for now** | These are mandatory async boundaries today because process termination callbacks are synchronous. |
| `RsyncUI/Model/Global/GlobalTimer.swift:156-158`, `211-213` | Bridges `Timer` and workspace wake notifications back into main-actor schedule state | **Keep** | This is a legitimate sync-callback to async/main-actor bridge. |
| `RsyncUI/Model/Global/ObservableSchedules.swift:188-192` | Logs schedule execution asynchronously from a schedule callback | **Keep** | Safe to keep until logfile writes are fully centralized. |
| `RsyncUI/Views/Restore/RestoreTableView.swift:51-59` | Debounced restore filtering with cancellation | **Keep** | This is a valid UI debounce/cancellation pattern. |
| `RsyncUI/Views/InspectorViews/LogRecords/LogRecordsTabView.swift:84-94` | Debounced log filtering and profile reload cancellation | **Keep** | Good candidate for a reusable debouncer later, but the async behavior is required. |
| `RsyncUI/Views/Configurations/ListofTasksMainView.swift:63-75` | Debounced multi-select filter behavior | **Keep** | UI debounce task is acceptable. |
| `RsyncUI/Views/Sidebar/SidebarStatusMessagesView.swift:22-25`, `38-41` | Auto-dismiss transient UI notices | **Keep** | Simple delay task; not a concurrency problem. |
| `RsyncUI/Views/Quicktask/QuicktaskFormView.swift:35-41` | Delay before clearing fields after task-type change | **Keep** | Another valid UI delay task. |
| `RsyncUI/Views/Modifiers/ButtonStyles.swift:143-146` | Press-animation hold duration | **Keep** | Pure UI timing task. |
| `RsyncUI/Views/Tasks/CompletedView.swift:31-34` | One-second completion banner timeout | **Keep** | Pure UI timing task. |
| `RsyncUI/Views/Detailsview/SummarizedDetailsContentView.swift:173-176` | Delayed clearing of preselected task state | **Keep** | Pure UI timing task. |

### B. Task sites that are mostly sync-to-async adapters and should shrink later

| File and lines | What the task is compensating for | Classification | Where to refactor |
|---|---|---|---|
| `RsyncUI/Model/Process/InterruptProcess.swift:12-17` | Sync initializer uses `Task` only to log through `ActorLogToFile` before interrupting process state | **Convert** | Make interruption an explicit async function or hide logfile write inside a dedicated interruption service. |
| `RsyncUI/Model/Global/SharedReference.swift:111-114` | Delayed kill after `terminate()` | **Keep but isolate** | This is valid process-control timing, but it should live in a clearly named async termination helper instead of inline task creation. |
| `RsyncUI/Model/Global/ObservableRestore.swift:36-39` | Async output mapping after restore completes | **Convert** | Once `ActorCreateOutputforView` is removed, this can become a direct call. |
| `RsyncUI/Views/Restore/RestoreTableView.swift:191-196` | Async output mapping inside a main-actor view callback | **Convert** | Same `ActorCreateOutputforView` simplification target. |
| `RsyncUI/Views/Detailsview/OneTaskDetailsView.swift:154-173` | Async output mapping for presented estimate results | **Convert** | Remove the actor wrapper and call helper directly. |
| `RsyncUI/Views/InspectorViews/VerifyTask/VerifyTaskTabView.swift:170-173` | Async output mapping for verify results | **Convert** | Same output-helper cleanup. |
| `RsyncUI/Views/Quicktask/extensionQuickTaskView.swift:120-138` | Main-actor UI updates after async output conversion and progress updates | **Convert** | Output conversion should stop requiring actor hops. |
| `RsyncUI/Views/LogView/LogfileView.swift:44-47` | Sync button action wraps async logfile reset/read | **Convert partly** | Keep logfile read async, but remove the extra output-conversion actor layer. |
| `RsyncUI/Views/Configurations/ConfigurationsTableLoadDataView.swift:71-80` | `onChange` creates a task to re-read configurations | **Convert** | Replace with `.task(id:)` only, or centralize profile loading so both `.task(id:)` and `onChange` are not needed. |
| `RsyncUI/Views/Sidebar/extensionSidebarMainView.swift:63-83` | External deeplink flows launch tasks to await profile loading before navigation | **Convert later** | Move profile-loading flow into one async API instead of inline task creation. |
| `RsyncUI/Views/Sidebar/extensionSidebarMainView.swift:94-112` | Workspace mount/unmount notification closures create tasks to await profile reload checks | **Keep for callback bridge, but centralize** | The async bridge is valid; the duplicated load/check logic should move into one notification handler service. |
| `RsyncUI/Views/Snapshots/SnapshotsView.swift:216-224` | Snapshot/log merge is launched from a sync view method | **Convert later** | Prefer `.task(id:)` or one async `loadSnapshotData` entry point owned by the snapshot model/service. |
| `RsyncUI/Views/Snapshots/SnapshotsView.swift:269-271` | Two-second delay after updating snapshot plan, with no follow-up work | **Remove** | This task currently does not protect any real async dependency. |
| `RsyncUI/Views/Snapshots/SnapshotsView.swift:275-289` | Sync delete action wraps async log-store deletion | **Convert** | Once log-data persistence is unified, this becomes one awaited service call. |
| `RsyncUI/Views/InspectorViews/LogRecords/LogRecordsTabView.swift:53-56` | Delete action wraps async log-store deletion | **Convert** | Same future log-data service boundary as `SnapshotsView`. |
| `RsyncUI/Views/InspectorViews/LogRecords/LogRecordsTabView.swift:192-198` | Selection changes launch a task only to call actor filter/update methods | **Convert** | Removing actor ownership from pure filtering will make this synchronous again. |
| `RsyncUI/Views/Settings/Sshsettings.swift:82-86` | Delay before re-reading generated SSH keys | **Keep if UX needs the delay, otherwise convert** | Prefer an explicit async key-generation result instead of polling after sleep if possible. |

## 7. Mandatory async paths to preserve while refactoring

These are the safety rails for later phases. If any of these are removed too early, cleanup will likely change behavior.

1. **Rsync process streaming and termination callbacks**
   - `RsyncUI/Model/Execution/CreateHandlers/CreateStreamingHandlers.swift`
   - `RsyncUI/Model/Execution/EstimateExecute/Estimate.swift`
   - `RsyncUI/Model/Execution/EstimateExecute/Execute.swift`
   - `RsyncUI/Views/Restore/RestoreTableView.swift:218-230`

2. **Process termination / interrupt timing**
   - `RsyncUI/Model/Global/SharedReference.swift:103-116`
   - `RsyncUI/Model/Process/InterruptProcess.swift:8-19`

3. **Log-data read/write serialization**
   - `RsyncUI/Model/Storage/Actors/ActorLogToFile.swift`
   - `RsyncUI/Model/Storage/Actors/ActorReadLogRecords.swift`
   - `RsyncUI/Model/Storage/WriteLogRecordsJSON.swift`
   - `RsyncUI/Model/Loggdata/Logging.swift`

4. **UI debounce and cancellation flows**
   - `RsyncUI/Views/InspectorViews/LogRecords/LogRecordsTabView.swift`
   - `RsyncUI/Views/Restore/RestoreTableView.swift`
   - `RsyncUI/Views/Configurations/ListofTasksMainView.swift`
   - `RsyncUI/Views/Sidebar/SidebarStatusMessagesView.swift`
   - `RsyncUI/Views/Quicktask/QuicktaskFormView.swift`
   - `RsyncUI/Views/Modifiers/ButtonStyles.swift`

5. **Timer and workspace-notification bridges**
   - `RsyncUI/Model/Global/GlobalTimer.swift`
   - `RsyncUI/Model/Global/ObservableSchedules.swift`
   - `RsyncUI/Views/Sidebar/extensionSidebarMainView.swift:86-153`

## 8. Highest-value refactor seams for Phase 2 and Phase 3

1. **Shared JSON storage layer**
   - Start at `Homepath.swift`
   - Replace duplicated encode/decode/path/write code in:
     - `ReadSynchronizeConfigurationJSON.swift`
     - `WriteSynchronizeConfigurationJSON.swift`
     - `ReadUserConfigurationJSON.swift`
     - `WriteUserConfigurationJSON.swift`
     - `ReadSchedule.swift`
     - `WriteSchedule.swift`
     - `ReadImportConfigurationsJSON.swift`
     - `WriteExportConfigurationsJSON.swift`
     - `WriteWidgetsURLStringsJSON.swift`

2. **Thin actor removal**
   - Convert:
     - `ActorCreateOutputforView.swift`
     - `ActorGetversionofRsyncUI.swift`
   - Then simplify the task adapters in:
     - `OneTaskDetailsView.swift`
     - `VerifyTaskTabView.swift`
     - `ObservableRestore.swift`
     - `LogfileView.swift`
     - `extensionQuickTaskView.swift`

3. **Profile/configuration loader unification**
   - Consolidate read paths in:
     - `RsyncUIView.swift`
     - `extensionSidebarMainView.swift`
     - `ConfigurationsTableLoadDataView.swift`
     - `ReadAllTasks.swift`

4. **Log-data service completion**
   - Finish moving view-owned log mutations out of:
     - `LogRecordsTabView.swift`
     - `SnapshotsView.swift`
     - `Logging.swift`
   - Use `LogStoreService.swift` as the current destination instead of introducing a second parallel log abstraction.

## 9. Phase 1 checkpoints

- There is a documented owner for every actor.
- Every executable `Task.detached` site is either removed or explicitly justified.
- Every storage read/write path is mapped to one later shared storage API.
- Every `Task {}` site is classified as:
  - required callback bridge
  - valid UI debounce/delay
  - temporary sync-to-async adapter
  - removable
- No later phase should introduce a second configuration loader or a second log-data service while these inventories still point to existing shared seams.

If this file is used as the Phase 1 execution checklist, the safest first edits are:

1. convert `ActorGetversionofRsyncUI` into a plain async service,
2. remove `ActorCreateOutputforView` by replacing it with pure helpers, and
3. replace detached writes in `WriteSynchronizeConfigurationJSON` and `WriteLogRecordsJSON` with one awaited storage writer.
