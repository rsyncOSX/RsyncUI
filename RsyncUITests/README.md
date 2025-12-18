# RsyncUI Tests

This directory contains unit tests for the RsyncUI application using Swift Testing framework.

## Setup

To run these tests, you need to configure the Xcode project:

### 1. Add Test Target to Xcode Project

1. Open `RsyncUI.xcodeproj` in Xcode
2. Select the project in the navigator
3. Click the "+" button at the bottom of the targets list
4. Choose "Unit Testing Bundle" (not "XCTest")
5. Name it `RsyncUITests`
6. Set the Target to be tested to `RsyncUI`

### 2. Make RsyncUI Module Testable

Add `@testable` import to the test files:

```swift
@testable import RsyncUI
```

And ensure the main app target allows testing:
- Select the RsyncUI target
- Go to Build Settings
- Search for "Enable Testing Search Paths"
- Set to "Yes"

### 3. Link Required Frameworks

The tests depend on:
- Swift Testing framework (built into Xcode 16+)
- RsyncUI app module
- Any SPM dependencies (RsyncArguments, ProcessCommand, etc.)

### 4. Add Test Files to Target

Make sure the following test files are added to the `RsyncUITests` target:
- `VerifyConfigurationTests.swift`
- `TestSharedReference.swift`

## Test Structure

### VerifyConfigurationTests.swift

Comprehensive tests for configuration validation covering:

#### ✅ Valid Configuration Tests
- Local synchronization (no SSH)
- Remote synchronization with SSH
- Snapshot tasks
- Syncremote tasks

#### ❌ Missing Catalog Tests
- Empty local catalog rejection
- Empty remote catalog rejection
- Both catalogs empty rejection

#### 🔐 SSH Configuration Tests
- Server without username rejection
- Username without server rejection
- Empty server with username
- Empty username with server

#### 📁 Trailing Slash Handling Tests
- Add trailing slash (.add)
- Remove trailing slash (.do_not_add)
- Preserve paths (.do_not_check)
- Handle existing trailing slashes

#### 📸 Snapshot Validation Tests
- Reject without rsync v3
- Default snapshot number to 1
- Preserve custom snapshot numbers
- Network connectivity checks

#### 🔄 Syncremote Validation Tests
- Reject without rsync v3
- Require remote server
- Require username

#### 🏷️ Backup ID Tests
- Handle nil backup ID
- Preserve backup ID
- Special characters in backup ID

#### 🔢 Hidden ID Tests
- Default to -1 for new configs
- Preserve for updates

#### 🎯 Edge Cases
- Very long path names
- Paths with spaces
- Unicode characters in paths
- Various path separators
- Default parameter initialization

## Running Tests

### Command Line
```bash
cd /Volumes/MacMini4/GitHub/RsyncUI
swift test
```

### Xcode
1. Press `⌘U` to run all tests
2. Or click the diamond icon next to individual tests
3. View results in the Test Navigator (⌘6)

### Individual Test Suite
```bash
swift test --filter VerifyConfigurationTests
```

### Individual Test
```bash
swift test --filter VerifyConfigurationTests/validLocalSynchronization
```

## Test Coverage

Current coverage focuses on Priority 1: Configuration Validation

### Covered ✅
- Configuration creation and validation
- SSH parameter validation
- Trailing slash handling
- Snapshot/syncremote task validation
- Empty/missing field rejection
- Edge case handling

### To Be Added 🚧
- Priority 2: Output processing tests
- Priority 3: Data persistence tests (JSON read/write)
- Priority 4: Duplicate detection tests
- Priority 5: Process execution tests
- Priority 6: Schedule logic tests
- Priority 7: Logging tests

## Writing New Tests

### Test Naming Convention
Use descriptive names that explain what is being tested:
```swift
@Test("Descriptive name of what is tested")
func methodNameInCamelCase() async {
    // Test implementation
}
```

### Test Organization
Group related tests with MARK comments:
```swift
// MARK: - Category Name

@Test("Test description")
func testMethod() async {
    // ...
}
```

### Expectations
Use `#expect` for assertions:
```swift
#expect(result != nil)
#expect(result?.value == expected)
#expect(condition, "Custom failure message")
```

### Async Tests
Mark tests as async when needed:
```swift
@Test("Async operation test")
func asyncTest() async {
    let result = await someAsyncOperation()
    #expect(result != nil)
}
```

### Test Isolation
Use `@Suite(.serialized)` for tests that share mutable state:
```swift
@Suite("Test Suite Name", .serialized)
struct MyTests {
    // Tests run one at a time
}
```

## Mocking

### TestSharedReference
A mock implementation of `SharedReference` for testing without full app context:

```swift
// Setup
SharedReference.shared.rsyncversion3 = true

// Test
let result = performOperation()

// Cleanup
SharedReference.shared.reset()
```

## CI/CD Integration

To integrate with CI/CD pipelines:

```yaml
# GitHub Actions example
- name: Run Tests
  run: swift test --parallel
```

## Troubleshooting

### Common Issues

1. **Module not found**: Ensure `@testable import RsyncUI` is present
2. **Tests don't run**: Check test target membership
3. **Network tests fail**: Some tests require localhost connectivity
4. **Flaky tests**: Use `.serialized` suite attribute for shared state

### Debug Tips

- Use `print()` statements (they appear in test output)
- Run individual tests to isolate issues
- Check SharedReference state with breakpoints
- Review test logs in Xcode's Report Navigator

## Contributing

When adding new tests:
1. Follow existing naming conventions
2. Add MARK comments for organization
3. Include descriptive test names
4. Test both success and failure cases
5. Add edge case coverage
6. Update this README if adding new test categories

## Resources

- [Swift Testing Documentation](https://developer.apple.com/documentation/testing)
- [RsyncUI Documentation](https://rsyncui.netlify.app/docs/)
- [Testing Best Practices](https://developer.apple.com/videos/play/wwdc2023/10179/)
