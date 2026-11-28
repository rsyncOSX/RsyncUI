# RsyncUI 3.6.0 (build 218): Swift and SwiftUI changes

Compared: RsyncUI 3.6.0 build 218 (branch `version-3.6.0`) against RsyncUI 3.5.1 build 217 (`c2792f65`).
The changes come from RsyncUI-next, where they were tested as 3.9.0 (a preview of 4.0.0).
The Swift code of 3.6.0 is the same as RsyncUI-next.
Only `.swift` files are included. Resources, localizations and the Xcode project are left out.

## Short list

1. **App Intents (Shortcuts, Siri, Spotlight):** new *Estimate Tasks* and *Synchronize Tasks* intents. They run without the main window.
2. **Shortcuts approval:** a task can only run from Shortcuts after you verify it and allow it. Changing the task's settings removes the approval.
3. **Tasks that need rsync 3.x are kept:** with openrsync, snapshot and remote pull tasks are hidden, not deleted from disk.
4. **Unreadable log records file:** it is never overwritten. It is moved aside, or left as it is.
5. **Large logfile:** it no longer marks a successful sync as failed.
6. **Silent rsync failures:** a non-zero exit code is now shown even when "Check for error in output" is off.
7. **Global SSH port and key:** these are now passed to rsync. Rsync daemon tasks still do not get them.
8. **Remote server check:** uses the configured SSH port instead of always using port 22.
9. **Snapshot tagging around New Year:** weeks and previous months that cross a year boundary are tagged correctly.
10. **Estimate before synchronize:** the estimate has to cover the current selection, and incomplete estimates need confirmation.
11. **New confirmation sheet:** shows which tasks will run and warns when deletion is enabled.
12. **Backup toggle and argument slots:** the backup toggle shows what rsync will really do, and only argument slots in use are shown.
13. **Trailing slash on remote pull:** it is applied to the source, which for a remote pull is the remote folder.
14. **Command preview:** shows the real command, quoted so it can be pasted into a shell, with a Copy button.
15. **UI refresh:** headers on each workspace, inspector tabs with icon and caption, a bottom action bar, Save buttons, and wording, empty states and accessibility.
16. **Keyboard command plumbing:** the hidden "trigger" views are replaced by `onChange`, and menu commands are disabled when they cannot be used.
17. **Smaller display fixes:** "1 file" instead of "1 files", correct singular and plural for min/hour/day, and "Never run" for new tasks.
18. **Tests:** 13 new test files cover the fixes above.

---

## Details

### 1. App Intents – `Model/Intents/RsyncUIIntents.swift`, `HeadlessRunner.swift` (new)

**What:** Two intents, `EstimateTaskIntent` and `RunTaskIntent`, take a Profile and an optional list of Tasks. Synchronize also has an optional *Maximum Deletions* setting. The `HeadlessRunner` reads settings and finds the rsync version when RsyncUI is launched only for an intent. It runs one job at a time, and refuses to start while the app window is running a task. It quits the app a few seconds after the intent if no window is open. Tasks are identified as `profile#hiddenID`, because the `UUID` is created again on every read. `Estimate.start` now has an `onComplete` callback so it can be used without a view.

**Why:** It lets you run unattended backups from Shortcuts, Siri, Spotlight or `shortcuts run`. The safety checks are strict because no one is watching:
- The synchronize intent always estimates first.
- It stops if the *Confirm execute* setting flags a suspicious estimate.
- It stops if the number of deletions is above the limit.
- It stops if a local source that `--delete` would mirror is missing or empty, for example an external drive that is not mounted. Running in that case would empty the destination.

### 2. Shortcuts approval – `ShortcutsApproval.swift` (new), `SynchronizeConfiguration`, `UpdateConfigurations`, `VerifyTaskTabView`, `ConfigurationNameLabel` (new)

**What:** A new optional field, `shortcutsapproval`, is stored in the task JSON. It holds a SHA-256 fingerprint of the settings that decide what rsync does: task type, paths, user, server, parameters 4 and 8–14, daemon flag, SSH port and SSH key. The Verify tab has a toolbar toggle, green for allowed and red for not allowed. You can only allow a task after a completed verify run. Imported, pasted and copied tasks start with no approval. The task list shows a green checkmark for allowed tasks and a trash icon for tasks that use `--delete`.

**Why:** Shortcuts must never run a task you have not checked. Because the approval is a fingerprint, any later change to the task's settings revokes it automatically.

### 3. Hidden rsync 3.x tasks are preserved – `HiddenConfigurations.swift` (new), `Read/WriteSynchronizeConfigurationJSON`, `UpdateConfigurations.maxhiddenID`, `LogStoreService`

