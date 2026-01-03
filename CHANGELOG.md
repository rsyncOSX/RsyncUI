# RsyncUI Changelog

All notable changes to RsyncUI will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.8.5] - 2026-01-03

### Added
- **Log to file feature**: New option to save synchronization output to log files for better debugging and audit trails
- **Empty state overlays**: Added informative empty state views for task lists to improve user experience
- **Help tooltips**: Added comprehensive help tooltips throughout the UI for better user guidance
- **Two-tables Inspector option**: New setting to use alternative two-tables inspector view layout
- **Show rsync command toggle**: Added option to display the resulting rsync command in inspector views for transparency
- **Configuration table view**: Added configuration table to ProfileView for better visualization
- **Validation feedback**: Added error borders to required fields in AddTaskView for better form validation
- **Tab-based Inspector navigation**: Refactored inspector views to use TabView for improved navigation

### Changed
- **Sentinel defaults removed (MAJOR)**: Completely eliminated all `?? -1` sentinel patterns throughout the codebase
  - SSH ports and paths now use proper optional handling with validation
  - Tri-state boolean configuration converted to proper optional/enum handling
  - All configuration decode/encode paths refactored for type safety
- **SSH parameter validation**: Enhanced SSH port and path validation with proper error surfacing via AlertError
- **Inspector UI improvements**: Significantly improved inspector view layouts, spacing, and organization
- **Task list layout**: Switched DefaultView layout from VStack to HStack for better space utilization
- **Parameter field widths**: Increased maxWidth and parameter field widths for better readability
- **Help text updates**: Improved and clarified help instructions for parameter usage, especially --delete flag
- **Button text updates**: Updated various button labels for better clarity
- **Toolbar refinements**: Improved toolbar logic and layout across multiple views
- **Tab change behavior**: Clear selected UUIDs on tab change for consistent state management
- **Code organization**: Moved documentation files to project root for better accessibility
- **Actor logging**: Refactored ActorLogToFile usage to method calls for cleaner architecture

### Fixed
- **Parameter handling**: Fixed nil and default value handling for SSH parameters throughout the application
- **Add+ button logic**: Fixed enable/disable logic in AddTaskView to properly validate required fields
- **hiddenID handling**: Improved hiddenID handling in OneTaskDetailsView and task execution flows
- **Shared SSH settings**: Fixed parameter handling for shared SSH settings between configurations
- **Optional value initialization**: Improved handling of optional values in model initializers
- **Inspector selection**: Fixed inspector to hide when multiple items are selected
- **Configuration persistence**: Improved configuration validation and persistence logic

### Removed
- **Unused code cleanup**: Removed LogfileToReset enum and other unused error handling code
- **Commented-out parameters**: Removed commented-out parameters from DecodeSynchronizeConfiguration
- **Legacy views**: Removed unused view properties and initializers for cleaner codebase
- **Obsolete buttons**: Removed unused buttons and simplified UI layouts

### Documentation
- Updated CODE_QUALITY_ANALYSIS_COMPREHENSIVE.md to reflect all architectural improvements
- Updated TODO.md to mark sentinel default removal as completed (Jan 3, 2026)
- Enhanced documentation for SSH port/path validation and configuration handling
- Overall code quality score improved to 9.5/10

---

## [2.8.4] - 2025-12-26

### Added
- **RsyncProcessStreaming integration (MAJOR)**: Complete migration to unified process execution model using event-driven handlers
  - Real-time streaming output across Estimate/Execute operations
  - Strong reference management during execution with deterministic cleanup post-termination
  - Prevents memory leaks through proper handler lifecycle management
- **Comprehensive test suite**: Added RsyncUITests target with extensive test coverage
  - UI tests for arguments validation
  - Deeplink URL creation and parsing tests
  - Configuration validation tests
- **Argument validation**: New toggle for validating rsync arguments before execution
  - Optional validation to catch errors early
  - Configurable via user settings
- **Enhanced progress view**: Improved progress view with better styling and layout
- **Profile management**: Enhanced profile creation with dedicated sheet UI
- **Quick add task**: New popover for quickly adding tasks from toolbar

### Changed
- **Streaming handler cleanup**: Refactored all execution paths to release streaming references properly
  - Estimate class now properly manages handler lifecycle
  - Execute class implements deterministic cleanup
  - OneTaskDetailsView uses handler factories with explicit cleanup hooks
- **Application shutdown**: Added structured cleanup on app termination
  - Timer invalidation on window close
  - Process termination guards to prevent orphaned subprocesses
  - Proper resource cleanup for cleaner app lifecycle
- **SwiftLint configuration**: Expanded rules to cover trailing whitespace, unused imports, and sorted imports
  - Added reasonable caps for line/function/type length
  - Enforces explicit initialization patterns
