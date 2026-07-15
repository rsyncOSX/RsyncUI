# Verification and Issue Report

Updated: 2026-07-15

Reviewed range: `c59e3e3^..49ceaea2` (`c59e3e3` through the current `HEAD`, inclusive).

Previous review head: `1f246395`

Branch reviewed: `version-3.0.4-tr`

Scope: 43 commits, 24 changed files, 719 insertions, and 475 deletions.

## Summary

The original P1 task-type defect is resolved. The update model now loads the selected configuration's task type, and add-only preferences no longer overwrite update-mode state.

The two original P2 issues are not fully resolved. The automatic Add Task sheet can still remain latched after configurations finish loading, and the new submit handler shares focus correctly but invokes `handleSubmit()` against the parent edit model instead of the sheet's local add model. In addition, the latest merge leaves two identical Add toolbar actions in `AddTaskSheetView`.

The branch builds successfully and all 56 automated tests pass, but the remaining issues are SwiftUI workflow defects not covered by the current model-focused test suite.

Priority definitions:

- **P1**: High priority; can cause an action to mutate the wrong task/model.
- **P2**: Medium priority; user-visible workflow or presentation regression.
- **P3**: Low priority; maintainability, formatting, or documentation defect.

## Resolution Status

| Original finding | Status | Verification |
|---|---|---|
| P1 — Update mode does not load the selected task type | **Resolved** | `updateview(_:)` now maps `config.task` into `selectedrsynccommand`; update-mode `TaskForm` no longer loads add preferences on appearance. |
| P2 — Return/submit handling was lost from the Add Task sheet | **Not resolved; fix targets wrong model** | The sheet now receives focus and an `onSubmit` closure, but the closure is the parent `AddTaskView.handleSubmit`, which reads and mutates the parent's `newdata`, not the sheet's local `newdata`. |
| P2 — Automatic and user-requested sheet presentation share a latched Boolean | **Not resolved** | The implementation changed from `.task` to `.onChange`, but the `if !showAddPopover` guard prevents a sheet automatically opened for transient `nil` configurations from closing when a nonempty list arrives. |
| P3 — Changed Swift files fail formatting checks | **Partially resolved** | `git diff --check` is now clean, but SwiftLint still reports five changed-file warnings and SwiftFormat reports three of five reviewed files require formatting. |
| P3 — `changestr.md` is stale | **Not resolved** | The document still ends its review at `65cef24`/version 3.0.3 and contains assertions superseded by later commits. |

## Resolved Finding

### Resolved P1 — Update mode now loads the selected task type

Relevant code:

- `RsyncUI/Model/Global/ObservableAddConfigurations.swift:123-145`
- `RsyncUI/Views/InspectorViews/Add/TaskForm.swift:165-183`

`ObservableAddConfigurations.updateview(_:)` now sets:

```swift
selectedrsynccommand = TypeofTask(rawValue: config.task) ?? .synchronize
```

It resets the value to `.synchronize` when the selection is cleared. The trailing-slash and rsync-command preference loaders were also moved from the shared form into `AddTaskSheetView`, so selecting an existing snapshot or `syncremote` task is no longer overwritten by add-form defaults.

Static flow verification confirms that update layout and `VerifyConfiguration` now receive the selected task type. No new automated regression test was added for this behavior, so a targeted model test remains recommended.

## Open Findings

### P1 — Add-sheet Return invokes submit logic on the parent edit model

Affected code:

- `RsyncUI/Views/InspectorViews/Add/AddTaskSheetView.swift:13-14`
- `RsyncUI/Views/InspectorViews/Add/AddTaskSheetView.swift:36-43`
- `RsyncUI/Views/InspectorViews/Add/AddTaskView.swift:59-65`
- `RsyncUI/Views/InspectorViews/Add/extensionAddTaskView+BusinessLogic.swift:20-43`

`AddTaskSheetView` owns the form data entered by the user:

