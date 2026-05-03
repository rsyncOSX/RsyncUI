# RsyncUI cleanup plan

## Problem statement

RsyncUI has accumulated a mix of custom actors, `Task` usage, `@MainActor` file I/O, duplicated storage helpers, and large view/model types that make the code harder to reason about than necessary. The requested cleanup is to remove unnecessary concurrency machinery, keep concurrency only where it is truly justified, consolidate duplicate code, and simplify complex flows without changing user-visible behavior.

## Current-state findings

### Concurrency and isolation

- The app defines **five custom actors**:
  - `Model/Storage/Actors/ActorLogToFile.swift`
  - `Model/Storage/Actors/ActorReadLogRecordsJSON.swift`
  - `Model/Storage/Actors/ActorLogChartsData.swift`
  - `Model/Output/ActorCreateOutputforView.swift`
  - `Model/Newversion/ActorGetversionofRsyncUI.swift`
- Only the **log-data actors** clearly align with the desired retained-concurrency scope:
  - `ActorLogToFile`
  - `ActorReadLogRecordsJSON`
  - `ActorLogChartsData`
- Two actors are likely unnecessary and should be strong candidates for removal or conversion to plain services:
  - `ActorCreateOutputforView` mostly maps arrays into view models and delegates to other work.
  - `ActorGetversionofRsyncUI` is a thin wrapper around one fetch/filter operation.
- A number of storage helpers are annotated `@MainActor` while performing synchronous file-system work:
  - `ReadSynchronizeConfigurationJSON`
  - `ReadUserConfigurationJSON`
  - `ReadSchedule`
  - `WriteUserConfigurationJSON`
  - `WriteSchedule`
  - `WriteExportConfigurationsJSON`
  - `WriteWidgetsURLStringsJSON`
- `WriteLogRecordsJSON` and `WriteSynchronizeConfigurationJSON` use `Task.detached` fire-and-forget writes. That reduces main-thread blocking, but it also makes persistence ordering and error surfacing harder to reason about.
- `Execute.swift`, `CreateStreamingHandlers.swift`, and several SwiftUI views use many unstructured `Task {}` blocks. Some are appropriate UI/task-bound launches, but others are wrappers around small synchronous operations and should be reviewed for simplification.

### Duplication and structural complexity

- The storage layer repeats the same responsibilities in many places: build path, encode/decode JSON, write/read file, propagate error.
- Duplicate or near-duplicate call flows exist in:
  - startup/profile loading (`RsyncUIView`, `SidebarMainView`, `extensionSidebarMainView`, `ConfigurationsTableLoadDataView`)
  - log record reload/filter/delete (`Logging`, `LogRecordsTabView`, `SnapshotsView`, `ObservableChartData`)
  - export/import/widget/user-config persistence helpers
- Several large hotspot files are carrying mixed responsibilities and should be split or reduced before deeper cleanup:
  - `Model/Execution/EstimateExecute/Execute.swift` (335 lines)
  - `Views/Snapshots/SnapshotsView.swift` (299 lines)
  - `Views/Tasks/LogStatsChartView.swift` (293 lines)
  - `Views/Restore/RestoreTableView.swift` (272 lines)
  - `Views/Sidebar/SidebarMainView.swift` (268 lines)
  - `Model/Global/ObservableSchedules.swift` (263 lines)
  - `Model/Global/GlobalTimer.swift` (258 lines)

### Issues discovered during review

- The repository root contains `RsyncUI.xcodeproj`, but **does not contain `Package.swift`**, so the documented `swift test` command is not valid in this checkout.
- The current architecture documentation says storage runs on actors, but the codebase is already in a mixed state where some storage is actor-based, some is `@MainActor`, and some is detached-task based.
- Configuration/profile loading is implemented in multiple entry points instead of one shared loader, which increases the chance of behavior drift.
- Log filtering/sorting/deletion logic is repeated between inspector and snapshot flows instead of being centralized into one log-data service.

## Proposed approach

1. Establish an explicit concurrency boundary:
   - keep concurrency only where data volume or serialization warrants it
   - remove thin actors and accidental async wrappers
   - preserve necessary async behavior around rsync process streaming and UI lifecycle work