- **Enum naming conventions**: Refactored multiple enums to use camelCase for consistency
  - RsyncCommand enum cases updated
  - PushPullCommand enum converted to camelCase
  - OtherRsyncCommand enum refactored
  - PlanSnapshots enum cases normalized
  - Day of week enums use lowercase cases
- **Configuration model improvements**: Made parameter fields optional where appropriate
  - parameter4 now optional to better handle delete flag
  - Uses DefaultRsyncParameters enum for rsync flags
  - Removed unused parameter1-3 fields
- **Variable naming consistency**: Refactored variable names throughout codebase
  - FileManager variables use consistent naming
  - RemoteDataNumbers uses clearer integer property names
  - Loop variables renamed for better clarity
- **Swift package dependencies**: Updated to use main branch for stability
- **View organization**: Reorganized view files into logical directories
  - Moved DefaultView files to InspectorViews
  - Moved Add and RsyncParameters views to DefaultView
  - Moved HelpView with updated constraints

### Fixed
- **Delete parameter handling**: Fixed handling of --delete parameter across the application
- **SSH key validation**: Improved SSH key path validation logic
- **Stats error handling**: Refined stats error detection and alert threshold logic
- **Dry-run validation**: Added dry-run checks to argument validation
- **Guard statement order**: Fixed guard statement order in snapshot and restore flows
- **Threading safety**: Added debug threading checks for streaming handlers

### Removed
- **Legacy RsyncProcess**: Removed RsyncProcess dependency in favor of RsyncProcessStreaming
- **Unused output views**: Removed RsyncRealtimeView and related UI references
- **Obsolete logging**: Removed rsync output logfile support from legacy log views
- **Debug print statements**: Silenced debug print statements in streaming handlers (gated behind DEBUG flag)
- **@ObservationIgnored annotation**: Removed from process property where no longer needed

### Documentation
- Added comprehensive CODE_QUALITY_ANALYSIS_COMPREHENSIVE.md document
- Updated TODO.md to reflect streaming migration completion (Dec 18, 2025)
- Updated README for v2.8.2 and v2.8.4 releases
- Documented ParseRsyncOutput package integration
- Added detailed architecture and lifecycle documentation

### Performance
- Process lifecycle now deterministic with proper cleanup
- Background work isolated via Task.detached with main actor marshalling
- Reduced retain-cycle risk through proper reference management
- Streaming output provides real-time feedback without performance degradation

---

## [2.8.2] - 2025-12-14

### Changed
- Refined parameter handling for rsync configurations
- Updated Swift package dependencies
- Various UI refinements and bug fixes

### Documentation
- Updated version references in documentation
- Improved README with latest release information

---

## Earlier Versions

For changelog information about versions 2.8.0 through 2.8.1, please refer to the [release notes on GitHub](https://github.com/rsyncOSX/RsyncUI/releases).

---

## Release Notes

### Version Highlights

**v2.8.5** focuses on eliminating technical debt (sentinel defaults), enhancing validation and error handling, and improving the user experience with better logging and UI refinements.

**v2.8.4** introduced a major architectural improvement with RsyncProcessStreaming integration, providing real-time output streaming, better process lifecycle management, and comprehensive test coverage.

**v2.8.2** continued refinements to parameter handling and configuration management.

### Upgrade Notes

#### Upgrading to 2.8.5
- The elimination of sentinel defaults (`?? -1`) means SSH port configuration is now properly validated
- Existing configurations will be automatically migrated to use proper optional handling
- No user action required, but review SSH settings if you use custom ports

#### Upgrading to 2.8.4
- The new streaming architecture provides better real-time feedback during operations
- Existing configurations are fully compatible
- Test suite additions do not affect end-user functionality

### Known Issues & Limitations

- No CI/CD pipeline yet implemented (GitHub Actions workflow planned)
- Test coverage for streaming execution paths is incomplete (in progress)
- Telemetry counters for error detection not yet implemented (planned)

### Future Plans

See [TODO.md](TODO.md) for detailed roadmap including:
- CI/CD automation with SwiftLint and build workflows
- Expanded test coverage for streaming execution
- Error telemetry hooks for better observability
- Potential extraction of configuration models to reusable package

---

## Contributing

For bug reports and feature requests, please visit the [GitHub Issues](https://github.com/rsyncOSX/RsyncUI/issues) page.

## Links

- [Documentation](https://rsyncui.netlify.app/docs/)
- [GitHub Repository](https://github.com/rsyncOSX/RsyncUI)
- [Releases](https://github.com/rsyncOSX/RsyncUI/releases)
- [License](Licence.MD)