```swift
@State var newdata = ObservableAddConfigurations()
```

However, `AddTaskView` presents the sheet with `onSubmit: handleSubmit`. That method belongs to the parent edit view and reads the parent's separate `newdata` property. Sharing `$focusField` lets Return advance focus, but the final Return on the remote-server field does not submit the sheet data.

Consequences:

- With no selected task, final Return tries to add the empty parent model, so the sheet values are not added.
- With an existing task selected behind the sheet, final Return takes the update branch and can rewrite/reset the selected task even though the user is interacting with Add Task.
- The sheet remains open because this path does not invoke `onAdd(sheetNewdata)`.

The sheet should own its focus state and submit policy, or its submit callback must receive the sheet's `newdata`. The final field should call the same add action as the toolbar Add button.

### P2 — Add Task sheet declares the Add toolbar action twice

Affected code:

- `RsyncUI/Views/InspectorViews/Add/AddTaskSheetView.swift:44-67`

The final merged view applies two `.toolbar` modifiers, and each contains an identical `.confirmationAction` Add button. The second toolbar also contains Cancel. The same `.padding()` and `.frame(minWidth: 600)` chain is duplicated around them.

Depending on toolbar preference composition, the sheet can display two Add actions. Even where SwiftUI collapses or overrides one toolbar, the duplicated action and layout chain are unintended merge residue and make behavior fragile.

Keep one padding/frame chain and one toolbar containing exactly one Add action and one Cancel action.

### P2 — Automatic Add Task presentation remains latched

Affected code:

- `RsyncUI/Views/InspectorViews/EditTabView.swift:13`
- `RsyncUI/Views/InspectorViews/EditTabView.swift:28-32`
- `RsyncUI/Views/InspectorViews/EditTabView.swift:38-48`

Current logic:

```swift
.onChange(of: rsyncUIdata.configurations, initial: true) {
    if !showAddPopover {
        showAddPopover = rsyncUIdata.configurations?.isEmpty ?? true
    }
}
```

If initial configurations are temporarily `nil`, this sets `showAddPopover = true`. When asynchronous loading later supplies a nonempty list, the guard is false because the sheet is already presented, so the state is never corrected. A populated profile can therefore retain a spurious Add Task sheet.

Automatic first-task presentation should use state separate from user-requested toolbar presentation, or it should wait until configuration loading has definitively completed.

### P3 — Formatting checks still fail on changed Swift files

Current results:

- `git diff --check c59e3e3^..HEAD`: **passes**.
- SwiftLint: five warnings in changed files.
- SwiftFormat: three of five reviewed files require formatting.

Changed-file SwiftLint warnings:

- `RsyncUI/Views/InspectorViews/EditTabView.swift:26` — vertical whitespace before closing brace.
- `RsyncUI/Views/InspectorViews/EditTabView.swift:29` — redundant parentheses around the `if` condition.
- `RsyncUI/Views/InspectorViews/Add/extensionAddTaskView+BusinessLogic.swift:75` — vertical whitespace before closing brace.
- `RsyncUI/Views/InspectorViews/Add/TaskForm.swift:33` — consecutive blank lines.
- `RsyncUI/Views/InspectorViews/Add/TaskForm.swift:242` — vertical whitespace before closing brace.

SwiftFormat additionally reports modifier-chain indentation in `AddTaskView` and existing formatting rules throughout `TaskForm`.

### P3 — `changestr.md` remains stale

Affected code:

- `changestr.md:1-5`
- `changestr.md:22-27`
- `changestr.md:90-95`
- `changestr.md:124-126`

The committed report reviews only through `65cef24` on `version-3.0.3-tr`. It does not represent the current 3.0.4 branch and still states that Add Task submit behavior was retained. Update or remove it to avoid conflicting verification records.

## Verification Performed

### Repository build command

Command:

```bash
make debug
```

Result: **did not reach compilation**. The unchanged notification wrapper still fails:

