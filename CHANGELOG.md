# Changelog - RsyncUI v2.8.5 to v2.8.6

All notable changes to this project will be documented in this file.

## [2.8.6] - 2026-01-08

### Major Changes

#### Code Refactoring & Architecture Improvements
- **Removed Verify Remote Feature**: Eliminated the entire Verify Remote functionality from the application, including:
  - All associated views and UI components
  - State management related to verification
  - Configuration properties and toggles
  - SSH key and port logic from parameters
  - This simplification removes redundant functionality previously available in Push/Pull operations

- **Unified Rsync Command Views**: Consolidated duplicate rsync command views:
  - Removed `RsyncCommandView` and `OtherRsyncCommandsView` from InspectorViews/RsyncParameters
  - Created a new unified `RsyncCommandView` under VerifyTasks
  - Updated AddTaskView and AddTaskViewtwotables to use the consolidated view
  - Reduced code duplication and improved maintainability

- **Push/Pull Command Refactoring**:
  - Removed the unused 'none' case from `PushPullCommand` enum
  - Updated default selection to 'pushLocal'
  - Refactored `ExecutePushPullView` to use an inspector panel for command controls
  - Streamlined progress display logic
  - Changed progress indicators from VStack to HStack with rounded rectangle overlays for improved UI

#### Code Quality Improvements
- **Collection Checks**: Replaced count-based checks with more idiomatic Swift constructs:
  - Converted multiple `guard` statements checking `stackoftasks.count` to use `isEmpty`
  - Replaced filter followed by `isEmpty` checks with `contains` for more concise evaluation
  - Applied similar improvements across model and view files for configuration and remote task checks

- **Optional Handling**: Refactored `getIndex` to return optional `Int` instead of -1 for not found cases
  - Updated all usages to employ optional binding
  - Improved code clarity and safety

- **Hardcoded Constants**: Replaced hardcoded values with named constants:
  - Introduced `reduceestimatedcount` constants to replace hardcoded row reduction values in rsync output
  - Set to 15 for rsync version 3 and 13 for openrsync
  - Updated both `ProgressDetails` and `PushPullView` for consistency

### UI/UX Enhancements

- **Inspector Panel for VerifyTasks**: Added a new Inspector view in the VerifyTasks screen:
  - Allows users to view Rsync command and arguments for selected configurations
  - Inspector displays only when a configuration is selected
  - Improves task inspection and clarity

- **Navigation Improvements**: Updated `VerifyRemoteView` to use `NavigationSplitView`:
  - Replaced previous NavigationStack-based layout
  - Added profile picker with validprofilesverifytasks
  - Improved state management for selected profiles and configurations

- **Progress Bar Handling**: Enhanced progress visualization:
  - Ensured progress values are clamped between 0 and maximum for both push and pull operations
  - Added padding to progress bars and related UI elements for better visual spacing

- **Layout Consistency**: Improved SwiftUI layout consistency:
  - Moved `.padding()` and `.overlay()` modifiers outside conditional blocks
  - Applied fixes in `OneTaskDetailsView`, `ExecuteEstTasksView`, and `PushPullView`

- **Transfer Size Display**: Added formatted transfer size display in DetailsView:
  - New `totaltransferredfilessize` property in `RemoteDataNumbers`
  - Displays human-readable transfer sizes instead of raw byte values

### Bug Fixes & Cleanup

- **Removed Obsolete Classes**:
  - Deleted `ObservableVerifyRemotePushPull`
  - Deleted `PushPullCommandtoDisplay`
  - Deleted `ArgumentsPullRemote` class

- **Removed Unused Code**:
  - Cleaned up unused SSH key/port logic
  - Removed obsolete code in `OtherRsyncCommandtoDisplay`, `DefaultView`, and `RsyncParametersViewtwotables`
  - Removed unused `ArgumentsView.swift`

- **Always Show Abort Button**: Made abort button permanently visible in PushPullView toolbar for better user control

### Documentation & Analysis

- **Updated Quality Analysis**: 
  - Revised analysis for v2.8.6 with updated metrics
  - Updated file count, lines of code, and test coverage statistics
  - Adjusted overall score and readiness assessment to reflect current codebase status

- **Documentation Restructuring**:
  - Removed CHANGELOG.md, CODE_QUALITY_ANALYSIS_COMPREHENSIVE.md, and TODO.md
  - Added QUALITY_ANALYSIS_DETAILED.md with in-depth project analysis
  - Updated RsyncParameters and VerifyTasks SwiftUI views documentation

### Technical Details

**Version Number**: 2.8.6 (Build 177)

**Date**: January 3-8, 2026

**Commits**: 30 commits with significant architectural improvements and code quality enhancements

### Summary

Version 2.8.6 focuses on code quality, architectural simplification, and user experience improvements. The removal of the Verify Remote feature streamlines the application, while the consolidation of command views reduces code duplication. Enhanced UI components with Inspector panels and improved navigation provide users with better task inspection capabilities. The refactoring to use more idiomatic Swift patterns throughout the codebase improves maintainability and safety.

---

## Previous Version

For information about version 2.8.5 and earlier releases, please visit the [GitHub Releases](https://github.com/rsyncOSX/RsyncUI/releases) page.
