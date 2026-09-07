# Release review: 3.0.4 (207)

Reviewed September 7, 2026, at commit `a8ded14b`. Application source was left unchanged.

Follow-up: the shared storage writer issue below is fixed. Prepare the updater feed change for publication alongside the release asset; the runtime and distribution verification limits below still apply.

## P1: overlapping saves can overwrite newer data or corrupt JSON

**Status: fixed September 7, 2026.** Encoding and atomic file replacement now run without suspension on the storage actor, serializing saves through completion. The original stress reproduction now reports **0 stale or invalid files in 20 rounds**. The full suite passes **80 tests in 17 suites**, including new coverage for concurrent saves, complete JSON reads during saves, the last accepted value winning, and preservation/recovery after an encoding failure. The description below records the original defect.

The fixed source also passed a Release archive for Intel and Apple Silicon. Follow-up evidence: `/tmp/RsyncUI-207-storage-fixed.log`, `/tmp/RsyncUI-207-storage-fixed.xcresult`, and `/tmp/RsyncUI-207-storage-fixed-release.log`.

`RsyncUI/Model/Storage/SharedJSONStorageWriter.swift:18-20` awaits a detached task that writes directly to the destination file. That suspension allows another call into the actor to start another write to the same file. The actor therefore does not serialize file writes, and the writes are not atomic.

This writer persists configurations, schedules, user settings, logs, widget data, and exports. Independent UI tasks can submit saves; for example, task-type changes launch an unstructured save in `Views/Configurations/ConfigurationsTableDataMainView.swift:219-221`. An earlier save can finish after a later one. Concurrent direct writes can also leave invalid JSON. Configuration loading returns nil on decode failure, so corrupt configuration JSON cannot be loaded normally.

Reproduction used the current writer source, removing only its logging call and module imports, plus the exact resolved `EncodeGeneric` source. A Swift 6 command-line harness submitted 20 overlapping saves per round to a temporary file, alternating arrays of 500,000 integers and 10 integers. Instrumentation recorded the order in which the actor accepted saves. After all writes completed, the harness compared the decoded file with the last accepted value.

Result: **14 of 20 rounds produced stale or undecodable JSON**. Seven rounds saved the earlier value and seven produced undecodable JSON. A smaller-payload initial stress run did not reproduce corruption; this is a concurrency stress reproduction, not a measured frequency in normal UI use.

Reproduction source and executable: `/tmp/RsyncUI-207-storage-check/`. No user configuration files were used.

Required fix: serialize saves to each destination through completion and use atomic replacement. Atomic writes alone do not prevent an older save from replacing a newer one. Add regression coverage for overlapping saves and verify that the most recently accepted save wins and remains decodable.

## Release publication prerequisite: updater feed still targets 3.0.3

Both the checked-in `versionRsyncUI/versionRsyncUI.json` and the public feed read on September 7 contain records only through 3.0.2, all pointing to the 3.0.3 DMG. `GetversionofRsyncUI.swift:32-34` looks for a record matching the installed version, so 3.0.3 users receive no update offer.

Once the 3.0.4 asset exists, add the 3.0.3 entry and update supported older-version entries to the 3.0.4 asset. Do not add a 3.0.4 entry under the current matching scheme. This is a publication prerequisite, not evidence that the new application cannot run.

The README's latest-release line also still describes 3.0.3; update it when publishing.

## Verification completed

- Xcode macOS test action: **78 tests in 17 suites passed**.
- Release archive: **succeeded**, with `x86_64` and `arm64` slices.
- Archive signature: deep and strict verification passed, including the widget extension.
- Developer ID export using the repository's `exportOptions.plist`: **succeeded**.
- Archive metadata confirms version 3.0.4, build 207, minimum macOS 14.0.
- Release log contains no source compiler errors; the only warning is App Intents metadata extraction skipped for a target with no AppIntents framework dependency.
- Inspected process completion and ownership, batch cancellation, restore destination and snapshot selection, snapshot deletion arguments, scheduling, persistence, and updater behavior.

Evidence: `/tmp/RsyncUI-207-tests.log`, `/tmp/RsyncUI-207-tests.xcresult`, `/tmp/RsyncUI-207-release.log`, `/tmp/RsyncUI-207-release.xcarchive`, `/tmp/RsyncUI-207-export.log`, `/tmp/RsyncUI-207-export/`, and `/tmp/RsyncUI-207-live-feed.json`.

## Verification limits

Builds and tests ran on macOS 27 beta with Xcode 27 beta. Intel was compiled but not executed; macOS 14 runtime compatibility was not exercised. No real SSH backup/restore, remote snapshot deletion, long-running schedule/wake cycle, or interactive UI smoke test was performed. The exported app was not submitted for notarization, and a final DMG/Gatekeeper installation check remains outstanding. Passing these checks does not establish absence of every possible release defect.
