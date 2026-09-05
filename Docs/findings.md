# RsyncUI 3.0.4 pre-release findings

Reviewed September 5, 2026. `make debug` completed its archive and export, and
the Xcode test target passed all 60 tests in 11 suites. The items below are
evidence-backed findings from the current working tree, ordered by release
priority.

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

**Priority: high**

Quick Task sets `showprogressview = true` before checking whether rsync is
available and before confirming that it has arguments and streaming handlers
([`extensionQuickTaskView.swift:82-103`](../RsyncUI/Views/Quicktask/extensionQuickTaskView.swift#L82-L103)).
Any subsequent `guard` return bypasses `processTermination`, the sole location
that resets this value ([`extensionQuickTaskView.swift:126-131`](../RsyncUI/Views/Quicktask/extensionQuickTaskView.swift#L126-L131)).

Users without a usable rsync binary can therefore be left on a progress state
for a task that was never started.

**Required fix:** validate all prerequisites before setting the progress state,
or reset `showprogressview` and release the handler references on every
non-start path. Surface the existing "no rsync" error consistently with the
other execution flows.

### 3. The deep-link synchronization countdown expires earlier than advertised

**Priority: high**

The normal countdown subtracts the entire elapsed duration from the already
decremented value on every timer event
([`TimerView.swift:43-49`](../RsyncUI/Views/Detailsview/TimerView.swift#L43-L49)).
For a nominal six-second delay, the sequence is approximately `6, 5, 3, 0,
-4`, so synchronization begins on the fourth tick rather than after six
seconds. In the `synchronizewithouttimedelay` branch, resetting the value to
one on each tick still delays execution until the second tick
([`TimerView.swift:27-33`](../RsyncUI/Views/Detailsview/TimerView.swift#L27-L33)).

This timer starts a real synchronization after a deep link, so the timing
error reduces the user's opportunity to cancel an unexpected operation.

**Required fix:** derive the remaining interval from a fixed deadline (for
example, `max(0, deadline.timeIntervalSinceNow)`) rather than repeatedly
subtracting elapsed time, and explicitly define the no-delay path as immediate
execution or a deliberately documented short confirmation interval.

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

**Priority: medium**

`TimerView` makes an `Image` or `Text` cancel the countdown with
`.onTapGesture` ([`TimerView.swift:23-37`](../RsyncUI/Views/Detailsview/TimerView.swift#L23-L37)
and [`TimerView.swift:39-53`](../RsyncUI/Views/Detailsview/TimerView.swift#L39-L53)).
This does not provide a semantic Button, visible action name, keyboard
activation, or VoiceOver hint. It also conflicts with the user's expectation
that the displayed countdown describes what will happen.

**Recommended fix:** replace the gesture with a labelled `Button`, such as
"Cancel synchronization", and expose the remaining time as its accessibility
value. This also resolves the SwiftUI interaction-pattern issue without an
AppKit bridge.

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

**Recommended fix:** import Combine in `TimerView.swift`, and remove
`nonisolated(unsafe)` after confirming the existing lock-based access remains
the intended concurrency design.