```text
osascript: syntax error: A identifier can’t go after this identifier. (-2740)
make: *** [archive-debug] Error 1
```

### Direct Debug build

Command:

```bash
xcodebuild build \
  -project RsyncUI.xcodeproj \
  -scheme RsyncUI \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  CODE_SIGNING_ALLOWED=NO
```

Result: **BUILD SUCCEEDED**.

### Tests

Command:

```bash
xcodebuild test \
  -project RsyncUI.xcodeproj \
  -scheme RsyncUI \
  -destination 'platform=macOS,arch=arm64' \
  CODE_SIGNING_ALLOWED=NO
```

Result: **TEST SUCCEEDED** — 56 Swift Testing tests passed across 9 suites.

No tests were added for update-form task-type initialization, sheet-local submit behavior, duplicate toolbar actions, or asynchronous sheet presentation.

### Patch and style checks

Commands:

```bash
git diff --check c59e3e3^..HEAD
swiftlint lint --config .swiftlint.yml --quiet
swiftformat --lint <reviewed-files> --config .swiftformat
```

Results:

- Diff check passes.
- SwiftLint still exits nonzero because of its cache-permission error and repository-wide identifier-name violations; five warnings are in files changed by this range.
- SwiftFormat reports three of five reviewed files require formatting.

## New Commit Review (`1f246395..49ceaea2`)

| Commit | Assessment |
|---|---|
| `60ebc5a1` — issue doc | Added the original `issues.md` report. |
| `747e22f8` — submit fix | Added shared focus binding and submit plumbing, but routes submit to the parent edit handler/model. |
| `49031146` — P1 fix | Loads the selected task type and moves add preferences out of the shared form. |
| `9e4bb4a5` — P1 follow-up | Resets task type when selection is cleared. |
| `6c7051ce` — merge PR #156 | P1 fix is present and verified in the cumulative result. |
| `5684694c` — presentation fix | Replaced `.task(id:)` with `.onChange(..., initial: true)`. |
| `b1d55f84` — presentation follow-up | Added the `!showAddPopover` guard, which preserves the transient-`nil` latch. |
| `4a53bfcb` — merge PR #157 | Automatic sheet issue remains in the cumulative result. |
| `066b8852` — branch merge | Conflict integration leaves duplicated Add toolbar/layout code in `AddTaskSheetView`. |
| `49ceaea2` — merge PR #158 | Current head builds/tests, but submit targets the wrong model and duplicate toolbar actions remain. |

## Full Commit Inventory

All 43 commits reachable in the requested inclusive range were reviewed:

