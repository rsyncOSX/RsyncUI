# Change Review: c59e3e3 through 65cef24

Reviewed range: `c59e3e3^..65cef24`, covering merge commit `c59e3e3` through `65cef24` inclusive.

Current branch/head reviewed: `version-3.0.3-tr` at `65cef24c6d6f9ee9c31222efe5f4aa947a2569fd`.

## Summary

This range is mainly a SwiftUI UI cleanup and consistency set. It adds destructive roles to delete confirmation buttons, removes a duplicated first-task creation view, converts add/edit task fields to grouped forms, moves sheet actions into toolbar placements, updates add-profile/task toolbar buttons to icon-only controls, moves the About sheet close action out of `AboutView`, hides the inspector tab label, and bumps `CURRENT_PROJECT_VERSION` from `197` to `200`.

No rsync execution, storage, parsing, scheduling model, or process pipeline logic was changed. The largest behavioral change is in the first-task workflow: instead of rendering the deleted `AddFirstTask` view, the app now opens the shared Add Task sheet when the active profile has no configurations.

## Commit Inventory

| Commit | Date | Author | Details |
|---|---:|---|---|
| `c59e3e37` | 2026-07-08 | Thomas Evensen | Merged PR #137, adding `role: .destructive` to delete buttons. |
| `744d2a91` | 2026-07-08 | Thomas Evensen | Merged PR #141, replacing `AddFirstTask` with the shared Add Task sheet. |
| `ffae3f9a` | 2026-07-08 | Thomas Evensen | Merged PR #140, moving the About sheet close button outside `AboutView`. |
| `1d0a8b82` | 2026-07-08 | Thomas Evensen | Merged PR #139, updating the Add Profile toolbar button. |
| `a81da0df` | 2026-07-08 | Thomas Evensen | Merged PR #138, moving sheet buttons into `ToolbarItem`s. |
| `85e47d0c` | 2026-07-08 | Thomas Evensen | Bumped Xcode project build number from `197` to `200`. |
| `6110ddbd` | 2026-07-08 | timreichen | Refactored Add Task UI: deleted helper views, converted content to grouped `Form`, replaced custom fixed-width fields with standard `TextField`s, and moved sheet actions into toolbar items. |
| `0b1033aa` | 2026-07-08 | timreichen | Follow-up task form update, mainly grouped form styling and field label cleanup. |
| `7f33d821` | 2026-07-08 | Thomas Evensen | Merged PR #142, using grouped form style for task fields. |
| `0b1da0f1` | 2026-07-08 | timreichen | Hid the inspector tab picker label. |
| `65cef24c` | 2026-07-08 | Thomas Evensen | Merged PR #143, removing the visible inspector tab label. |

The raw ancestry for the range also includes the PR branch commits `8e720a1c`, `bc3b2cc1`, `ea6799b4`, `38acc560`, and `64528c4d`, which are the side-branch commits merged by the PR merge commits above.

## Changelog

### Changed

- Delete confirmation dialogs now mark delete actions as destructive in task lists, schedule lists, and snapshot lists.
- The first-task experience now uses the same Add Task sheet as the regular add-task workflow.
- Add Task and Add Profile sheets now place Add/Cancel controls in SwiftUI toolbar confirmation/cancellation placements.
- Add Task fields now use a grouped `Form` layout with standard SwiftUI `TextField`s.
- Task action and trailing-slash pickers now use `.menu` picker style.
- The Add Profile toolbar button now uses a plus icon with an accessibility/help label.
- The Add Task toolbar button now uses a plus icon in the status toolbar placement.
- The About sheet close button is now owned by `RsyncUIApp` through the sheet toolbar.
- The inspector segmented picker label is hidden.
- The project build number was bumped from `197` to `200`.

### Removed

- Removed `AddFirstTask.swift`.
- Removed `AddTaskContentView.swift`.
- Removed `AddTaskSectionHeader.swift`.
- Removed the close button and `dismiss` dependency from `AboutView`.

## Technical Details

### Destructive Delete Roles

Files changed:

- `RsyncUI/Views/Configurations/ListofTasksAddView.swift`
- `RsyncUI/Views/Configurations/ListofTasksMainView.swift`
- `RsyncUI/Views/ScheduleView/CalendarMonthView.swift`
- `RsyncUI/Views/Snapshots/SnapshotListView.swift`

The delete buttons inside confirmation dialogs now use `Button("Delete", role: .destructive)`. This is a presentation/semantics improvement and should not alter the underlying delete calls.

### First Task Workflow

Files changed:

- `RsyncUI/Views/InspectorViews/AddFirstTask.swift`
- `RsyncUI/Views/InspectorViews/EditTabView.swift`
- `RsyncUI/Views/InspectorViews/InspectorView.swift`

`AddFirstTask` was deleted. `EditTabView` now always shows `ListofTasksAddView` and an always-present inspector, while `.task(id: rsyncUIdata.configurations)` opens the Add Task sheet when configurations are `nil` or empty.

This reduces duplicated add-task logic and routes first-task creation through `AddTaskView.addTaskSheetView`.

### Add Task Form Refactor

Files changed:

- `RsyncUI/Views/InspectorViews/Add/AddTaskView.swift`
- `RsyncUI/Views/InspectorViews/Add/extensionAddTaskView.swift`
- `RsyncUI/Views/InspectorViews/Add/extensionAddTaskView+FormFields.swift`
- `RsyncUI/Views/InspectorViews/Add/extensionAddTaskView+ViewBuilders.swift`
- `RsyncUI/Views/InspectorViews/Add/OpencatalogView.swift`