**What:** When RsyncUI runs with openrsync, snapshot and syncremote tasks were dropped when the file was read. They are now stored per profile in memory, and they are merged back when the file is written. Their hiddenIDs are counted when a new ID is assigned. Their log records are also kept when logs are deleted.

**Why:** **Data loss bug.** Saving any change while running openrsync used to rewrite the task file without these tasks, so they were deleted for good. New tasks could also reuse their IDs, which mixed up the log records.

### 4. Unreadable log records file – `LogStoreService.loadStoreForWriting`, `Logging`

**What:** A missing file is still treated as empty. A file that exists but cannot be decoded is now renamed to `…​.unreadable-yyyyMMdd-HHmmss` and you are told about it. If the rename fails, nothing is written.

**Why:** **Data loss bug.** Before, a decode error gave an empty store, and the next write replaced the whole log history with one new record.

### 5. Large logfile is a warning, not a failure – `ActorLogToFile`

**What:** The size check runs after the write has succeeded. Its warning is shown once per session, and again after a reset. It no longer throws inside the write path.

**Why:** A logfile above the size limit used to make `writeloggfile` return `false`, so a successful sync was reported as failed.

### 6. Report silent rsync failures – `CreateStreamingHandlers`

**What:** `createResultHandlers` now shows a `RsyncFailureAlert` with the exit code when the process failed, the exit code is non-zero, and no other error has been reported.

**Why:** With *Check for error in output* turned off, a failed rsync run used to end with no message at all.

### 7. Global SSH settings are applied – `SSHParams`, `Params`

**What:** A value that is not set is now passed as `nil` instead of `""`. `Params` uses `SSHParams` instead of keeping its own copy of the code. Rsync daemon tasks (`host::module`) never get the global port or key.

**Why:** `RsyncArguments` treats any non-nil port, including `""`, as the task's own setting. Because of that, the global SSH port and key from Settings were always ignored. Daemon tasks are excluded because adding `-e ssh` would make rsync run the daemon over SSH instead of connecting to port 873.

### 8. Remote server check uses the right port – `VerifyConfiguration`

**What:** The check now uses the task's own port, then the global port, then 22. Before, it always used port 22.

**Why:** Snapshot tasks for servers on a custom SSH port failed with "not connected" even when the server could be reached.

### 9. Snapshot tagging across New Year – `TagSnapshots`

**What:** "This week" now compares `weekOfYear` together with `yearForWeekOfYear`. "Previous month" uses calendar arithmetic, so in January the previous month is December of last year. "Now" can be injected for tests.

**Why:** In the week around New Year and in January, snapshots were tagged wrongly. `month == monthToday - 1` is never true in January, and the same ISO week can have different calendar years. Snapshots could end up marked for delete or keep by mistake.

### 10. Estimate must cover what will run – `Estimate`, `RemoteDataNumbers.hasUsableStatistics`, `TasksView`, `SummarizedDetailsView/ContentView`, `ExecuteEstTasksView`, `OneTaskDetailsView`

**What:**
- An estimate only counts as complete when every requested task has a record with usable statistics.
- *Synchronize* only uses an existing estimate if it belongs to the current profile and covers the whole current selection.
- Records with no stats are left out of the "estimated" run.
- Single-task dry runs now record their profile.
- An incomplete estimate shows *Review Incomplete Estimate…*.
- The external URL completion only finishes when every task reports zero changes.

**Why:** Before, a partial or failed estimate, or an estimate from another selection or profile, could be treated as approval to synchronize everything. The run could then go ahead with unknown changes.

### 11. Synchronize confirmation sheet – `SynchronizeConfirmationView` (new), `TasksView`

**What:** This replaces the old "Synchronize all tasks without estimating first?" alert. It shows the tasks in scope, or the source and destination for a single task. It warns when any effective rsync argument deletes files (`--delete*`). It offers *Estimate (Dry Run)*, *Synchronize Now* and, after an incomplete estimate, *Synchronize Estimated Tasks*.

**Why:** Running without an estimate is a risky choice, so you should see what will run and whether files may be deleted before you confirm. The same deletion check is used by the App Intents.

### 12. Rsync options: backup toggle and argument slots – `ObservableParametersRsync`, `RsyncParametersView`, `EditRsyncParameter`

**What:** The backup state is now read from the arguments themselves (`-b`, `--backup`, `--backup-dir`). Turning it on fills free slots and does not overwrite other arguments. Turning it off removes only the backup arguments. Only argument slots in use are shown, and an *Add Argument* button adds a new one. The "Danger Zone" box is replaced by a *Destination behavior* group, which shows a deletion warning when `--delete` is on. There is one *Save* button, which is enabled only when something has changed.