| Commit | Date | Author | Subject |
|---|---|---|---|
| `8e720a1c` | 2026-07-07 | timreichen | initial commit |
| `c59e3e37` | 2026-07-08 | Thomas Evensen | Merge pull request #137 from timreichen/add-destructive-button-role |
| `ea6799b4` | 2026-07-07 | timreichen | initial commit |
| `744d2a91` | 2026-07-08 | Thomas Evensen | Merge pull request #141 from timreichen/remove-add-first-task |
| `64528c4d` | 2026-07-07 | timreichen | initial commit |
| `ffae3f9a` | 2026-07-08 | Thomas Evensen | Merge pull request #140 from timreichen/move-AboutView-close-button |
| `38acc560` | 2026-07-07 | timreichen | initial commit |
| `1d0a8b82` | 2026-07-08 | Thomas Evensen | Merge pull request #139 from timreichen/update-Add-Profile-Button |
| `bc3b2cc1` | 2026-07-07 | timreichen | initial commit |
| `a81da0df` | 2026-07-08 | Thomas Evensen | Merge pull request #138 from timreichen/sheet-toolbar-buttons-2 |
| `85e47d0c` | 2026-07-08 | Thomas Evensen | updates tr |
| `6110ddbd` | 2026-07-08 | timreichen | initial commit |
| `0b1033aa` | 2026-07-08 | timreichen | update |
| `7f33d821` | 2026-07-08 | Thomas Evensen | Merge pull request #142 from timreichen/use-form-style-for-task-fields |
| `0b1da0f1` | 2026-07-08 | timreichen | initial commit |
| `65cef24c` | 2026-07-08 | Thomas Evensen | Merge pull request #143 from timreichen/remove-inspector-tab-label |
| `deb1dc0b` | 2026-07-08 | Thomas Evensen | changes.md |
| `938e512b` | 2026-07-08 | Thomas Evensen | changes.md |
| `9f5c51e1` | 2026-07-13 | Thomas Evensen | Merge pull request #147 from rsyncOSX/version-3.0.3-tr |
| `6eada0ea` | 2026-07-13 | timreichen | initial commit |
| `e733fff0` | 2026-07-13 | timreichen | update |
| `f4c6933d` | 2026-07-13 | timreichen | update |
| `a348e892` | 2026-07-13 | Thomas Evensen | Merge pull request #148 from timreichen/add-task-form-and-sheet |
| `e879dda2` | 2026-07-13 | Thomas Evensen | version 3.0.4 |
| `144a9541` | 2026-07-13 | timreichen | initial commit |
| `689b61de` | 2026-07-14 | Thomas Evensen | Merge pull request #150 from timreichen/separate-add-and-update-views |
| `291ad565` | 2026-07-13 | timreichen | initial commit |
| `9a59b9e7` | 2026-07-14 | timreichen | Merge remote-tracking branch 'refs/remotes/timreichen/RsyncUI/remove-dead-code' |
| `c91c3cfd` | 2026-07-14 | Thomas Evensen | Merge pull request #151 from timreichen/remove-dead-code |
| `e69842f5` | 2026-07-14 | timreichen | initial commit |
| `1f184294` | 2026-07-14 | timreichen | update |
| `f21fdc01` | 2026-07-14 | timreichen | move changesnapshotnum |
| `1f246395` | 2026-07-14 | Thomas Evensen | Merge pull request #152 from timreichen/cleanup-TaskForm-bindings |
| `60ebc5a1` | 2026-07-14 | Thomas Evensen | issue doc |
| `747e22f8` | 2026-07-14 | timreichen | initial commit |
| `49031146` | 2026-07-14 | timreichen | initial commit |
| `9e4bb4a5` | 2026-07-14 | timreichen | update |
| `6c7051ce` | 2026-07-14 | Thomas Evensen | Merge pull request #156 from timreichen/fix-P1 |
| `5684694c` | 2026-07-14 | timreichen | initial commit |
| `b1d55f84` | 2026-07-14 | timreichen | update |
| `4a53bfcb` | 2026-07-14 | Thomas Evensen | Merge pull request #157 from timreichen/fix-P2 |
| `066b8852` | 2026-07-14 | timreichen | Merge branch 'version-3.0.4-tr' into fix-P2-submit |
| `49ceaea2` | 2026-07-15 | Thomas Evensen | Merge pull request #158 from timreichen/fix-P2-submit |

## Recommended Manual Smoke Checks

1. Open Add Task while an existing task is selected, fill the sheet, and press Return through the final field. Confirm the existing task is not updated or deselected.
2. Confirm exactly one Add action and one Cancel action appear in the sheet toolbar.
3. Add synchronize, snapshot, and `syncremote` tasks using both the toolbar Add button and keyboard submission.
4. Select and update one existing task of each type; verify task-specific folder layout and validation.
5. Delay configuration loading and enter the task screen; confirm a populated profile does not retain an automatically opened Add Task sheet.

## Conclusion

The original P1 issue is fixed, but the branch is not ready to merge. The submit fix currently operates on the wrong model and can invoke update behavior on a selected task. The automatic-sheet P2 and formatting/documentation findings also remain, and the latest merge introduced duplicate Add toolbar code.