2. Consolidate storage code behind shared read/write helpers before removing wrappers one by one.
3. Centralize log-data operations so the remaining concurrency is concentrated in one place.
4. Refactor large mixed-responsibility types after shared services exist, so simplification reduces code instead of moving duplication around.
5. Update documentation and validation commands to match the actual Xcode-based project layout.

## Todo plan

### Phase 1 - Inventory and safety rails

- Build a full matrix of:
  - every actor
  - every `Task {}` / `Task.detached`
  - every `@MainActor` storage/helper type
  - every persistence entry point
- Classify each item as:
  - keep
  - convert to synchronous service
  - convert to async function without actor
  - centralize behind shared infrastructure
- Confirm which async paths are mandatory for correctness:
  - rsync process streaming
  - process termination callbacks
  - log-data read/write/sort pipeline
  - any UI-driven debounce/cancellation flows

### Phase 2 - Storage consolidation

- Introduce a shared storage abstraction for local JSON persistence:
  - path building
  - encode/decode
  - file write/read
  - uniform error propagation
- Migrate these helpers onto the shared storage layer:
  - `ReadSynchronizeConfigurationJSON`
  - `WriteSynchronizeConfigurationJSON`
  - `ReadUserConfigurationJSON`
  - `WriteUserConfigurationJSON`
  - `ReadSchedule`
  - `WriteSchedule`
  - import/export/widget persistence helpers
- Remove duplicated filename/path creation logic from individual helpers.
- Decide case-by-case whether the remaining API should be plain sync or async, but avoid detached fire-and-forget persistence unless it is explicitly needed.

### Phase 3 - Concurrency cleanup

- Keep and harden log-data concurrency:
  - `ActorLogToFile`
  - `ActorReadLogRecordsJSON`
  - `ActorLogChartsData`
- Review whether each retained actor really needs actor isolation or whether one log-data service actor is enough.
- Remove or replace thin actors:
  - `ActorCreateOutputforView`
  - `ActorGetversionofRsyncUI`
- Reduce unstructured `Task` usage in views and models where the work is:
  - immediate
  - non-cancellable
  - already on the main actor
  - simple synchronous mapping
- Replace ad hoc `Task.detached` writes with structured persistence where possible.

### Phase 4 - Log-data service unification

- Create one shared log-data domain service responsible for:
  - load
  - filter
  - sort
  - merge
  - delete
  - persist
  - chart preparation
- Move duplicate logic out of:
  - `Logging`
  - `LogRecordsTabView`
  - `SnapshotsView`
  - `ObservableChartData`
  - `LogStatsChartView`
- Keep UI views focused on state and presentation instead of storage mutations and log transforms.

### Phase 5 - High-value structural refactors

- Split `Execute.swift` into smaller components:
  - task queue/stack orchestration
  - process start
  - termination handling
  - log/config persistence
- Simplify schedule handling by separating:
  - schedule generation
  - timer orchestration
  - wake recovery
  - persistence
- Reduce duplication in profile/configuration loading across:
  - `RsyncUIView`
  - `SidebarMainView`
  - `extensionSidebarMainView`
  - `ConfigurationsTableLoadDataView`
- Extract reusable helpers from large SwiftUI views where code is mixing state coordination with data access.

### Phase 6 - Validation and documentation

- Run the real Xcode-based validation path for the repo and record the correct commands in docs.
- Update `CLAUDE.md` or other directly relevant documentation so it matches the actual project/test setup and the new storage/concurrency architecture.
- Add or update tests around refactored log-data and configuration-loading behavior before large removals of duplication.

## Recommended execution order

1. Inventory and classify concurrency/storage usage.
2. Consolidate storage helpers.
3. Unify log-data service.
4. Remove thin actors and simplify `Task` usage.
5. Refactor `Execute`, scheduling, and profile-loading hotspots.
6. Refresh validation/docs.

## Risks and considerations

- The rsync execution and streaming pipeline should not be simplified blindly; some async behavior is essential even if the app-owned actor count is reduced.
- Removing detached persistence without replacing it carefully may expose UI blocking or ordering assumptions that are currently hidden.
- Centralizing storage and log-data code first should reduce risk because later cleanups can become mostly mechanical call-site updates.
- Scope is limited to code in this repository, including local app targets such as the main app, widget, tests, and XPC code when touched by the cleanup. External rsyncOSX packages are out of scope for this plan.