The old custom wrapper views were replaced with an inline grouped `Form`. The sheet body now has the same core fields as the edit inspector: task type, trailing slash, synchronize ID, folders, and remote fields.

Important behavior retained:

- `handleSubmit()` still advances focus and submits add/update on return.
- `showAddPopover` still resets form state when opening.
- `addConfig()` still validates through `ObservableAddConfigurations.addConfig`.
- `validateAndUpdate()` still updates through `ObservableAddConfigurations.updateConfig`.
- Duplicate checking still runs after a successful add when enabled.

Main visual changes:

- Standard `TextField` replaces `EditValueScheme` for most Add Task fields.
- Fixed field widths were removed.
- Section headers are now standard `Section("...")` labels.
- Browse button sizing is now left to `.buttonStyle(.bordered)`.

### Sheet Toolbar Buttons

Files changed:

- `RsyncUI/Main/RsyncUIApp.swift`
- `RsyncUI/Views/Profiles/ProfileView.swift`
- `RsyncUI/Views/Settings/AboutView.swift`
- `RsyncUI/Views/InspectorViews/Add/extensionAddTaskView+ViewBuilders.swift`

The Add Task, Add Profile, and About sheet actions are now represented as toolbar items with `.confirmationAction` and `.cancellationAction` placements where appropriate. The About close action is controlled by `showabout` in `RsyncUIApp`.

### Inspector Label

File changed:

- `RsyncUI/Views/InspectorViews/InspectorView.swift`

The segmented inspector picker now has `.labelsHidden()`, removing the visible picker label while preserving the segments.

## Review Findings

No blocking bugs were found in this range.

### Risk: About Changelog No Longer Dismisses Sheet

`AboutView.openChangelog()` still opens the changelog URL, but the previous `dismiss()` call was removed from the Changelog button when `dismiss` was removed from `AboutView`.

Current code: `RsyncUI/Views/Settings/AboutView.swift`, lines 61-67.

This is not necessarily wrong. It may be intentional because the sheet now has a toolbar Close button. It is a behavior change users may notice: after opening the changelog, the About sheet remains open.

Risk level: low.

### Risk: Empty-Profile UI Now Shows Empty List/Inspector Behind Add Sheet

`EditTabView` now opens the Add Task sheet when configurations are empty, while keeping the list and inspector visible.

Current code: `RsyncUI/Views/InspectorViews/EditTabView.swift`, lines 28-38.

If the user cancels the Add Task sheet on an empty profile, they remain on an empty task list with the inspector visible. This is probably acceptable, but it is a UX behavior change from the dedicated `AddFirstTask` view.

Risk level: low to medium.

### Risk: Task Field Layout Changed from Fixed Width to Form-Managed Width

Most Add Task fields changed from `EditValueScheme(400, ...)` to plain `TextField(...)` inside a grouped `Form`.

Current code: `RsyncUI/Views/InspectorViews/Add/extensionAddTaskView+FormFields.swift`, lines 13-146.

This is idiomatic SwiftUI and compiled successfully, but visual layout should be manually checked on the supported macOS versions because field widths and red validation borders may render differently inside grouped forms.

Risk level: low to medium.

### Risk: Toolbar Buttons in Sheets Need Manual UI Verification

Add/Cancel buttons were moved into toolbar placements. The code compiles, but toolbar placement and visibility in macOS sheets can be sensitive to window/sheet style.

Files to verify:

- `RsyncUI/Views/InspectorViews/Add/extensionAddTaskView+ViewBuilders.swift`
- `RsyncUI/Views/Profiles/ProfileView.swift`
- `RsyncUI/Main/RsyncUIApp.swift`

Risk level: low.

## Merge Risk Assessment

Overall merge risk into `main`: low to medium.

Reasons the risk is low:

- The changes are almost entirely SwiftUI presentation changes.
- No rsync execution pipeline, storage actors, JSON formats, process streaming, parser, or schedule model logic changed.
- The shared Add Task workflow removes duplicated code instead of adding a second path.
- Delete changes are limited to SwiftUI button roles.
- The project builds and the test suite passes.

Reasons it is not zero:

- The first-task workflow changed behavior.
- Add Task fields changed layout and control types.
- Sheet controls moved into toolbars, which should be visually checked on macOS.
- Existing tests are primarily model/business-logic tests, not UI workflow tests.

## Verification Performed

Command run:

```bash
xcodebuild test -project RsyncUI.xcodeproj -scheme RsyncUI -destination 'platform=macOS'
```

Result:

- Build succeeded.
- Test run succeeded.
- 56 Swift Testing tests passed across 9 suites.

Additional check:

```bash
git diff --check c59e3e3^..65cef24
```

Result:

- No whitespace or patch formatting problems reported.

## Recommended Manual Smoke Tests Before Merge

1. Open a profile with no tasks. Confirm the Add Task sheet appears automatically.
2. Cancel the Add Task sheet on an empty profile. Confirm the remaining UI state is acceptable.
3. Add a synchronize task, a snapshot task, and a syncremote task from the new sheet.
4. Edit an existing task and confirm fields populate correctly.
5. Verify red validation borders still appear for incomplete local/remote and remote user/server pairs.
6. Confirm Add/Cancel toolbar buttons are visible and work in Add Task and Add Profile sheets.
7. Open About, open Changelog, and decide whether the About sheet should remain open or close.
8. Delete one and multiple tasks, schedules, and snapshots; confirm destructive button styling appears and delete behavior is unchanged.

## Conclusion

This range is acceptable to merge after a short manual UI smoke test pass. The automated test signal is good, and the code changes are scoped to UI presentation and first-task workflow consolidation. The main thing to verify manually is not data correctness but macOS sheet and form behavior.
