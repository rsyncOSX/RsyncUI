# Verification and Issue Report

Reviewed range: `c59e3e3^..1f246395` (`c59e3e3` through the current `HEAD`, inclusive).

Branch reviewed: `version-3.0.4-tr`

Scope: 33 commits, 22 changed files, 483 insertions, and 469 deletions.

## Summary

The branch builds successfully and all 56 automated tests pass. The review found three behavioral issues in the task add/edit refactor, one formatting/lint issue, and one stale-documentation issue. The highest-risk problem is that update-mode form state is not initialized with the selected configuration's task type, so `syncremote` and snapshot edits can use the wrong layout and the wrong validation path.

Priority definitions used below:

- **P1**: High priority; can result in invalid or incorrectly edited persisted task data.
- **P2**: Medium priority; user-visible workflow regression or unreliable presentation state.
- **P3**: Low priority; maintainability, formatting, or documentation defect.

## Findings

### P1 — Update mode does not load the selected task type

Affected code:

- `RsyncUI/Views/InspectorViews/Add/AddTaskView.swift:40`
- `RsyncUI/Views/InspectorViews/Add/TaskForm.swift:198-205`
- `RsyncUI/Model/Global/ObservableAddConfigurations.swift:123-145`
- `RsyncUI/Model/Global/ObservableAddConfigurations.swift:67-110`
- `RsyncUI/Model/Storage/Basic/UpdateConfigurations.swift:86-97`

`AddTaskView` creates its edit model with the default `selectedrsynccommand == .synchronize`. When a task is selected, `ObservableAddConfigurations.updateview(_:)` copies catalogs, remote fields, ID, and snapshot number, but never copies `config.task` into `selectedrsynccommand`.

The shared `TaskForm` then uses `selectedrsynccommand` to choose the ordinary-sync versus `syncremote` folder layout. `updateConfig` also constructs and validates `NewTask` using this stale value. Finally, `UpdateConfigurations.updateConfiguration` preserves the original persisted task type while applying the newly validated fields.

Consequences:

- An existing `syncremote` task is displayed with ordinary synchronization folder semantics.
- Clearing both remote fields can be validated as an ordinary synchronization and then persisted back into the still-`syncremote` record, bypassing the `syncremote` remote-user/server requirements.
- Snapshot-specific validation can likewise be bypassed because validation sees `.synchronize` even though the stored task remains a snapshot.

The selected task type should be loaded into the edit model before the form renders or validates. Add regression tests covering update behavior for synchronize, snapshot, and `syncremote` configurations.

### P2 — Return/submit handling was lost from the Add Task sheet

Affected code:

- `RsyncUI/Views/InspectorViews/Add/AddTaskSheetView.swift:17-38`
- `RsyncUI/Views/InspectorViews/Add/TaskForm.swift:62-174`
- `RsyncUI/Views/InspectorViews/Add/AddTaskView.swift:61-65`

The pre-refactor Add Task sheet attached `.onSubmit { handleSubmit() }`. The final `AddTaskSheetView` has no submit handler, while add-mode `TaskForm` owns its own `@FocusState`. The `.onSubmit` attached to `AddTaskView` is outside the presented sheet and cannot handle submissions from the sheet's separate view hierarchy.

As a result, the fields still advertise `.continue` and `.return`, but pressing Return in the Add Task sheet neither advances focus nor submits the task. The toolbar Add button still works.

Submit behavior should be owned by `AddTaskSheetView`/`TaskForm`, or the add form should receive an explicit submit action and focus-advance policy.

### P2 — Automatic and user-requested sheet presentation share a latched Boolean

Affected code:

- `RsyncUI/Views/InspectorViews/EditTabView.swift:13`
- `RsyncUI/Views/InspectorViews/EditTabView.swift:28-34`
- `RsyncUI/Views/InspectorViews/EditTabView.swift:42-49`

`showAddPopover` now represents both automatic first-task presentation and the toolbar's user-requested presentation. The `.task(id: rsyncUIdata.configurations)` body sets this value to `true` for `nil` or empty configurations but has no nonempty/loading-complete transition.

