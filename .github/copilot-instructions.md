# AI Coding Agent Instructions for RsyncUI

## Project Overview

**RsyncUI** is a macOS application that provides a user-friendly interface for rsync synchronization tasks. It's built with SwiftUI and follows modern iOS/macOS development patterns.

- **Language:** Swift
- **Framework:** SwiftUI
- **Platform:** macOS
- **Repository:** https://github.com/rsyncOSX/RsyncUI
- **Current Branch:** version-2.8.x

---

## Project Structure

### Core Directories

```
RsyncUI/
├── Main/                          # App entry points and root views
│   ├── RsyncUIApp.swift          # Main app initialization
│   └── RsyncUIView.swift         # Root view controller
├── Model/                         # Business logic and data management
│   ├── Deeplink/                 # URL/deeplink handling
│   ├── Execution/                # Rsync execution logic
│   │   ├── EstimateExecute/      # Estimate and execute phases
│   │   ├── CreateHandlers/       # Process creation
│   │   └── ProgressDetails/      # Progress tracking
│   ├── FilesAndCatalogs/         # File system management
│   ├── Global/                   # Observable state and global data
│   ├── Loggdata/                 # Logging system
│   ├── Storage/                  # Data persistence
│   ├── Utils/                    # Helper utilities
│   └── [Other domains]/          # Additional business logic
├── Views/                         # UI components
│   ├── Add/                       # Add configuration views
│   ├── Configurations/            # Configuration management UI
│   ├── LogView/                   # Logging UI
│   ├── ProgressView/              # Progress indicators
│   ├── Restore/                   # Restore operation UI
│   ├── Settings/                  # App settings UI
│   └── [Other features]/          # Feature-specific views
└── Preview Content/               # SwiftUI previews
```

### Key Model Components

- **Observable Classes**: State management using `@Observable` macro
- **Global Observables**: Centralized state in `Model/Global/`
- **Storage Layer**: JSON-based persistence via Actors
- **Execution Engine**: Process management and monitoring

---

## Development Guidelines

### 1. Architecture Principles

#### MVVM with SwiftUI
- **Model**: Business logic in `Model/` directory
- **View**: SwiftUI views in `Views/` directory
- **ViewModel**: Observable classes managing view state

#### Observable State Management
```swift
@Observable
class MyViewModel {
    var property: String = ""
    
    func updateProperty(_ newValue: String) {
        property = newValue
    }
}
```

#### Separation of Concerns
- Keep execution logic (`Model/Execution/`) separate from UI
- Isolate data storage (`Model/Storage/`) from business logic
- Use dedicated observable classes for each domain

### 2. Code Organization

#### File Naming Conventions
- **Views**: `{FeatureName}View.swift` or `{FeatureName}{Component}.swift`
- **Models**: `{DomainName}.swift`
- **Observable**: `Observable{Domain}.swift`
- **Services**: `{Domain}Service.swift`
- **Actors**: `Actor{Operation}.swift`

#### Directory Structure Rules
- One primary type per file (or related types)
- Group related functionality in subdirectories
- Use clear, descriptive folder names
- Keep Models close to their usage domain

### 3. Error Handling

#### Expected Patterns
```swift
// Use explicit error handling
do {
    let result = try perform()
} catch {
    // Handle error appropriately
    Logger.error("Operation failed: \(error)")
}

// Provide fallback values when appropriate
var value: String {
    get throws { try loadValue() }
    ?? "default"
}
```

#### Error Recovery
- Add default values for missing data
- Log errors with context for debugging
- Don't silently fail - always inform the user when appropriate
- Use conditional logging based on settings

### 4. Logging

#### Logging System Architecture
- **Primary Logger**: `Model/Loggdata/Logging.swift`
- **Observable Settings**: `Model/Global/ObservableLogSettings.swift`
- **Storage**: JSON-based records in file system

#### Logging Best Practices
```swift
// Use contextual logging
Logger.info("Task started: \(taskName)", context: "execution")

// Add debug logging for troubleshooting
Logger.debug("Statistics: \(stats)", level: .verbose)

// Log errors with full context
Logger.error("Failed to parse output", error: error)
```

#### Conditional Logging
- Respect user log settings before logging
- Use different log levels (info, debug, warning, error)
- Include operation context in log messages

### 5. Process Management

#### Rsync Execution Flow
1. **Estimate Phase**: `Model/Execution/EstimateExecute/Estimate.swift`
   - Dry run to get file count and size
   - Parse rsync output using `getstats()`
   - Handle missing statistics gracefully

2. **Execute Phase**: `Model/Execution/EstimateExecute/Execute.swift`
   - Run actual synchronization
   - Monitor progress
   - Capture and parse output

#### Key Classes
- `RemoteDataNumbers`: Statistics parsing with error handling
- `RsyncProcess`: Process lifecycle management
- `ProgressDetails`: Real-time progress tracking

#### Process Termination
- Implement proper cleanup on app exit
- Add process termination handlers
- Ensure resource cleanup in error paths

### 6. UI/View Development

#### SwiftUI Best Practices
```swift
struct MyView: View {
    @State private var state = MyViewModel()
    
    var body: some View {
        VStack {
            // View content
        }
    }
}
```

#### View Extraction
- Extract complex views to separate files
- Keep preview support in extracted views
- Name views descriptively: `{Feature}View.swift`

