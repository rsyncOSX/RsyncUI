# RsyncUI Code Review Issues

Generated: 2026-03-18

---

## Bugs / Correctness Issues

### 1. Race condition in `SharedReference.checkeandterminateprocess()`
**File:** `RsyncUI/Model/Global/SharedReference.swift:103–118`

```swift
func checkeandterminateprocess() {
    guard let process, process.isRunning else { return }
    process.terminate()
    Task {
        try? await Task.sleep(for: .milliseconds(500))
        if process.isRunning {   // ← `self.process` is already nil here
            kill(process.processIdentifier, SIGKILL)
        }
    }
    self.process = nil   // ← set to nil BEFORE Task body runs
}
```

`self.process = nil` runs synchronously before the `Task` body executes. More critically, `Process` is not `Sendable` — passing the captured reference into the `Task` closure crosses an isolation boundary without a `Sendable` guarantee, which Swift 6 strict concurrency will flag as a data race.

**Fix:** Mark the Task `@MainActor` so no isolation crossing occurs:
```swift
Task { @MainActor in
    try? await Task.sleep(for: .milliseconds(500))
    if process.isRunning { kill(process.processIdentifier, SIGKILL) }
}
```

---

### 2. `GlobalTimer.shared` singleton initialised without `@MainActor`
**File:** `RsyncUI/Model/Global/GlobalTimer.swift:54`

```swift
@Observable @MainActor
final class GlobalTimer {
    static let shared = GlobalTimer()   // ← missing @MainActor
```

`GlobalTimer` is `@MainActor`-isolated, but `static let shared` has no isolation attribute. The initializer calls `setupWakeNotification()` which registers an `NSWorkspace` observer — this can happen at first access from off the main actor, violating the isolation contract.

**Fix:**
```swift
@MainActor static let shared = GlobalTimer()
```

---

### 3. `GlobalTimer` stored as `let` in a view — observation won't track changes
**File:** `RsyncUI/Views/Sidebar/SidebarMainView.swift:56`

```swift
let globaltimer = GlobalTimer.shared
```

`GlobalTimer` is `@Observable`. Storing it as a plain `let` in a `struct` view means SwiftUI cannot install an observation tracker on it. Changes to `globaltimer.firstscheduledate` and `globaltimer.scheduledprofile` that drive `onChange` callbacks won't reliably trigger view updates.

**Fix:**
```swift
@State private var globaltimer = GlobalTimer.shared
```

---

### 4. Strong `self` capture + actor isolation violation in streaming closures
**Files:** `RsyncUI/Model/Execution/EstimateExecute/Estimate.swift:40–43`, `RsyncUI/Model/Execution/EstimateExecute/Execute.swift:58–68`

```swift
streamingHandlers = CreateStreamingHandlers().createHandlers(
    fileHandler: { _ in },
    processTermination: { output, hiddenID in
        self.processTermination(...)   // ← strong capture, no weak reference
    }
)
```

Both `Estimate` and `Execute` are `@MainActor final class`. If the streaming library delivers completions from a background thread, calling `self.processTermination(...)` directly is an actor isolation violation — a `@MainActor`-isolated method being called from a non-`@MainActor` context. The strong capture also creates a retain cycle between the handler and the owning object.

**Fix:** Use `weak self` and hop to `@MainActor`:
```swift
processTermination: { [weak self] output, hiddenID in
    Task { @MainActor [weak self] in
        self?.processTermination(stringoutputfromrsync: output, hiddenID)
    }
}
```

---

### 5. `AlertError` recreated on every view body evaluation
**File:** `RsyncUI/Main/RsyncUIView.swift:75–78`

```swift
var errorhandling: AlertError {
    SharedReference.shared.errorobject = AlertError()
    return SharedReference.shared.errorobject ?? AlertError()
}
```

This computed property is called as a parameter to `SidebarMainView(...)`. Every time SwiftUI re-evaluates the view body a brand-new `AlertError()` is assigned to `SharedReference.shared.errorobject`, wiping any pending error. Any error set between body evaluations is silently lost.

**Fix:** Create `AlertError` once — either as a `@State` property in `RsyncUIView` or as a property on `RsyncUIconfigurations` — and pass the same instance down the hierarchy.

---

### 6. Operator precedence bug in `onlySelectedTaskIsEstimated`
**File:** `RsyncUI/Model/Execution/ProgressDetails/ProgressDetails.swift:68–71`

```swift
func onlySelectedTaskIsEstimated(_ uuids: Set<UUID>) -> Bool {
    let answer = estimatedlist?.filter { uuids.contains($0.id) }
    return (answer?.count ?? 0 == 1) && (estimatedlist?.count ?? 0 == 1)
}
```

`answer?.count ?? 0 == 1` parses as `answer?.count ?? (0 == 1)` which is `answer?.count ?? false` — not the intended comparison. This makes the function always return `false` when `answer` is `nil`.

**Fix:** Add parentheses around the comparisons:
```swift
return ((answer?.count ?? 0) == 1) && ((estimatedlist?.count ?? 0) == 1)
```

---

## Deprecated API Usage

