# Output Streaming Implementation Guide

## Problem Statement
Currently, RsyncUI buffers the **entire** rsync output in memory before processing it. For large sync operations with thousands of files, this can:
- Consume excessive memory
- Delay feedback to the user
- Make the app unresponsive during large transfers

## Solution: Stream Processing

Process rsync output **line-by-line** as it arrives, instead of waiting for the entire output.

---

## Implementation Options

### Option 1: Use Existing `printLine` Closure ✅ RECOMMENDED

Your `RsyncProcess` package already supports streaming via the `printLine` parameter! This is visible in:
- `CreateHandlers.swift` line 33: `printLine: RsyncOutputCapture.shared.makePrintLinesClosure()`

**Advantages:**
- No need to modify RsyncProcess package
- Already working for `RsyncRealtimeView`
- Clean separation of concerns

**How to Implement:**

1. **Use `StreamingOutputHandler.swift`** (already created)
   - Manages a rolling buffer (keeps last N lines)
   - Provides callbacks for line-by-line and batch processing
   - Prevents memory overflow

2. **Use `CreateStreamingHandlers.swift`** (already created)
   - Wrapper around `CreateHandlers`
   - Injects streaming handler into the flow
   - Maintains compatibility with existing code

3. **Update your classes** (example: `EstimateWithStreaming.swift`)
   ```swift
   // Before: Waits for all output
   let handlers = CreateHandlers().createHandlers(...)
   
   // After: Streams output line-by-line
   let streamingHandler = StreamingOutputHandler(
       maxBufferSize: 100,
       onLineReceived: { line in
           // Process each line immediately
           self.handleLine(line)
       }
   )
   
   let handlers = CreateStreamingHandlers().createHandlers(
       fileHandler: fileHandler,
       processTermination: processTermination,
       streamingHandler: streamingHandler
   )
   ```

---

### Option 2: Modify RsyncProcess Package (If Needed)

If `printLine` isn't working or you need more control, implement streaming at the `Process` level using `Pipe.readabilityHandler`.

See `ProcessStreamingExample.swift` for a complete implementation showing:
- How to use `fileHandle.readabilityHandler`
- Line-by-line processing with partial line handling
- Memory-efficient streaming

**Key Code:**
```swift
outputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
    let data = fileHandle.availableData  // Non-blocking read
    // Process data immediately as it arrives
    onLineReceived(line)
}
```

---

## Migration Strategy

### Phase 1: Test with Quick Task ✅ Low Risk
1. Modify `extensionQuickTaskView.swift`
2. Use `CreateStreamingHandlers` instead of `CreateHandlers`
3. Test with small sync operations

### Phase 2: Update Estimate
1. Modify `Estimate.swift` using `EstimateWithStreaming.swift` as reference
2. Keep rolling buffer of last 100 lines
3. Only send summary (last 20 lines) to UI

### Phase 3: Update Execute
1. Modify `Execute.swift`
2. Stream output to progress indicator
3. Use streaming for log file writing

### Phase 4: Update Verify Operations
1. `VerifyTasks.swift`
2. `ExecutePushPullView.swift`
3. `PushPullView.swift`

---

## Benefits

### Memory Usage
**Before:**
- 10,000 file sync = 10,000 lines buffered = ~500 KB per operation
- Multiple simultaneous operations = potential memory issues

**After:**
- Rolling buffer of 100 lines = ~5 KB per operation
- 99% memory reduction

### User Experience
**Before:**
- No feedback until process completes
- UI appears frozen on large transfers

**After:**
- Real-time line-by-line updates
- Responsive UI during transfers
- Better progress indication

### Performance
**Before:**
- Process finishes → Parse 10,000 lines → Create UI data → Display
- User waits for all steps

**After:**
- Line arrives → Display immediately
- Continuous feedback

---

## Files Created

1. **`StreamingOutputHandler.swift`**
   - Core streaming logic
   - Rolling buffer management
   - Callbacks for line/batch processing

2. **`CreateStreamingHandlers.swift`**
   - Drop-in replacement for `CreateHandlers`
   - Integrates streaming handler
   - Maintains API compatibility

3. **`EstimateWithStreaming.swift`**
   - Example implementation for Estimate
   - Shows how to use streaming in practice

4. **`ProcessStreamingExample.swift`**
   - Low-level reference implementation
   - Use if modifying RsyncProcess package

---

## Testing

1. **Small sync** (< 100 files)
   - Verify no regression
   - Check output completeness

2. **Large sync** (> 1,000 files)
   - Monitor memory usage (should stay low)
   - Verify UI responsiveness
   - Check that summary data is correct

3. **Error cases**
   - Rsync errors are caught immediately
   - Partial output handled correctly

4. **Real-time view**
   - `RsyncRealtimeView` continues to work
   - No duplicate output

---

## Configuration

In `StreamingOutputHandler`:
```swift
maxBufferSize: Int = 100  // Adjust based on needs
```

**Recommendations:**
- **Estimate operations**: 100 lines (only need summary)
- **Execute operations**: 200 lines (keep more context)
- **Restore operations**: 500 lines (user wants full list)
- **Quick tasks**: 100 lines (small operations)

---

## Rollback Plan

If streaming causes issues:
1. Keep `CreateHandlers` unchanged
2. Use `CreateStreamingHandlers` only where needed
3. Easy to revert individual classes

---

## Next Steps

1. **Test `printLine` behavior**
   - Verify it's called line-by-line
   - Check timing (immediate vs batched)

2. **Start with Quick Task**
   - Lowest risk area
   - Quick to test and verify

3. **Gradually migrate**
   - One class at a time
   - Monitor memory and performance

4. **Remove buffering in PrepareOutputFromRsync**
   - Currently keeps entire output to extract last 20 lines
   - With streaming, can extract during process
   - Further memory savings

---

## Code Quality Notes

✅ **Follows existing patterns**
- Uses `@MainActor` appropriately
- Proper logging with `Logger.process`
- Error handling via `SharedReference.shared.errorobject`

✅ **Maintains compatibility**
- Doesn't break existing code
- Optional adoption
- Can run both approaches side-by-side

✅ **Memory safe**
- Rolling buffer prevents unbounded growth
- Configurable limits
- Clear ownership and lifecycle

---

## References

- Original recommendation: `AIDocuments/CODE_QUALITY_ANALYSIS_COMPREHENSIVE_DEC16.md` line 705
- Existing streaming UI: `RsyncUI/Views/OutputViews/RsyncRealtimeView.swift`
- Current handler: `RsyncUI/Model/Execution/CreateHandlers/CreateHandlers.swift`
- Output capture: Check RsyncProcess package's `PrintLines.swift`