If `EditTabView` appears while configurations are temporarily `nil`, the Add Task sheet opens. When asynchronous loading later supplies an existing nonempty configuration list, the sheet remains open because the Boolean is never cleared. This can produce a spurious Add Task sheet on a populated profile. The previous `showNoTasks` implementation included an `else` transition back to the populated state.

Automatic empty-profile presentation should be modeled separately from explicit toolbar presentation, or delayed until configuration loading has definitively completed.

### P3 — Changed Swift files do not pass repository formatting checks

Affected files include:

- `RsyncUI/Views/InspectorViews/Add/AddTaskSheetView.swift`
- `RsyncUI/Views/InspectorViews/Add/AddTaskView.swift`
- `RsyncUI/Views/InspectorViews/Add/TaskForm.swift`
- `RsyncUI/Views/InspectorViews/Add/extensionAddTaskView+BusinessLogic.swift`
- `RsyncUI/Views/InspectorViews/EditTabView.swift`

Evidence:

- `git diff --check c59e3e3^..HEAD` reports trailing whitespace at `AddTaskSheetView.swift:12`.
- SwiftLint reports five warnings in changed files: trailing whitespace, consecutive/closing vertical whitespace, and blank lines at the end of scopes.
- SwiftFormat lint reports that five of the six reviewed task-form files require formatting, including whole-body over-indentation in `AddTaskSheetView` and modifier-chain indentation in `AddTaskView`.

Run SwiftFormat on the changed files and resolve the changed-file SwiftLint warnings before merge.

### P3 — `changestr.md` is stale and contradicts the final branch

Affected code:

- `changestr.md:1-5`
- `changestr.md:22-27`
- `changestr.md:90-95`
- `changestr.md:124-126`

The committed report only reviews through `65cef24` on `version-3.0.3-tr`, while this branch now ends at `1f246395` and version 3.0.4/build 201. It also states that Add Task `handleSubmit()` behavior was retained, which is no longer true after the later `TaskForm`/`AddTaskSheetView` separation.

Update or remove this report so it does not provide misleading verification status for the current branch.

## Verification Performed

### Build

The repository's documented command was attempted:

```bash
make debug
```

It stopped before compilation because the notification command failed:

```text
osascript: syntax error: A identifier can’t go after this identifier. (-2740)
make: *** [archive-debug] Error 1
```

This failure occurs in the pre-build `osascript` wrapper, not in changed Swift code. Compilation was therefore verified directly:

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

The existing suite exercises model, storage, scheduling, argument, URL, log, and validation behavior. It does not exercise the SwiftUI add/edit form interactions identified above.

### Patch and style checks

Commands:

```bash
git diff --check c59e3e3^..HEAD
swiftlint lint --config .swiftlint.yml --quiet
swiftformat --lint <changed-task-form-files> --config .swiftformat
```

Results:

- Diff check: failed on one trailing-whitespace line.
- SwiftLint: five warnings in changed files; the full run also encountered its cache-permission error and existing repository-wide identifier-name violations.
- SwiftFormat: five of six reviewed task-form files require formatting.

## Commit Inventory

All commits reachable in the requested inclusive range were reviewed:

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

## Recommended Manual Smoke Checks

1. Select and update one task of each type: synchronize, snapshot, and `syncremote`.
2. For `syncremote`, confirm folder labels/order and verify that empty remote credentials cannot be persisted.
3. In the Add Task sheet, use Return through every field and confirm the final Return submits only when valid.
4. Enter the task screen while configuration loading is intentionally delayed; confirm a populated profile does not retain an automatically opened Add Task sheet.
5. Verify Add/Cancel/Close toolbar buttons on macOS 14, 15, and 26, including Escape/Return keyboard behavior.

## Conclusion

The branch is not ready to merge without addressing the P1 update-mode task-type defect. The P2 add-sheet submit regression should also be fixed before release. Automated compilation and model tests are green, but they do not cover these SwiftUI workflows.
