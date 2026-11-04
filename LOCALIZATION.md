# Translating RsyncUI

RsyncUI uses English presentation text as localization keys. The main app's
resources are in `RsyncUI/Resources/<language>.lproj/Localizable.strings`.
The widget is a separate bundle, with its own resources under
`WidgetEstimate/Resources`. English (`en`) is the development language and
fallback; Simplified Chinese (`zh-Hans`) uses the contributor's supplied
RsyncUI 3.1.0 translation (393 entries).

To add a language, copy the English resources to a new language's `.lproj`
folder, translate the values, and add the language to the Xcode project's
known regions. Xcode's synchronized source folders include these resources
in the corresponding target automatically. Do not add them again to Copy
Bundle Resources.

Keep keys, escape sequences, rsync flags, and format placeholders intact.
The imported translation uses `%@` for interpolated values; the tables also
include `%lld` variants for Swift integer interpolation. When adding a new
message, use the format matching its Swift interpolation types. Preserve
placeholder order, or use numbered format arguments when reordering.

Pass literals directly to SwiftUI text APIs. Shared UI components should
accept `LocalizedStringKey`; computed strings and `LocalizedError` messages
should use `String(localized:)`. For picker values backed by persisted raw
strings, localize only the display label. Never translate stored identifiers,
profile names, paths, command arguments, JSON keys, or rsync output.

Validate resources with `plutil -lint <file>`. To check behavior, select Chinese,
Simplified in the Xcode scheme's Run > Options > App Language (or use macOS
System Settings > General > Language & Region > Applications), then relaunch.
Check the settings, task pickers, estimates, restore confirmation, and widget;
repeat in English to check fallback behavior. Raw rsync output and phrases
not included in the contributed translation remain in their original language.
