# RsyncUI 3.0.4 pre-release findings

Reviewed September 5, 2026. `make debug` completed its archive and export, and
the Xcode test target passed all 60 tests in 11 suites. The items below are
evidence-backed findings from the current working tree, ordered by release
priority.

Follow-up validation: after fixing findings 2 and 3, `xcodebuild test` passed
all 64 tests in 12 suites. The countdown has deterministic regression coverage;
Quick Task startup paths were reviewed and compiled, without running a real
remote synchronization.

## Fix before publishing 3.0.4

### 1. The in-app updater cannot offer 3.0.4 to users running 3.0.3

**Priority: release blocker**

`GetversionofRsyncUI` treats a record whose `version` equals the running app
version as both the "new version available" signal and the download URL
([`GetversionofRsyncUI.swift:32-49`](../RsyncUI/Model/Newversion/GetversionofRsyncUI.swift#L32-L49)).
The published feed has entries only through `3.0.2`, and every entry still
points to the 3.0.3 DMG
([`versionRsyncUI.json:1-34`](../versionRsyncUI/versionRsyncUI.json#L1-L34)).

Consequently, 3.0.3 installations will not show an update at all. Older
installations that do show an update will be sent to `RsyncUI.3.0.3.dmg`, not
3.0.4.

**Required release change:** after the 3.0.4 release asset is available,
add/update feed records for every supported prior version, including `3.0.3`,
to point to
`https://github.com/rsyncOSX/RsyncUI/releases/download/v3.0.4/RsyncUI.3.0.4.dmg`.
Do not add a `3.0.4` record; that is how the current implementation avoids
offering the installed version as an update.

### 2. Quick Task can leave a permanent progress UI without starting rsync

**Status: fixed**

Quick Task now checks rsync availability, halted tasks, and generated arguments
before creating handlers or showing progress. Missing rsync reports the existing
`Validatedrsync.norsync` error. A launch failure clears progress and releases both
the process and handlers; successful execution retains them until the main-actor
termination callback performs cleanup. Repeated starts are ignored while a task
is in progress.

Implementation: [`extensionQuickTaskView.swift`](../RsyncUI/Views/Quicktask/extensionQuickTaskView.swift).

### 3. The deep-link synchronization countdown expires earlier than advertised

**Status: fixed**

The countdown now uses a fixed deadline set when the view appears. The displayed
seconds round up, remain nonnegative, and expiration occurs only at or after the
full six-second interval. `synchronizewithouttimedelay` explicitly means immediate
execution on appearance. Expiration is consumed once; cancellation and view
removal prevent later timer events from starting synchronization.

Implementation: [`TimerView.swift`](../RsyncUI/Views/Detailsview/TimerView.swift).
Regression tests cover repeated ticks, the six-second boundary, late ticks,
immediate execution, cancellation, and duplicate expiration in
[`SynchronizationCountdownTests.swift`](../RsyncUITests/SynchronizationCountdownTests.swift).

## User-interface updates worth including

### 4. Failed profile creation dismisses its error message

**Priority: medium**

The Add button always sets `showSheet = false` immediately after `addProfile()`
([`ProfileView.swift:153-157`](../RsyncUI/Views/Profiles/ProfileView.swift#L153-L157)).
However, `addProfile()` deliberately sets an inline error for an empty name
([`ProfileView.swift:171-175`](../RsyncUI/Views/Profiles/ProfileView.swift#L171-L175))
or a duplicate/failed name
([`ProfileView.swift:185-188`](../RsyncUI/Views/Profiles/ProfileView.swift#L185-L188)).
The sheet is dismissed before that error can be read.

**Recommended fix:** make `addProfile()` report success and dismiss only on
success. Keep focus in the name field and disable Add for whitespace-only
input; retain the inline message for duplicate or filesystem failures.

### 5. The cancellation control in the deep-link countdown is not accessible

**Status: fixed alongside finding 3**

The countdown now uses a semantic Button with a "Cancel synchronization"
accessibility label, remaining-time accessibility value, and help text.
Cancellation disables the countdown before dismissing the view.

## Release hygiene

### 6. The README still declares 3.0.3 to be the latest release

**Priority: medium**

The primary README displays a 3.0.4 download badge, but its "Latest release"
section still says `v3.0.3 — August 7, 2026 — in active development`
([`README.md:3-4`](../README.md#L3-L4) and
[`README.md:23-25`](../README.md#L23-L25)).

**Required release change:** update the latest-release line, release date, and
release-note link/content when the 3.0.4 asset is published. Remove the
obsolete 3.0.3 badge unless two version-specific download counters are
intentional.

### 7. The release build has avoidable compiler warnings

**Priority: low**

The debug archive and test build both warn that `TimerView.swift` uses
`Timer.publish(...).autoconnect()` without importing Combine
([`TimerView.swift:19`](../RsyncUI/Views/Detailsview/TimerView.swift#L19)).
They also warn that `nonisolated(unsafe)` is unnecessary on the locked static
`DateFormatter` ([`extensions.swift:10-19`](../RsyncUI/Model/Utils/extensions.swift#L10-L19)).

Neither warning blocked the archive or tests, but a release build should be
warning-free so future SDK or strict-concurrency changes are not masked.

**Partially resolved:** `TimerView.swift` now imports Combine. Remove
`nonisolated(unsafe)` after confirming the existing lock-based access remains
the intended concurrency design.