### 7. `.alert(isPresented:)` with `Alert(...)` — deprecated
**Files:**
- `RsyncUI/Views/Sidebar/SidebarMainView.swift:101–107`
- `RsyncUI/Views/Tasks/TasksView.swift:105–113`
- `RsyncUI/Views/InspectorViews/Add/GlobalChangeTaskView.swift:40–57`

All three use the old `Alert(title:primaryButton:secondaryButton:)` initialiser. Replace with the modern `.alert(_:isPresented:actions:message:)` form:

```swift
// TasksView example
.alert("Synchronize all tasks with NO estimating first?", isPresented: $showingAlert) {
    Button("Synchronize") { executetaskpath.append(Tasks(task: .executenoestimatetasksview)) }
    Button("Cancel", role: .cancel) {}
}

// SidebarMainView error alert — use localizedError description directly
.alert(errorhandling.activeError?.localizedDescription ?? "", isPresented: errorhandling.isPresentingAlert) {
    Button("OK", role: .cancel) {}
}
```

---

### 8. `.cornerRadius(_:)` — deprecated since iOS 15 / macOS 12
**File:** `RsyncUI/Views/InspectorViews/RsyncParameters/RsyncParametersView.swift:87, 94`

```swift
.cornerRadius(8)
.cornerRadius(10)
```

**Fix:**
```swift
.clipShape(.rect(cornerRadius: 8))
.clipShape(.rect(cornerRadius: 10))
```

---

### 9. `.accentColor(.blue)` — deprecated since iOS 15 / macOS 12
**File:** `RsyncUI/Views/Restore/RestoreTableView.swift:155`

```swift
.accentColor(.blue)
```

**Fix:**
```swift
.tint(.blue)
```

---

## SwiftUI Correctness Issues

### 10. `@State` properties not `private`
**Files:** `RsyncUI/Views/Sidebar/SidebarMainView.swift:34, 38, 44, 47–55`, `RsyncUI/Views/Tasks/TasksView.swift:49–69`

Several `@State` vars are declared without `private`, for example:

```swift
@State var selectedview: Sidebaritems = .synchronize
@State var executetaskpath: [Tasks] = []
@State var queryitem: URLQueryItem?
@State var mountingvolumenow: Bool = false
```

Per SwiftUI's rules: `@State` properties must be `private`. A non-private `@State` allows a caller to pass an initial value, but the `@State` wrapper ignores any external updates after the first render — creating subtle, hard-to-debug incorrect behaviour.

**Fix:** Add `private` to all `@State` declarations that are not intentionally public interface of the view.

---

## Minor Issues

### 11. Redundant `count > 0` guard in `checkSchedules()`
**File:** `RsyncUI/Model/Global/GlobalTimer.swift:186–195`

```swift
private func checkSchedules() {
    if let item = allSchedules.first {
        if allSchedules.count > 0 {   // ← always true if `first` succeeded
            allSchedules.removeFirst()
        }
        executeSchedule(item)
    }
}
```

The inner `if allSchedules.count > 0` is always `true` when `allSchedules.first` returns a value. Remove the redundant check.

---

### 12. `withAnimation` without value in hover handlers
**Files:** `RsyncUI/Views/Sidebar/SidebarMainView.swift:267`, `RsyncUI/Views/Settings/SidebarSettingsView.swift:94`

```swift
withAnimation(.easeInOut(duration: 0.15)) {
    isHovered = hovering
}
```

`withAnimation(_:_:)` animates all state changes in the closure. This is lower priority but can cause unexpected animations in list-heavy views. Consider using `.animation(_:value:)` on the view modifier instead for more predictable, scoped animation.

---

## Summary

| # | File | Issue | Severity |
|---|------|-------|----------|
| 1 | `SharedReference.swift:103` | Non-`Sendable` `Process` captured across Task boundary | **Bug** |
| 2 | `GlobalTimer.swift:54` | `static let shared` missing `@MainActor` | **Bug** |
| 3 | `SidebarMainView.swift:56` | `GlobalTimer` stored as `let` — observation won't track | **Bug** |
| 4 | `Estimate.swift:40`, `Execute.swift:58` | Strong `self` capture + potential actor isolation violation | **Bug** |
| 5 | `RsyncUIView.swift:75` | `AlertError` recreated on every body evaluation | **Bug** |
| 6 | `ProgressDetails.swift:70` | `??` operator precedence bug yields wrong boolean result | **Bug** |
| 7 | 3 view files | `.alert(isPresented:)` + `Alert(...)` deprecated | **Deprecated API** |
| 8 | `RsyncParametersView.swift:87,94` | `.cornerRadius()` deprecated | **Deprecated API** |
| 9 | `RestoreTableView.swift:155` | `.accentColor()` deprecated | **Deprecated API** |
| 10 | `SidebarMainView.swift`, `TasksView.swift` | `@State` properties not `private` | **SwiftUI correctness** |
| 11 | `GlobalTimer.swift:188` | Redundant `count > 0` guard inside `if let first` | **Minor** |
| 12 | `SidebarMainView.swift:267` | `withAnimation` without scoped value | **Minor** |