#### Progress Indicators
- Use `SynchronizeProgressView` for task progress
- Use `RestoreProgressView` for restore operations
- Set max values for accurate progress display

### 7. Data Persistence

#### Storage Strategy
- Use JSON for configuration and logs
- Implement Actors for concurrent access: `ActorRead*.swift`
- Provide proper error handling for I/O operations

#### Configuration Files
- Store in user-accessible locations
- Include validation and schema versioning
- Provide migration paths for format changes

### 8. Testing Considerations

#### Areas to Test
- Error handling with missing data
- Process execution and output parsing
- Progress calculation accuracy
- File I/O operations
- Observable state updates

#### Preview-Driven Development
- Create comprehensive SwiftUI previews
- Use mock data for testing views
- Test dark mode and various sizes

---

## Common Tasks & Patterns

### Adding a New Feature

1. **Create the Model/Logic**
   ```swift
   // Model/YourDomain/YourFeature.swift
   class YourFeatureLogic {
       func performAction() throws {
           // Implementation
       }
   }
   ```

2. **Create Observable**
   ```swift
   // Model/Global/ObservableYourFeature.swift
   @Observable
   class ObservableYourFeature {
       var state: String = ""
   }
   ```

3. **Create Views**
   ```swift
   // Views/YourFeature/YourFeatureView.swift
   struct YourFeatureView: View {
       @State private var viewModel = ObservableYourFeature()
   }
   ```

### Refactoring Existing Code

- Follow the established patterns in the codebase
- Maintain backward compatibility when possible
- Update related tests and previews
- Document breaking changes in commit messages

### Fixing Bugs

1. Locate affected code using grep/search
2. Add error handling if appropriate
3. Update logging for debugging
4. Add fallback mechanisms
5. Test with various data conditions

### Removing Features

- Comment out code temporarily before removal
- Check for dependencies using grep
- Update related documentation
- Remove unused imports and dependencies

---

## Code Quality Standards

### Style Guide

- **Naming**: Use camelCase for variables/functions, PascalCase for types
- **Indentation**: Use 4 spaces (SwiftUI standard)
- **Line Length**: Keep under 120 characters
- **Comments**: Use `//` for single-line, clear and meaningful
- **Access Control**: Use explicit access modifiers (private, internal, public)

### Performance Considerations

- Use Actors for concurrent data access
- Avoid blocking the main thread
- Use `@escaping` closures appropriately
- Monitor memory usage in long-running operations

### Security

- Validate all external input
- Use secure paths for file operations
- Handle sensitive data carefully (ssh keys, passwords)
- Log securely without exposing sensitive information

---

## Dependencies & Tools

### Swift Packages
- Check `Package.resolved` for current versions
- Update packages regularly for security patches
- Document new dependencies in README

### Build System
- Use Makefile for common tasks
- Xcode version: Check `.xcodeproj` requirements
- Deploy target: macOS 13.0+

---

## Workflow

### Before Starting Work

1. Check current branch and pull latest changes
2. Review related code and existing patterns
3. Check for similar implementations
4. Plan the implementation approach

### During Development

1. Follow established patterns
2. Add logging for debugging
3. Handle errors explicitly
4. Create/update previews
5. Test with various data conditions

### Before Committing

1. Review changes for consistency
2. Ensure all errors are handled
3. Update relevant documentation
4. Create meaningful commit messages
5. Run project checks/builds

### Commit Message Format

```
[Type] Brief description

More detailed explanation if needed:
- What changed
- Why it changed
- How it was tested
```

**Types**: feat, fix, refactor, docs, test, chore

---

## Troubleshooting Guide

### Common Issues

#### Observable State Not Updating
- Ensure class is marked `@Observable`
- Use `@State` or `@Bindable` in views
- Check for proper property modification

#### Process Execution Failures
- Check rsync arguments are correctly formatted
- Verify file paths exist and are accessible
- Review error output from `RemoteDataNumbers`
- Add debug logging to trace execution

#### Data Persistence Issues
- Verify file paths and permissions
- Check JSON schema validity
- Ensure Actors are properly initialized
- Add error handling for I/O operations

#### UI Not Responsive
- Check for main thread operations
- Verify Actors aren't blocking UI
- Monitor view update frequency
- Use proper async patterns

---

## Resources & References

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [Swift Concurrency](https://developer.apple.com/documentation/swift/concurrency)
- [Rsync Manual](https://linux.die.net/man/1/rsync)
- Project README.md for overview
- Existing code for patterns and examples

---

## Quick Reference

### Key Files to Know

- `RsyncUI/Model/Execution/EstimateExecute/Estimate.swift` - Estimation logic
- `RsyncUI/Model/Execution/EstimateExecute/Execute.swift` - Execution logic
- `RsyncUI/Model/Loggdata/Logging.swift` - Logging system
- `RsyncUI/Model/Global/ObservableLogSettings.swift` - Log configuration
- `RsyncUI/Views/ProgressView/SynchronizeProgressView.swift` - Progress UI

### Common Commands

```bash
# Build the project
xcodebuild build

# Run tests
xcodebuild test

# Clean build
xcodebuild clean

# Build and run
make run
```

---

**Last Updated:** December 2025  
**Version:** 2.8.x  
**Maintained By:** RsyncUI Development Team