**Why:** The old toggle was a separate `@State`. It could disagree with the stored arguments, and it always wrote to parameters 12 and 13, overwriting whatever you had put there.

### 13. Trailing slash on a remote pull – `ObservableAddConfigurations.applyTrailingSlashToSource`, `AddTaskView`

**What:** The slash is added to the remote folder for syncremote tasks, and to the local folder otherwise. It is applied once in `addConfigAndDismiss`, which also guards against a double submit with `isAdding`. A *Save* button, enabled by `hasUnsavedChanges`, replaces *Update*. A segmented task type picker and a "What this task will do" summary are added.

**Why:** For a remote pull, the slash was added to the destination. That changes what rsync copies. Pressing Return could also add the same task twice.

### 14. Command preview – `ShellCommand.swift` (new), `RsyncCommandtoDisplay`, `OtherRsyncCommandtoDisplay`, `RsyncCommandView`

**What:** The displayed commands are now built from the real (non-dry-run) arguments, and each argument is quoted for the shell. Arguments with spaces, `~` and similar characters are single-quoted. A monospaced preview has a Copy button.

**Why:** The old text joined the arguments without separators or quoting, and replaced commas with spaces. It was not the command RsyncUI actually runs, and pasting it into Terminal could fail or behave differently.

### 15. UI refresh (SwiftUI)

- `TaskWorkspaceHeading` is shared by Synchronize, Tasks, Restore and Snapshots. It shows the profile, the number of tasks and the number selected.
- The inspector shows the task name and badge, and an icon-and-caption `InspectorTabBar` (General, Rsync Options, Logs, Verify) replaces the segmented control. Selecting more than one task shows "Select a task".
- A bottom `SynchronizeActionBar` holds *Estimate (Dry Run)* and *Synchronize*. These moved from the toolbar.
- The estimate page has a `PreflightOverview` with totals for created, transferred, deleted and transfer size. One detail table replaces the two side-by-side tables.
- Progress is shown in a bar under the table (`safeAreaInset`) instead of an overlay on top of it.
- The sidebar merges "Management" into "Tools", with new SF Symbols.
- Toolbar buttons show both title and icon, and the window title is "RsyncUI" throughout.
- Empty states now separate "loading", "empty" and "no match for this filter" (task list and log history). Status dots have help text and accessibility labels.
- Shared helpers `displaySourcePath`, `displayDestinationPath` and `displaysRemoteSource` replace several copies of `isRemotePull`.
- Column widths are adjusted, and the "synchronize" badge is hidden in narrow tables.

**Why:** To make the redesign consistent and clearer, to make the main actions easy to find, and to improve accessibility. It also removes repeated code.

### 16. Keyboard command plumbing – `TasksView`, `ExecuteEst/NoEstTasksView`, `SummarizedDetailsView`, `ExecuteCommands`; removed `TasksFocusActionsView.swift`

**What:** The hidden `Label("", "play.fill").onAppear { … }` views that started actions are replaced by `.onChange(of:)`. ⌘E, ⌘R and ⌘K are disabled when the current view does not support them. `executetasksinprogress` is now set and cleared on every path, including abort and disappear.

**Why:** The old trick was fragile. Actions could fire twice or not at all, and the invisible views took up space in the layout. An aborted unestimated run also left the in-progress flag set and did not return to Synchronize.

### 17. Smaller display fixes – `extensions.swift`, log and snapshot tables, `ProfilesToUpdateView`, `ConfigurationsTableDataMainView`

- `displayedRunResult` shows "1 file" instead of "1 files" on screen. The stored text is not changed.
- `Double.latest()` uses the singular for the rounded value 1 only. Before, 1.6 hours showed as "1.6 hour".
- `lastRun` returns `nil` for an empty `dateRun`, so new tasks show "Never run" instead of a strange date. A relative "… ago" text is added.
- The "not due" colour in Profiles is `.primary` instead of `.white`, which could not be read in light mode.

### 18. New unit tests – `RsyncUITests/`

`CommandDisplayTests`, `DisplayTextTests`, `GlobalSSHSettingsTests`, `HiddenConfigurationsTests`, `LogfileSizeWarningTests`, `ObservableParametersRsyncTests`, `ShortcutsApprovalTests`, `SnapshotSSHPortTests`, `SynchronizeScopeTests`, `TagSnapshotsTests`, `UnreadableLogStoreTests` and `UnreportedFailureAlertTests` are new. `ObservableAddConfigurationsTests` is extended.
